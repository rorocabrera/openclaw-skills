# CRM Tasks And Timeline

Task endpoints require tenant auth and staff roles.
Typical allowed roles: `SUPER_ADMIN`, `ADMIN`, `MANAGER`, `SALES`, `TECHNICIAN`.

## 1 — List Admin Tasks

```bash
curl -s "$TUNESUITE_API_URL/tasks/admin/tasks?page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 2 — Task Calendar

```bash
curl -s "$TUNESUITE_API_URL/tasks/admin/calendar?from=2026-02-01&to=2026-02-28" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

Calendar hints:

```bash
curl -s "$TUNESUITE_API_URL/tasks/admin/calendar/hints?from=2026-02-01&to=2026-02-28" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 3 — Unread Tasks

```bash
curl -s "$TUNESUITE_API_URL/tasks/admin/tasks/unread" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 4 — Task Details And Events

```bash
curl -s "$TUNESUITE_API_URL/tasks/admin/tasks/TASK_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

curl -s "$TUNESUITE_API_URL/tasks/admin/tasks/TASK_ID/events" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 5 — Create Or Update Task

```bash
# Create
curl -s -X POST "$TUNESUITE_API_URL/tasks/admin/tasks" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"title":"Call lead","type":"lead_follow_up","status":"open"}' | jq

# Update
curl -s -X POST "$TUNESUITE_API_URL/tasks/admin/tasks/TASK_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"status":"done"}' | jq
```

Allowed task statuses:
- `open`
- `in_progress`
- `done`
- `cancelled`

## 6 — Mark Read

```bash
curl -s -X POST "$TUNESUITE_API_URL/tasks/admin/tasks/TASK_ID/read" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"isRead":true}' | jq
```

## 7 — Timeline

```bash
curl -s "$TUNESUITE_API_URL/timeline/admin?page=1&limit=30" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 8 — Automation Rules

```bash
curl -s "$TUNESUITE_API_URL/automation/admin/rules" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

curl -s -X POST "$TUNESUITE_API_URL/automation/admin/rules/RULE_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"enabled":true}' | jq
```

## 9 — Task Series

```bash
curl -s "$TUNESUITE_API_URL/task-series/admin" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

curl -s -X POST "$TUNESUITE_API_URL/task-series/admin/SERIES_ID/deactivate" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```
