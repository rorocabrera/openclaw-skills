# TuneSuite Payments

Use this module for payment approval flows currently exposed by the API.

## 1 — Manual Approve Product Order Bank Transfer

Endpoint:
`POST /product-orders/admin/:id/manual-approve-bank-transfer`

```bash
curl -s -X POST "$TUNESUITE_API_URL/product-orders/admin/PRODUCT_ORDER_ID/manual-approve-bank-transfer" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "adminNotes": "Bank transfer confirmed",
    "ticketId": "OPTIONAL_TICKET_ID",
    "paymentId": "OPTIONAL_REFERENCE"
  }' | jq
```

Allowed roles include admin-level tenant users.

## 2 — Manual Approve Credit Purchase

Endpoint:
`POST /credits/purchases/admin/:id/manual-approve`

```bash
curl -s -X POST "$TUNESUITE_API_URL/credits/purchases/admin/CREDIT_PURCHASE_ID/manual-approve" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "adminNotes": "Manual approval completed",
    "paymentProvider": "bank_transfer",
    "paymentId": "OPTIONAL_REFERENCE",
    "ticketId": "OPTIONAL_TICKET_ID",
    "metadata": {"source":"ops"}
  }' | jq
```

`paymentProvider` values:
- `stripe`
- `paypal`
- `bank_transfer`

## 3 — What Is Not Covered

- No manual payment-approval endpoint exists for `tenant-orders` (tuning orders).
- Product order Stripe/PayPal flows are verification-based (`/product-orders/verify` and `/product-orders/verify-paypal`), not admin manual approval for those providers.
