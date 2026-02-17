# CRM Leads

## Auth Preflight

CRM actions are currently enforced by route guards/roles. Preflight with:

```bash
echo "$TUNESUITE_ME" | jq '{email, roles}'
```

## 1 — Public Lead Submission

`POST /leads` (public; still tenant-scoped by `x-tenant-id`)

```bash
curl -s -X POST "$TUNESUITE_API_URL/leads" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -F 'lead={"name":"John","email":"john@example.com","message":"Need info"}'
```

Notes:
- Endpoint throttled to ~5 submissions / 10 minutes per IP.
- Supports up to 3 attachments (10MB each).
- Allowed file types: `pdf`, `doc`, `docx`, `txt`, `jpg`, `jpeg`, `png`, `webp`.

## 2 — Admin Create Lead

```bash
curl -s -X POST "$TUNESUITE_API_URL/leads/admin" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane","email":"jane@example.com","source":"manual"}' | jq
```

## 3 — List Leads

```bash
curl -s "$TUNESUITE_API_URL/leads/admin?page=1&limit=20&status=new" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 4 — Get Lead

```bash
curl -s "$TUNESUITE_API_URL/leads/admin/LEAD_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 5 — Update Lead Status

```bash
curl -s -X PUT "$TUNESUITE_API_URL/leads/admin/LEAD_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"status":"contacted","notes":"Called customer"}' | jq
```

Allowed statuses:
- `new`
- `contacted`
- `qualified`
- `converted`
- `lost`

## 6 — Download Lead Upload

```bash
curl -s "$TUNESUITE_API_URL/leads/admin/LEAD_ID/uploads/0/download" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -o lead-upload.bin
```

## 7 — Ensure Lead Ticket

```bash
curl -s -X POST "$TUNESUITE_API_URL/leads/admin/LEAD_ID/ticket" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```
