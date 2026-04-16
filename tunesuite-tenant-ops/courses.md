# TuneSuite Courses, Classrooms, Products, and Registration Links

> IMPORTANT: Use API endpoints only. Do not use direct DB or server file access.

> API Endpoint: `https://api.tunersuite.com/api`

> Authentication Required: See [./SKILL.md](./SKILL.md).

---

## When to Use

- "Create a course"
- "Create a free course registration link"
- "Create a paid course product"
- "Create a virtual classroom / aula virtual"
- "Schedule live lessons according to these dates"
- "Add modules, lessons, videos, readings, resources, quizzes, or assignments"
- "Guide me through the UI to publish a course"
- "Enroll a student manually"
- "Assign instructors or moderators"
- "Moderate live classroom chat"
- "Update enrollment status, progress, or certificates"
- "Check whether the course, product, direct link, and live room are ready"

---

## Core Model

- `Course` is the learning container.
- `CourseModule` groups lessons.
- `CourseLesson` is a video, reading, resource, quiz, assignment, or live lesson.
- `CourseLiveSession` is the virtual classroom attached to one `live` lesson.
- `Product` sells or exposes access to the course. Course products use metadata `productType: "course"` and `courseId`.
- `CourseEnrollment` grants access. Paid checkout creates enrollments when the order completes. Free direct registration creates enrollments through the direct link flow.
- Public free registration links are product metadata, not standalone direct links.

Do not create a separate event for online course access unless the user explicitly asks for a public event mirror. The source of truth is course enrollment.

---

## Required Inputs

Collect only what is missing:

- Tenant code or `TUNESUITE_TENANT_ID`
- Admin email/password or existing `TUNESUITE_TOKEN`
- Course title, description, instructor, language, difficulty
- Whether it is draft or published
- Whether access is free or paid
- Whether to reuse an existing course/product or create new ones
- Instructor, assistant, or moderator user IDs when the user wants a teaching team
- Product name, slug, SKU, and price
- If free: direct registration slug and public copy
- Course structure: modules and lesson list
- For each live class: start date/time, end date/time, timezone, provider, room source or embed/watch URL
- For videos: provider (`youtube` or `vimeo`) and video ID or URL
- For resources: file to upload or an existing resource URL

Dates matter. If the user gives relative dates like "today", "tomorrow", or "next Friday", convert them to exact calendar dates before calling the API. If timezone is missing, use the tenant/business timezone if known; otherwise ask once. Store live class timestamps as ISO strings and always send the intended `timezone`.

---

## Guardrails

- Mutations require a short impact summary before execution.
- Confirm before creating paid products, publishing a course, changing enrollment access, or disabling an active registration link.
- Search existing courses and course products before creating anything with a user-provided title, SKU, or slug.
- Never trust a tenant ID in the request body. Use `x-tenant-id`.
- Include these headers on authenticated calls:
  - `Authorization: Bearer $TUNESUITE_TOKEN`
  - `x-tenant-id: $TUNESUITE_TENANT_ID`
  - `x-client-type: instance`
  - `x-panel-type: admin`
  - `Content-Type: application/json`
- Course/module/lesson/live-session mutations require admin, manager, or super admin.
- Free course direct registration requires:
  - product price `0`
  - active product
  - linked published course
  - product type `course`
  - direct registration enabled

---

## UI Guidance

Use these steps when the user asks how to do it in the UI:

1. Open the tenant instance admin app.
   - Local instance: `http://localhost:5174/admin/dashboard/courses`
   - Production tenant: use the tenant domain and `/admin/dashboard/courses`
2. Go to Courses.
3. Create a new course or open an existing course.
4. In Overview, fill title, description, thumbnail, instructor, language, duration, difficulty, and certificate option.
5. In Curriculum, create modules first, then lessons.
6. For a virtual classroom, add a lesson with type `live`, then fill schedule, timezone, provider, video/room source, join window, chat mode, watch URL, embed URL, and replay URL when available.
7. In Sales, create or link a course product.
8. For a free course, set product price to `0`, keep product active, choose listed or unlisted visibility, and enable Direct registration.
9. Copy the public registration URL from the product direct-registration section. The route shape is `/direct/:slug`.
10. Publish the course only after curriculum, live sessions, and product access are ready.

Client-facing routes:

- Course catalog: `/courses/index`
- Course detail: `/courses/:slug`
- Direct registration: `/direct/:slug`
- My courses: `/account/courses`
- Course player: `/account/courses/:courseId`
- Live room: `/account/courses/:courseId/classrooms/:liveSessionId`

---

## API Workflow

Set a helper once after auth:

```bash
api() {
  local method="$1"
  local path="$2"
  local data="${3-}"
  if [ -n "$data" ]; then
    curl -s -X "$method" "$TUNESUITE_API_URL$path" \
      -H "Authorization: Bearer $TUNESUITE_TOKEN" \
      -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
      -H "x-client-type: instance" \
      -H "x-panel-type: admin" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -s -X "$method" "$TUNESUITE_API_URL$path" \
      -H "Authorization: Bearer $TUNESUITE_TOKEN" \
      -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
      -H "x-client-type: instance" \
      -H "x-panel-type: admin"
  fi
}
```

### 0 - Preflight, Discovery, and Reuse

Verify the token, tenant scope, and role before any mutation:

```bash
api GET /auth/me | jq '{ id, email, roles, tenantId, type }'
```

Find existing courses first. Reuse or update a match when the user asks for an existing course, when a title already exists, or when a product already links to the course.

```bash
api GET /courses | jq '.[] | { id, title, status, courseInstructor, courseLanguage }'
```

Search admin products for a matching course product, SKU, slug, or course ID:

```bash
COURSE_SEARCH=$(printf '%s' "Curso de ejemplo" | jq -sRr @uri)

api GET "/products/admin?productTypes=course&includeInactive=true&includeUnlisted=true&limit=100&search=$COURSE_SEARCH" \
  | jq '.[] | { id, name, sku, slug, price, isActive, metadata }'
```

Generate a SKU suggestion before creating a new product:

```bash
PRODUCT_NAME_ENCODED=$(printf '%s' "Curso de ejemplo" | jq -sRr @uri)

api GET "/products/admin/sku-suggestion?name=$PRODUCT_NAME_ENCODED" | jq
```

Check direct-registration slug availability by resolving it publicly. A successful response means the slug is already active for this tenant; a `404` means it is available or disabled.

```bash
curl -s "$TUNESUITE_API_URL/direct-links/public/masterclass-gratuita" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-client-type: instance" | jq
```

Discovery decision:

- If a matching course exists and the user asked to add lessons, update that course instead of creating a duplicate.
- If a matching product exists and has the right `metadata.courseId`, update its metadata or price instead of creating a duplicate.
- If a direct-registration slug resolves to the wrong product or course, ask for a different slug before mutation.
- If role or tenant preflight fails, stop and fix auth first.

### 1 - Create the Course

Course status values: `DRAFT`, `PUBLISHED`, `ARCHIVED`.

Start as `DRAFT` unless the user explicitly asks to publish immediately and all access pieces are ready.

```bash
COURSE_JSON=$(api POST /courses "$(jq -nc '{
  title: "Curso de ejemplo",
  description: "Descripcion publica del curso",
  status: "DRAFT",
  courseDurationMinutes: 120,
  courseDifficulty: "beginner",
  courseLanguage: "es",
  courseInstructor: "Instructor",
  enableCertificate: false
}')")

COURSE_ID=$(echo "$COURSE_JSON" | jq -r '.id')
echo "$COURSE_JSON" | jq
```

Update later:

```bash
api PATCH "/courses/$COURSE_ID" "$(jq -nc '{
  status: "PUBLISHED"
}')" | jq
```

Use PATCH for edits such as title, description, language, difficulty, certificate toggle, or status:

```bash
api PATCH "/courses/$COURSE_ID" "$(jq -nc '{
  title: "Curso actualizado",
  description: "Descripcion actualizada",
  courseDurationMinutes: 180,
  courseDifficulty: "intermediate",
  enableCertificate: true
}')" | jq
```

Delete only when the user explicitly asks and you have confirmed the course is not needed by any active product or enrollment:

```bash
api DELETE "/courses/$COURSE_ID" | jq
```

### 2 - Create Modules

```bash
MODULE_JSON=$(api POST /courses/modules "$(jq -nc --arg courseId "$COURSE_ID" '{
  courseId: $courseId,
  title: "Modulo 1",
  description: "Fundamentos",
  displayOrder: 0,
  enforceSequentialAccess: false,
  isLocked: false,
  isActive: true
}')")

MODULE_ID=$(echo "$MODULE_JSON" | jq -r '.id')
echo "$MODULE_JSON" | jq
```

List modules:

```bash
api GET "/courses/modules/course/$COURSE_ID" | jq
```

Update a module:

```bash
api PUT "/courses/modules/$MODULE_ID" "$(jq -nc '{
  title: "Modulo 1 actualizado",
  description: "Fundamentos y preparacion",
  enforceSequentialAccess: true,
  isActive: true
}')" | jq
```

Reorder modules with the complete ordered module ID list:

```bash
api POST "/courses/modules/course/$COURSE_ID/reorder" "$(jq -nc '{
  moduleIds: [
    "FIRST_MODULE_ID",
    "SECOND_MODULE_ID"
  ]
}')" | jq
```

Delete a module only after confirming whether its lessons should be removed too:

```bash
api DELETE "/courses/modules/$MODULE_ID" | jq
```

### 3 - Create Lessons

Lesson type values: `video`, `quiz`, `assignment`, `reading`, `resource`, `live`.

Video lesson:

```bash
LESSON_JSON=$(api POST /courses/lessons "$(jq -nc --arg moduleId "$MODULE_ID" '{
  moduleId: $moduleId,
  title: "Leccion 1 - Bienvenida",
  description: "Primera leccion",
  lessonType: "video",
  displayOrder: 0,
  videoProvider: "youtube",
  videoId: "YOUTUBE_VIDEO_ID",
  durationMinutes: 12,
  isActive: true,
  isPreview: false,
  isRequired: true,
  completionThreshold: 0.8,
  allowReviewAfterCompletion: true
}')")

LESSON_ID=$(echo "$LESSON_JSON" | jq -r '.id')
echo "$LESSON_JSON" | jq
```

Reading lesson:

```bash
api POST /courses/lessons "$(jq -nc --arg moduleId "$MODULE_ID" '{
  moduleId: $moduleId,
  title: "Guia de lectura",
  lessonType: "reading",
  displayOrder: 1,
  content: "Contenido de la leccion en texto o HTML seguro.",
  isActive: true,
  isRequired: true
}')" | jq
```

Resource lesson with an existing URL:

```bash
api POST /courses/lessons "$(jq -nc --arg moduleId "$MODULE_ID" '{
  moduleId: $moduleId,
  title: "Material descargable",
  lessonType: "resource",
  displayOrder: 2,
  resourceUrl: "https://example.com/resource.pdf",
  isActive: true,
  isRequired: false
}')" | jq
```

Upload a resource file, then use the returned `storageKey` fields in the lesson:

```bash
curl -s -X POST "$TUNESUITE_API_URL/courses/lessons/resource-upload" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-client-type: instance" \
  -H "x-panel-type: admin" \
  -F "file=@/absolute/path/to/resource.pdf" | jq
```

List lessons:

```bash
api GET "/courses/lessons/module/$MODULE_ID" | jq
```

Update a lesson:

```bash
api PUT "/courses/lessons/$LESSON_ID" "$(jq -nc '{
  title: "Leccion 1 - Bienvenida actualizada",
  description: "Primera leccion revisada",
  durationMinutes: 15,
  isPreview: true,
  isRequired: true
}')" | jq
```

Reorder lessons with the complete ordered lesson ID list for the module:

```bash
api POST "/courses/lessons/module/$MODULE_ID/reorder" "$(jq -nc '{
  lessonIds: [
    "FIRST_LESSON_ID",
    "SECOND_LESSON_ID"
  ]
}')" | jq
```

Delete a lesson only after confirming whether students may already have progress on it:

```bash
api DELETE "/courses/lessons/$LESSON_ID" | jq
```

### 4 - Create a Virtual Classroom

Create a `live` lesson first:

```bash
LIVE_LESSON_JSON=$(api POST /courses/lessons "$(jq -nc --arg moduleId "$MODULE_ID" '{
  moduleId: $moduleId,
  title: "Clase en vivo",
  description: "Aula virtual con chat del curso",
  lessonType: "live",
  displayOrder: 3,
  durationMinutes: 90,
  isActive: true,
  isRequired: true
}')")

LIVE_LESSON_ID=$(echo "$LIVE_LESSON_JSON" | jq -r '.id')
echo "$LIVE_LESSON_JSON" | jq
```

Then upsert the live session. Provider values: `youtube`, `vimeo`, `jitsi`, `external_iframe`, `custom`. Chat mode values: `enabled`, `read_only`, `disabled`.

```bash
LIVE_SESSION_JSON=$(api POST /courses/live-sessions/upsert "$(jq -nc \
  --arg courseId "$COURSE_ID" \
  --arg lessonId "$LIVE_LESSON_ID" '{
  courseId: $courseId,
  lessonId: $lessonId,
  startsAt: "2026-04-20T23:00:00.000Z",
  endsAt: "2026-04-21T00:30:00.000Z",
  timezone: "America/Caracas",
  provider: "youtube",
  providerVideoId: "YOUTUBE_VIDEO_ID",
  roomSource: "https://www.youtube.com/watch?v=YOUTUBE_VIDEO_ID",
  watchUrl: "https://www.youtube.com/watch?v=YOUTUBE_VIDEO_ID",
  embedUrl: "https://www.youtube.com/embed/YOUTUBE_VIDEO_ID",
  chatEnabled: true,
  chatMode: "enabled",
  joinWindowMinutes: 15,
  metadata: {
    source: "openclaw-course-skill"
  }
}')")

LIVE_SESSION_ID=$(echo "$LIVE_SESSION_JSON" | jq -r '.id')
echo "$LIVE_SESSION_JSON" | jq
```

List live sessions:

```bash
api GET "/courses/live-sessions?courseId=$COURSE_ID" | jq
```

Update a virtual classroom by calling the same upsert endpoint with the same `lessonId` and revised room fields:

```bash
api POST /courses/live-sessions/upsert "$(jq -nc \
  --arg courseId "$COURSE_ID" \
  --arg lessonId "$LIVE_LESSON_ID" '{
  courseId: $courseId,
  lessonId: $lessonId,
  startsAt: "2026-04-27T23:00:00.000Z",
  endsAt: "2026-04-28T00:30:00.000Z",
  timezone: "America/Caracas",
  provider: "jitsi",
  roomSource: "https://meet.jit.si/tenant-course-room",
  watchUrl: "https://meet.jit.si/tenant-course-room",
  chatEnabled: true,
  chatMode: "read_only",
  joinWindowMinutes: 20
}')" | jq
```

Live chat and moderation:

```bash
api GET "/courses/live-sessions/$LIVE_SESSION_ID/chat/messages?limit=50&includeModerated=true" | jq
```

Posting chat messages creates visible room content. Only post when the user explicitly asks or you are using an approved test session:

```bash
api POST "/courses/live-sessions/$LIVE_SESSION_ID/chat/messages" "$(jq -nc '{
  body: "Bienvenidos a la clase en vivo."
}')" | jq
```

Hide or restore a message as a moderator, lead instructor, manager, admin, or super admin:

```bash
api POST "/courses/live-sessions/$LIVE_SESSION_ID/chat/messages/$MESSAGE_ID/hide" "$(jq -nc '{
  reason: "Contenido inapropiado"
}')" | jq

api POST "/courses/live-sessions/$LIVE_SESSION_ID/chat/messages/$MESSAGE_ID/restore" | jq
```

### 5 - Create the Course Product

Use `courseProductCourseId` so the API enforces tenant-scoped course linking and writes `metadata.productType = "course"` and `metadata.courseId`.

Paid product:

```bash
PRODUCT_JSON=$(api POST /products/admin "$(jq -nc --arg courseId "$COURSE_ID" '{
  sku: "COURSE-001",
  name: "Curso completo",
  slug: "curso-completo",
  description: "Acceso al curso completo",
  price: 49.99,
  inventory: 0,
  inventoryPolicy: "untracked",
  isActive: true,
  courseProductCourseId: $courseId,
  metadata: {
    shortDescription: "Acceso al curso completo",
    storefrontVisibility: "listed",
    courseAudience: "online",
    expirationDays: null
  }
}')")

PRODUCT_ID=$(echo "$PRODUCT_JSON" | jq -r '.id')
echo "$PRODUCT_JSON" | jq
```

Free product with active registration link:

```bash
PRODUCT_JSON=$(api POST /products/admin "$(jq -nc --arg courseId "$COURSE_ID" '{
  sku: "COURSE-FREE-001",
  name: "Masterclass gratuita",
  slug: "masterclass-gratuita",
  description: "Registro gratuito al curso",
  price: 0,
  inventory: 0,
  inventoryPolicy: "untracked",
  isActive: true,
  courseProductCourseId: $courseId,
  metadata: {
    shortDescription: "Registro gratuito al curso",
    storefrontVisibility: "unlisted",
    courseAudience: "online",
    expirationDays: null,
    directRegistration: {
      enabled: true,
      slug: "masterclass-gratuita",
      actionType: "course_enrollment",
      identityMode: "account_required",
      redirectTarget: "course",
      collectFields: {
        name: true,
        phone: true,
        password: true
      },
      publicCopy: {
        headline: "Masterclass gratuita",
        description: "Completa el registro para entrar al aula virtual.",
        ctaLabel: "Registrarme gratis",
        successMessage: "Registro completado. Ya puedes entrar al curso."
      },
      actionConfig: {
        courseId: $courseId
      }
    }
  }
}')")

PRODUCT_ID=$(echo "$PRODUCT_JSON" | jq -r '.id')
DIRECT_REGISTRATION_SLUG=$(echo "$PRODUCT_JSON" | jq -r '.metadata.directRegistration.slug')
echo "$PRODUCT_JSON" | jq
```

The public user-facing URL is:

```bash
echo "${TUNESUITE_INSTANCE_URL:-https://TENANT_DOMAIN}/direct/$DIRECT_REGISTRATION_SLUG"
```

For local instance testing, use `http://localhost:5174/direct/$DIRECT_REGISTRATION_SLUG`.

### 6 - Activate or Update a Registration Link on an Existing Product

When updating product metadata, preserve existing metadata values that should remain. Do not send only `directRegistration` if it would erase other metadata.

```bash
CURRENT_PRODUCT=$(api GET "/products/admin/$PRODUCT_ID")

UPDATED_PRODUCT=$(echo "$CURRENT_PRODUCT" | jq -c --arg courseId "$COURSE_ID" --arg slug "masterclass-gratuita" '
  {
    metadata: ((.metadata // {}) + {
      productType: "course",
      courseId: $courseId,
      storefrontVisibility: "unlisted",
      courseAudience: "online",
      expirationDays: null,
      directRegistration: (((.metadata // {}).directRegistration // {}) + {
        enabled: true,
        slug: $slug,
        actionType: "course_enrollment",
        identityMode: "account_required",
        redirectTarget: "course",
        collectFields: {
          name: true,
          phone: true,
          password: true
        },
        publicCopy: {
          headline: "Masterclass gratuita",
          description: "Completa el registro para entrar al aula virtual.",
          ctaLabel: "Registrarme gratis",
          successMessage: "Registro completado. Ya puedes entrar al curso."
        },
        actionConfig: {
          courseId: $courseId
        }
      })
    }),
    courseProductCourseId: $courseId,
    price: 0,
    isActive: true
  }
')

api PUT "/products/admin/$PRODUCT_ID" "$UPDATED_PRODUCT" | jq
```

Disable an active registration link only after explicit confirmation:

```bash
CURRENT_PRODUCT=$(api GET "/products/admin/$PRODUCT_ID")

UPDATED_PRODUCT=$(echo "$CURRENT_PRODUCT" | jq -c '
  {
    metadata: ((.metadata // {}) + {
      directRegistration: (((.metadata // {}).directRegistration // {}) + {
        enabled: false
      })
    })
  }
')

api PUT "/products/admin/$PRODUCT_ID" "$UPDATED_PRODUCT" | jq
```

Optional end-to-end smoke test for a free direct registration. This requires an existing, verified, active test account with password login, and it creates or reuses a real course enrollment. Run it only with an approved test email:

```bash
curl -s -X POST "$TUNESUITE_API_URL/direct-links/public/$DIRECT_REGISTRATION_SLUG/submit" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-client-type: instance" \
  -H "Content-Type: application/json" \
  -d "$(jq -nc '{
    email: "student.test@example.com",
    name: "Student Test",
    phone: "+10000000000",
    password: "Use-A-Real-Test-Password-Here"
  }')" | jq
```

Expected smoke result:

- Direct link action completes.
- Enrollment is created for the linked course.
- Existing account is accepted with the supplied password.
- The student can open `/account/courses` and the course player after login.

If the product is public in the catalog, also check the course preview endpoint:

```bash
curl -s "$TUNESUITE_API_URL/products/by-slug/masterclass-gratuita/course-preview" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-client-type: instance" | jq
```

### 7 - Verify Public and Admin Access

Admin verification:

```bash
api GET "/courses/$COURSE_ID" | jq
api GET "/courses/modules/course/$COURSE_ID" | jq
api GET "/courses/live-sessions?courseId=$COURSE_ID" | jq
api GET "/products/admin/$PRODUCT_ID" | jq
```

Public product check by slug:

```bash
curl -s "$TUNESUITE_API_URL/products/by-slug/masterclass-gratuita" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-client-type: instance" | jq
```

Public direct link resolution:

```bash
curl -s "$TUNESUITE_API_URL/direct-links/public/$DIRECT_REGISTRATION_SLUG" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-client-type: instance" | jq
```

Expected direct link result:

- `kind: "product"`
- `actionType: "course_enrollment"`
- `requiresAccount: true`
- `courseId` equals the course ID
- `collectFields.password: true`

### 8 - Manual Enrollment

Use this for admin-granted access, comps, or tests. Do not use it to bypass a paid purchase unless the user explicitly confirms.

```bash
api POST /courses/enrollments "$(jq -nc --arg userId "USER_ID" --arg courseId "$COURSE_ID" '{
  userId: $userId,
  courseId: $courseId,
  notes: "Manual enrollment by OpenClaw"
}')" | jq
```

List course enrollments:

```bash
api GET "/courses/enrollments/course/$COURSE_ID" | jq
```

Check current user access by product:

```bash
api GET "/courses/enrollments/check-access/$PRODUCT_ID" | jq
```

### 9 - Instructor, Assistant, and Moderator Assignments

Use instructor assignments when the user wants named teaching staff, live-room moderators, or a lead instructor beyond the course display text. Role values: `lead_instructor`, `assistant`, `moderator`.

```bash
api GET "/courses/$COURSE_ID/instructors" | jq
```

Assign or update a course staff member:

```bash
api POST "/courses/$COURSE_ID/instructors" "$(jq -nc --arg userId "USER_ID" '{
  userId: $userId,
  role: "lead_instructor"
}')" | jq
```

Remove an assignment only after confirming the person should lose teaching or moderation access:

```bash
api DELETE "/courses/$COURSE_ID/instructors/$ASSIGNMENT_ID" | jq
```

### 10 - Enrollment Lifecycle

Enrollment status values: `active`, `completed`, `expired`, `suspended`.

Get one enrollment:

```bash
api GET "/courses/enrollments/$ENROLLMENT_ID" | jq
```

Change status after confirmation:

```bash
api PUT "/courses/enrollments/$ENROLLMENT_ID/status" "$(jq -nc '{
  status: "active",
  notes: "Status updated by OpenClaw"
}')" | jq
```

Suspend access:

```bash
SUSPEND_REASON=$(printf '%s' "Payment dispute or admin request" | jq -sRr @uri)

api POST "/courses/enrollments/$ENROLLMENT_ID/suspend?reason=$SUSPEND_REASON" | jq
```

Extend access by days or set an exact expiration timestamp:

```bash
api POST "/courses/enrollments/$ENROLLMENT_ID/extend" "$(jq -nc '{
  additionalDays: 30,
  notes: "Access extended by OpenClaw"
}')" | jq

api POST "/courses/enrollments/$ENROLLMENT_ID/extend" "$(jq -nc '{
  expiresAt: "2026-05-31T23:59:59.000Z",
  notes: "Exact expiration set by OpenClaw"
}')" | jq
```

Recalculate progress and issue a certificate:

```bash
api POST "/courses/enrollments/$ENROLLMENT_ID/calculate-progress" | jq

api POST "/courses/enrollments/$ENROLLMENT_ID/certificate" "$(jq -nc '{
  forceIssue: false
}')" | jq
```

Use `forceIssue: true` only for an explicitly approved admin exception.

### 11 - Progress and Student Support

Use progress endpoints to diagnose access issues, resume lessons, and support students. Do not mark lessons complete or reset progress unless the user explicitly confirms.

```bash
api GET "/courses/progress/enrollment/$ENROLLMENT_ID" | jq
api GET "/courses/progress/enrollment/$ENROLLMENT_ID/summary" | jq
api GET "/courses/progress/enrollment/$ENROLLMENT_ID/resume" | jq
api GET "/courses/progress/check-access/$ENROLLMENT_ID/$LESSON_ID" | jq
api GET "/courses/progress/check-quiz-attempts/$ENROLLMENT_ID/$LESSON_ID" | jq
```

Mark one lesson complete:

```bash
api POST "/courses/progress/lesson/$LESSON_ID/enrollment/$ENROLLMENT_ID/complete" "$(jq -nc '{
  notes: "Completed by admin request",
  forceComplete: false
}')" | jq
```

Batch-complete lessons for an enrollment:

```bash
api POST "/courses/progress/enrollment/$ENROLLMENT_ID/batch-complete" "$(jq -nc '{
  lessonIds: [
    "FIRST_LESSON_ID",
    "SECOND_LESSON_ID"
  ],
  notes: "Bulk completion by admin request"
}')" | jq
```

Reset progress only when the user confirms the reset scope:

```bash
api POST "/courses/progress/lesson/$LESSON_ID/enrollment/$ENROLLMENT_ID/reset" "$(jq -nc '{
  reason: "Reset requested by student",
  fullReset: false
}')" | jq
```

---

## Product Access Rules

### Paid Courses

- Create an active course product with price greater than `0`.
- Checkout/order completion creates the course enrollment.
- Guest checkout for course products is not the target flow. Customers should have or create an account.
- Do not enable direct registration for paid products; direct registration is intended for free non-shipping products.

### Free Courses

- Create an active course product with price `0`.
- Link it to a published course.
- Enable `metadata.directRegistration.enabled`.
- Public route `/direct/:slug` handles account registration/verification, then submits the direct link and creates the enrollment.

### Unlisted Courses

Use `storefrontVisibility: "unlisted"` when the course should not appear in the catalog but should still be accessible through its direct link.

---

## Launch Checklist

Before telling the user the course is ready:

- Discovery was done and no duplicate course, SKU, product slug, or direct-registration slug was accidentally created.
- Course exists in the correct tenant.
- Course status is `PUBLISHED` if public access should work now.
- At least one active module exists.
- At least one active lesson exists.
- Every live lesson has a live session with correct `startsAt`, `endsAt`, and `timezone`.
- Teaching staff and moderators are assigned when requested.
- Live chat mode matches the class plan, and moderation endpoints work for the assigned role when moderation is part of the job.
- Product exists, is active, and has `metadata.productType: "course"` plus the right `courseId`.
- Free direct registration has `enabled: true`, `actionType: "course_enrollment"`, `identityMode: "account_required"`, and a slug.
- `GET /direct-links/public/:slug` resolves successfully for free registration.
- Optional free-registration smoke test was run with an approved test account when the user asked for proof.
- Manual enrollments, status changes, progress overrides, and certificate issuance were confirmed before execution.
- The user-facing URL is shown as `/direct/:slug`, not the backend `/direct-links/public/:slug`.

---

## Common Failures

- `400 Course not found for this tenant`: the course ID does not belong to `x-tenant-id`.
- `400 Product is not a course`: product metadata is missing `productType: "course"` or `courseId`.
- `400 SKU or slug already exists`: discovery found or missed an existing product. Reuse the product or choose a unique SKU/slug.
- `400 Direct registration slug already exists`: choose a unique `metadata.directRegistration.slug` or update the existing product.
- `400 Password is required`: `identityMode: "account_required"` usually requires collecting a password for new direct-registration users.
- `404 Direct link not found`: product is inactive, course is not published, price is not zero, direct registration is disabled, or slug is wrong.
- `403 Insufficient permissions`: login user is not admin, manager, or super admin for course mutations.
- `403 Only moderators, lead instructors, or admins can manage chat messages`: assign the user as moderator/lead instructor or use an admin token.
- Progress cannot be forced complete: `forceComplete: true` requires admin, manager, or super admin.
- Live room does not open: user is not enrolled, join window has not started, session ended, or live session is missing for the live lesson.
