# TuneSuite Tickets

Use this module for tenant ticket operations.

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
# Order-related tickets only
curl -s "$TUNESUITE_API_URL/admin/tickets?orderRelatedOnly=true&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# By status/priority
curl -s "$TUNESUITE_API_URL/admin/tickets?status=open&priority=high&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## Current API Limits

- "Unread by anyone" is not available as a single endpoint. Unread is user-relative.
- No direct `GET /.../tickets/by-order/:orderId`; use the order `ticketId` bridge flow above.
