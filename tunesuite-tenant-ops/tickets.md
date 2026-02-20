# TuneSuite Tickets

Use this module for tenant ticket operations (read, write, close, message, assign, escalate).

## Auth Preflight

```bash
curl -s "$TUNESUITE_API_URL/auth/me" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq '{id, email, roles}'
```

## 1 — Get Last Ticket

Most recently updated ticket:

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets?limit=1&page=1" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 2 — Get Unread Tickets (By Me)

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

## 3 — Get Ticket By Order ID (Two-Step)

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

## 4 — Download Ticket Attachment

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets/attachments/ATTACHMENT_ID/download" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -o ticket-attachment.bin
```

## 5 — Optional Ticket Filters

```bash
# Full-text search across title/description/conversation/entities
curl -s "$TUNESUITE_API_URL/admin/tickets?search=SEARCH_TERM&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Order-related tickets only
curl -s "$TUNESUITE_API_URL/admin/tickets?orderRelatedOnly=true&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# By status/priority
curl -s "$TUNESUITE_API_URL/admin/tickets?status=open&priority=high&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

### Search Coverage

`search` matches ticket data and linked conversation/entity fields, including:
- Ticket core: `id`, `title`, `description`
- Conversation: message `content`, `sender_identifier`, `external_message_id`
- Linked users: client/admin `email`, client profile (`name`, `firstName`, `lastName`, `phone`)
- Linked entities: `relatedEntityId`, `relatedEntityType`, lead `id/name/email/phone`, external contact `identifier/normalized_identifier`
- Metadata: lead snapshot (`name/email/phone`), order/credit/payment-related metadata IDs

### Local Smoke Test (Admin Search)

```bash
python3 - <<'PY'
import json, subprocess, urllib.parse

API_URL='http://localhost:3000/api'
TENANT_ID='a1c6c439-dda5-48af-854a-41ae1bde124e'
EMAIL='admin@reprorace.tunersuite.com'
PASSWORD='Admin123$'

def run(cmd):
    return subprocess.check_output(cmd, shell=True, text=True)

auth = run(f"curl -sS -X POST '{API_URL}/auth/login' -H 'Content-Type: application/json' -H 'x-client-type: instance' -H 'x-panel-type: admin' -H 'x-tenant-id: {TENANT_ID}' -d '{{\"email\":\"{EMAIL}\",\"password\":\"{PASSWORD}\"}}'")
token = json.loads(auth)['tokens']['accessToken']

cases = [
  ('title', 'minicooper'),
  ('description', 'electrovalvula'),
  ('conversation_content', 'hola'),
  ('lead_name', 'Rodrigo Cabrera'),
  ('lead_email', 'rorocabrera@gmail.com'),
  ('related_entity_id', '24c841a7-fda0-4569-b9b4-40b49e64a0e9'),
  ('external_identifier', '34607302691'),
]

print('CASE\\tTERM\\tTOTAL\\tFIRST_MATCH')
for label, term in cases:
    q = urllib.parse.quote(term, safe='')
    raw = run(f"curl -sS '{API_URL}/admin/tickets?page=1&limit=10&search={q}' -H 'Authorization: Bearer {token}' -H 'x-tenant-id: {TENANT_ID}'")
    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        data = json.loads(''.join(ch for ch in raw if ord(ch) >= 32 or ch in '\\n\\r\\t'))
    total = ((data.get('meta') or {}).get('totalItems'))
    items = data.get('items') or []
    first = '<none>' if not items else f"{items[0].get('id')} | {items[0].get('title','')}"
    print(f"{label}\\t{term}\\t{total}\\t{first}")
PY
```

## 6 — Get Ticket Messages

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages?page=1&limit=50" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 7 — Update Ticket Status

`PUT /admin/tickets/:id/status`

Allowed statuses: `open`, `in_progress`, `resolved`, `closed`, `canceled`, `approved`, `pending_client_response`, `pending_admin_response`, `pending_hub_response`.

```bash
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/status" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"status":"closed"}' | jq
```

## 8 — Send Message on Ticket

`POST /admin/tickets/:id/messages`

Body fields:
- `content` (string, 1-5000 chars, required)
- `isInternalNote` (boolean, optional — true = not visible to client)
- `isDirectMessage` (boolean, optional — true = direct Hub communication)

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

## 9 — Send Message With Attachments

`POST /admin/tickets/:id/messages-with-attachments`

Multipart form: `content` field + up to N file uploads.

```bash
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages-with-attachments" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -F 'content=Message with files' \
  -F 'files=@/path/to/file.pdf' | jq
```

## 10 — Assign Ticket to Admin

`PUT /admin/tickets/:id/assign`

```bash
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/assign" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"adminId":"ADMIN_USER_UUID"}' | jq
```

## 11 — Escalate Ticket to Hub

`PUT /admin/tickets/:id/escalate`

```bash
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/escalate" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"escalate":true,"escalationReason":"Needs Hub review"}' | jq
```

## 12 — Create Ticket (Admin)

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

## 13 — Delete Message

`DELETE /admin/tickets/:ticketId/messages/:messageId`

```bash
curl -s -X DELETE "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages/MESSAGE_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 14 — Set Message Private Status

`PUT /admin/tickets/:ticketId/messages/:messageId/private`

Toggle whether a message is visible to the client.

```bash
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/messages/MESSAGE_ID/private" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"isPrivate":true}' | jq
```

## Current API Limits

- "Unread by anyone" is not available as a single endpoint. Unread is user-relative.
- No direct `GET /.../tickets/by-order/:orderId`; use the order `ticketId` bridge flow above.
