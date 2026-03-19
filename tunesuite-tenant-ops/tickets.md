# TuneSuite Tickets

Use this module for tenant ticket operations (read, write, close, message, assign, escalate).
Supports multi-channel conversations: internal, email, SMS, WhatsApp, Messenger, Instagram (DMs and comment replies), phone call, and live chat.

## Auth Preflight

```bash
curl -s "$TUNESUITE_API_URL/auth/me" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq '{id, email, roles}'
```

---

## Channels Reference

| Channel value     | Description                                  |
|-------------------|----------------------------------------------|
| `internal`        | Platform-only tickets (client ↔ admin)       |
| `email`           | Email conversations                          |
| `sms`             | SMS messages                                 |
| `whatsapp`        | WhatsApp Business API                        |
| `messenger`       | Facebook Messenger                           |
| `instagram`       | Instagram (DMs **and** comment replies)      |
| `phone_call`      | Phone call records                           |
| `live_chat`       | Live chat widget                             |

**Virtual tabs** (UI-only, not channel enum values):

| Tab     | Meaning                                              |
|---------|------------------------------------------------------|
| `all`   | All channels combined                                |
| `hub`   | Direct admin ↔ hub tickets (`isDirect=true`)         |
| `spam`  | Spam-flagged tickets (`isSpam=true`)                 |

### Instagram Sub-Filters

Instagram tickets have two sub-types distinguished by `contactSource` in `channelMetadata`:

| contactSource        | Meaning                              |
|----------------------|--------------------------------------|
| `instagram`          | Instagram Direct Messages (DMs)      |
| `instagram_comment`  | Replies to Instagram post comments   |

Filter via the `contactSource` query parameter (see §5).

---

## 1 — List Tickets (with channel + filters)

```bash
# All tickets (default)
curl -s "$TUNESUITE_API_URL/admin/tickets?page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Single channel
curl -s "$TUNESUITE_API_URL/admin/tickets?channels=email&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Multiple channels (repeat param)
curl -s "$TUNESUITE_API_URL/admin/tickets?channels=whatsapp&channels=messenger&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Instagram DMs only (exclude comment threads)
curl -s "$TUNESUITE_API_URL/admin/tickets?channels=instagram&contactSource=instagram&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Instagram comment threads only
curl -s "$TUNESUITE_API_URL/admin/tickets?channels=instagram&contactSource=instagram_comment&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Hub (direct admin↔hub) tickets
curl -s "$TUNESUITE_API_URL/admin/tickets/direct?page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Spam folder
curl -s "$TUNESUITE_API_URL/admin/tickets?isSpam=true&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

### Email Recipient Filtering

Email tickets can be filtered by the recipient mailbox address. First fetch available addresses:

```bash
# Get available mailbox addresses for the tenant
curl -s "$TUNESUITE_API_URL/admin/tickets/compose/mailbox-addresses" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

Then filter by a specific address:

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets?channels=email&recipientInboxAddress=support@example.com&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 2 — Get Last Ticket

Most recently updated ticket:

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets?limit=1&page=1" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 3 — Get Unread Tickets (By Me)

Unread is evaluated for the authenticated user.

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets?unreadOnly=true&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

Unread summary counters:

```bash
curl -s "$TUNESUITE_API_URL/notifications/tickets/admin/summary" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 4 — Get Ticket By Order ID (Two-Step)

Direct `ticket by order id` endpoint is not exposed. Use:

1. Read order and extract `ticketId`.
2. Read ticket by that ID.

```bash
ORDER_JSON=$(curl -s "$TUNESUITE_API_URL/tenant-orders/ORDER_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID")

TICKET_ID=$(echo "$ORDER_JSON" | jq -r '.ticketId // empty')

if [ -n "$TICKET_ID" ]; then
  curl -s "$TUNESUITE_API_URL/admin/tickets/$TICKET_ID" \
    -H "Authorization: Bearer $TUNESUITE_TOKEN" \
    -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
else
  echo '{"message":"No ticket linked to this order"}'
fi
```

## 5 — Full Filter Reference

All query parameters for `GET /admin/tickets`:

| Parameter              | Type        | Description                                                              |
|------------------------|-------------|--------------------------------------------------------------------------|
| `page`                 | int         | Page number (default 1)                                                  |
| `limit`                | int         | Items per page, 1-100 (default 10)                                       |
| `search`               | string      | Full-text search (see §5a for coverage)                                  |
| `channels`             | string[]    | Filter by channel(s): repeat param for multiple                          |
| `contactSource`        | string      | `instagram` or `instagram_comment` — Instagram sub-filter                |
| `recipientInboxAddress`| string      | Filter email tickets by recipient mailbox address                        |
| `status`               | enum        | `open`, `in_progress`, `resolved`, `closed`, `canceled`, `approved`, `pending_client_response`, `pending_admin_response`, `pending_hub_response` |
| `type`                 | enum[]      | Ticket type(s) — repeat param for multiple                               |
| `priority`             | enum        | `low`, `medium`, `high`, `urgent`                                        |
| `clientGroupId`        | uuid        | Filter by client group                                                   |
| `unreadOnly`           | boolean     | Only unread tickets (user-relative)                                      |
| `readOnly`             | boolean     | Only read tickets                                                        |
| `includeArchived`      | boolean     | Include canceled/archived tickets                                        |
| `isSpam`               | boolean     | Spam folder                                                              |
| `orderRelatedOnly`     | boolean     | Only tickets linked to orders                                            |
| `isDirect`             | boolean     | Direct admin↔hub tickets (use `/admin/tickets/direct` endpoint instead)  |

### 5a — Search Coverage

`search` matches ticket data and linked conversation/entity fields, including:
- Ticket core: `id`, `title`, `description`
- Conversation: message `content`, `sender_identifier`, `external_message_id`
- Linked users: client/admin `email`, client profile (`name`, `firstName`, `lastName`, `phone`)
- Linked entities: `relatedEntityId`, `relatedEntityType`, lead `id/name/email/phone`, external contact `identifier/normalized_identifier`
- Metadata: lead snapshot (`name/email/phone`), order/credit/payment-related metadata IDs

**Finding a user by email across any channel:**

```bash
# Search by email — works across ALL channels (email, WhatsApp, Instagram, etc.)
curl -s "$TUNESUITE_API_URL/admin/tickets?search=user@example.com&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Combine with channel filter to narrow down
curl -s "$TUNESUITE_API_URL/admin/tickets?search=user@example.com&channels=instagram&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

**Finding a user by phone number (WhatsApp/SMS):**

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets?search=34607302691&channels=whatsapp&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

**Finding a user by name:**

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets?search=John+Doe&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 6 — Get Ticket Detail

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets/TICKET_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

**Important fields in response for Instagram tickets:**

```jsonc
{
  "channel": "instagram",
  "channelMetadata": {
    "contactSource": "instagram_comment", // or absent/null for DMs
    "originalCommentText": "Nice work!",  // the comment text (comment tickets only)
    "mediaCaption": "Check out our...",   // source post caption
    "commentAuthor": "username",
    "permalink": "https://instagram.com/...",
    "instagramPrivateReplySentAt": "2025-..." // set after private reply sent
  }
}
```

## 7 — Get Ticket Messages

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages?page=1&limit=50" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 8 — Download Ticket Attachment

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets/attachments/ATTACHMENT_ID/download" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -o ticket-attachment.bin
```

## 9 — Update Ticket Status

`PUT /admin/tickets/:id/status`

Allowed statuses: `open`, `in_progress`, `resolved`, `closed`, `canceled`, `approved`, `pending_client_response`, `pending_admin_response`, `pending_hub_response`.

```bash
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/status" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"status":"closed"}' | jq
```

## 10 — Send Message on Ticket

`POST /admin/tickets/:id/messages`

Body fields:
- `content` (string, 1-5000 chars, required)
- `isInternalNote` (boolean, optional — true = not visible to client)
- `isDirectMessage` (boolean, optional — true = direct Hub communication)
- `instagramCommentReplyMode` (string, optional — `"public"` or `"private"`, see §10a)

```bash
# Visible message (client sees it)
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"content":"Your message here"}' | jq

# Internal note (only admins see it)
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"content":"Internal note here","isInternalNote":true}' | jq
```

### 10a — Instagram Reply Modes

Instagram comment tickets support two reply modes via `instagramCommentReplyMode`:

| Mode       | Behavior                                                                                           |
|------------|-----------------------------------------------------------------------------------------------------|
| `"public"` | Posts reply as a **public comment** on the original Instagram post. Visible to everyone.            |
| `"private"`| Sends a **private DM** from the comment. After the person responds, conversation continues in DMs. |

**Constraints:**
- Only ONE private reply can be sent per comment thread. Once `channelMetadata.instagramPrivateReplySentAt` is set, `"private"` is no longer available.
- Public replies can be sent multiple times.
- This field is ONLY used for tickets where `channelMetadata.contactSource === "instagram_comment"`.
- For Instagram DM tickets (no `contactSource` or `contactSource === "instagram"`), just send a normal message — it goes as a DM automatically.

```bash
# Public reply to Instagram comment (visible on the post)
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"content":"Thanks for your comment!","instagramCommentReplyMode":"public"}' | jq

# Private reply to Instagram comment (sends a DM)
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"content":"Hi! Lets continue this privately.","instagramCommentReplyMode":"private"}' | jq

# Reply to Instagram DM (just a normal message, goes as DM)
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"content":"Thanks for reaching out via DM!"}' | jq
```

### Decision Tree: How to Reply

```
Is the ticket channel "instagram"?
├── YES → Check channelMetadata.contactSource
│   ├── "instagram_comment" → COMMENT THREAD
│   │   ├── Want public reply? → instagramCommentReplyMode: "public"
│   │   └── Want private DM?  → instagramCommentReplyMode: "private"
│   │       └── Already sent? (instagramPrivateReplySentAt exists) → NOT ALLOWED, use "public"
│   └── "instagram" / absent → DM THREAD
│       └── Send normal message (no instagramCommentReplyMode needed)
├── NO → Any other channel
│   └── Send normal message
└── Want internal note? → Add isInternalNote: true (works on all channels)
```

## 11 — Send Message With Attachments

`POST /admin/tickets/:id/messages-with-attachments`

Multipart form: `content` field + up to N file uploads (max 5 files, 5MB each).

```bash
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages-with-attachments" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -F 'content=Message with files' \
  -F 'files=@/path/to/file.pdf' | jq
```

## 12 — Assign Ticket to Admin

`PUT /admin/tickets/:id/assign`

```bash
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/assign" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"adminId":"ADMIN_USER_UUID"}' | jq
```

## 13 — Escalate Ticket to Hub

`PUT /admin/tickets/:id/escalate`

```bash
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/escalate" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"escalate":true,"escalationReason":"Needs Hub review"}' | jq
```

## 14 — Create Ticket (Admin)

`POST /admin/tickets`

```bash
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "title":"Ticket title (5-100 chars)",
    "description":"Ticket description (10-1000 chars)",
    "priority":"medium",
    "type":"general",
    "clientId":"CLIENT_USER_UUID"
  }' | jq
```

Allowed types: `technical_support`, `billing_issue`, `service_inquiry`, `general`, `subscription_query`, `configuration_request`, `credit_purchase_report`, `order_payment_report`, `order_issue`.

Allowed priorities: `low`, `medium`, `high`, `urgent`.

## 15 — Compose Ticket (Email / External)

`POST /admin/tickets/compose`

Used to compose a new ticket to an email address or external contact (not an existing client).

First get compose options:

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets/compose/options" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 16 — Delete Message

`DELETE /admin/tickets/:ticketId/messages/:messageId`

```bash
curl -s -X DELETE "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages/MESSAGE_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 17 — Set Message Private Status

`PUT /admin/tickets/:ticketId/messages/:messageId/private`

Toggle whether a message is visible to the client.

```bash
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages/MESSAGE_ID/private" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"isPrivate":true}' | jq
```

## 18 — Bulk Operations

```bash
# Bulk mark as unread
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/unread/bulk" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"ticketIds":["UUID1","UUID2"]}' | jq

# Bulk spam toggle
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/spam/bulk" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"ticketIds":["UUID1","UUID2"],"isSpam":true}' | jq

# Bulk delete conversations
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/conversation/bulk" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"ticketIds":["UUID1","UUID2"]}' | jq
```

## 19 — Mark Spam / Unspam

```bash
# Mark as spam
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/mark-spam" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Remove from spam
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/unspam" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 20 — Mark Unread

```bash
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/mark-unread" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 21 — Link / Unlink Entity

```bash
# Link to order/credit/subscription
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/link-entity" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"relatedEntityId":"ENTITY_UUID","relatedEntityType":"order"}' | jq

# Link to client
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/link-client" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"clientId":"CLIENT_UUID"}' | jq

# Unlink person
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/unlink-person" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 22 — Delete/Archive Conversation

```bash
curl -s -X DELETE "$TUNESUITE_API_URL/admin/tickets/TICKET_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

---

## Workflow: Find User → Read Thread → Reply

**Step 1: Search for user across all channels**

```bash
RESULTS=$(curl -s "$TUNESUITE_API_URL/admin/tickets?search=user@example.com&page=1&limit=10" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID")
echo "$RESULTS" | jq '.items[] | {id, title, channel, status, channelMetadata}'
```

**Step 2: Read the conversation**

```bash
TICKET_ID=$(echo "$RESULTS" | jq -r '.items[0].id')
curl -s "$TUNESUITE_API_URL/admin/tickets/$TICKET_ID/messages?page=1&limit=50" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq '.items[] | {sender: .senderType, content: .content, at: .createdAt}'
```

**Step 3: Reply (choose mode based on channel)**

```bash
# Check channel type first
TICKET_DETAIL=$(curl -s "$TUNESUITE_API_URL/admin/tickets/$TICKET_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID")
CHANNEL=$(echo "$TICKET_DETAIL" | jq -r '.channel')
CONTACT_SOURCE=$(echo "$TICKET_DETAIL" | jq -r '.channelMetadata.contactSource // empty')
PRIVATE_SENT=$(echo "$TICKET_DETAIL" | jq -r '.channelMetadata.instagramPrivateReplySentAt // empty')

# Then send with appropriate mode
if [ "$CHANNEL" = "instagram" ] && [ "$CONTACT_SOURCE" = "instagram_comment" ]; then
  # Instagram comment → choose public or private
  MODE="public"  # or "private" if $PRIVATE_SENT is empty
  curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/$TICKET_ID/messages" \
    -H "Authorization: Bearer $TUNESUITE_TOKEN" \
    -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"Your reply\",\"instagramCommentReplyMode\":\"$MODE\"}" | jq
else
  # All other channels (including Instagram DMs) → normal message
  curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/$TICKET_ID/messages" \
    -H "Authorization: Bearer $TUNESUITE_TOKEN" \
    -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
    -H "Content-Type: application/json" \
    -d '{"content":"Your reply"}' | jq
fi
```

---

## Current API Limits

- "Unread by anyone" is not available as a single endpoint. Unread is user-relative.
- No direct `GET /.../tickets/by-order/:orderId`; use the order `ticketId` bridge flow above.
- Instagram private reply: only ONE per comment thread.
- Message content: 1–5000 characters.
- Attachments: max 5 files, 5MB each per message.
