---
name: tunesuite-orders
description: Manage TuneSuite ECU tuning orders — list, search, inspect, update orders, download/upload ECU files, view order history, assign technicians, and change order details for any tenant instance
emoji: "\U0001F527"
requires:
  bins: [curl, jq]
  env: [TUNESUITE_API_URL]
config:
  defaultPageSize: "20"
---

# TuneSuite Orders Management

> ⚠️ **IMPORTANT**: This skill provides the ONLY interface to TuneSuite. Agents using this skill must use these API endpoints exclusively. Do NOT use direct database access, file system access to TuneSuite servers, or any other method. All data access must go through the API defined below.

> 📡 **API Endpoint**: `https://api.tunersuite.com/api` — This is the multi-tenant API that serves ALL TuneSuite tenants. All endpoints below are relative to this base URL.

The agent can work with **any tenant** — the user provides a tenant code (e.g., "mycompany") and admin credentials, and the agent resolves everything automatically.

## When to Use

- "List my recent orders"
- "Search for order by email john@example.com"
- "Show me details of order abc-123"
- "What services were selected on order X?"
- "What vehicle is on order X?"
- "Download the original file from order X"
- "Upload a modified file to order X"
- "Change order status to IN_PROGRESS"
- "Assign technician to order"
- "Show order history for order X"
- "What files are attached to order X?"
- "Connect to tenant mycompany"

---

## Step 0 — Connect to a Tenant

Before any operation, you need three things from the user:
1. **Tenant code** (the slug/subdomain, e.g., `mycompany` from `mycompany.tunersuite.com`)
2. **Admin email** for that tenant instance
3. **Admin password**

Ask the user for these if not already provided. A user may say something like "connect to mycompany with admin@example.com / password123" — extract the three values.

### 0a — Resolve Tenant Code to Tenant ID

The tenant code is the human-readable slug (e.g., "mycompany" from "mycompany.tunersuite.com"). You must resolve it to a UUID first:

```bash
TUNESUITE_TENANT_ID=$(curl -s "$TUNESUITE_API_URL/tenants/public/code/TENANT_CODE_HERE" | jq -r '.id')
```

If the result is `null`, the tenant code is wrong. Ask the user to double-check.

You can also verify the tenant is active:
```bash
curl -s "$TUNESUITE_API_URL/tenants/public/code/TENANT_CODE_HERE" | jq '{id, code, name, status}'
```

Only proceed if `status` is `"active"`.

### 0b — Authenticate

```bash
TUNESUITE_TOKEN=$(curl -s -X POST "$TUNESUITE_API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -H "x-client-type: instance" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-panel-type: admin" \
  -d "{\"email\": \"USER_EMAIL_HERE\", \"password\": \"USER_PASSWORD_HERE\"}" \
  | jq -r '.tokens.accessToken')
```

If the token is `null` or empty, authentication failed. Check credentials and tenant ID.

**Verify authentication works:**
```bash
curl -s "$TUNESUITE_API_URL/auth/me" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq '.email, .roles'
```

After authenticating, use `$TUNESUITE_TENANT_ID` and `$TUNESUITE_TOKEN` in all subsequent requests.

### Switching Tenants

To work with a different tenant, simply repeat Step 0 with the new tenant code and credentials. The agent can manage multiple tenants in one session — just re-resolve and re-authenticate.

---

## 1 — List Orders (with pagination and filtering)

```bash
curl -s "$TUNESUITE_API_URL/tenant-orders?page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

### Available Query Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | number | Page number (starts at 1) |
| `limit` | number | Items per page (default 20, max 100) |
| `unifiedSearch` | string | Search across order ID, client email, client name, model name, comments |
| `orderId` | string | Filter by exact or partial order UUID |
| `clientEmail` | string | Filter by client email |
| `technicianId` | string | Filter by assigned technician UUID |
| `status[]` | string | Filter by status (can repeat for multiple). Values: `CREATED`, `PENDING_ASSIGNMENT`, `ASSIGNED`, `IN_PROGRESS`, `REVIEWING`, `WAITING_CREDITS`, `COMPLETED`, `CANCELLED`, `REFUNDED` |
| `modelName` | string | Filter by ECU model name |
| `vehicleTypeId` | string | Filter by vehicle type UUID |
| `brandId` | string | Filter by brand UUID |
| `sortOrder` | string | `ASC` or `DESC` (by creation date) |

### Examples

**Search by client email:**
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders?unifiedSearch=john@example.com&page=1&limit=10" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

**Search by client name:**
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders?unifiedSearch=John%20Smith&page=1&limit=10" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

**Search by order ID (partial UUID works with 2+ characters):**
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders?unifiedSearch=abc123&page=1&limit=10" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

**Filter by multiple statuses:**
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders?status[]=IN_PROGRESS&status[]=ASSIGNED&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

**Filter by status and sort descending:**
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders?status[]=COMPLETED&sortOrder=DESC&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

### Response Format

```json
{
  "data": [
    {
      "id": "uuid",
      "status": "IN_PROGRESS",
      "totalPrice": "150.00",
      "createdAt": "2025-01-15T10:30:00Z",
      "updatedAt": "2025-01-15T12:00:00Z",
      "client": { "id": "uuid", "email": "client@example.com", "profile": { "name": "Client Name" } },
      "technician": { "id": "uuid", "email": "tech@example.com" },
      "model": { "id": "uuid", "name": "BMW N55" },
      "vehicleType": { "id": "uuid", "name": "Car" },
      "services": [ { "id": "uuid", "service": { "name": "Stage 1" }, "price": "100.00" } ],
      "vehicleDetails": { "brand": "BMW", "model": "335i", "year": 2015, "vin": "..." },
      "files": [ { "id": "uuid", "filename": "original.bin", "isOriginal": true } ],
      "quotationSnapshot": { "breakdown": { "finalTotal": 150, "services": [...] } }
    }
  ],
  "meta": { "page": 1, "limit": 20, "totalItems": 45, "totalPages": 3 }
}
```

### Presenting Order Lists to the User

When showing a list of orders, present a clean summary table with these columns:
- **Order ID** (first 8 characters of UUID)
- **Client** (name + email)
- **Status**
- **Model** (ECU model name)
- **Vehicle** (brand + model + year)
- **Total Price**
- **Created** (date only)

---

## 2 — Get Order Details

```bash
curl -s "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

This returns the full order with all relations: client, technician, model, services, vehicleDetails, files, history, and quotationSnapshot.

### Key Fields to Present

**Order Info:**
- `id`, `status`, `totalPrice`, `createdAt`, `updatedAt`

**Client Info:**
- `client.email`, `client.profile.name`, `client.profile.phone`

**Technician:**
- `technician.email`, `technician.profile.name` (null if unassigned)

**Vehicle Details** (`vehicleDetails`):
- `brand`, `model`, `year`, `power`, `displacement`, `vin`, `comments`, `additionalInfo`

**Services Selected** (`services` array):
- Each item has `service.name` and `price`

**Quotation Snapshot** (`quotationSnapshot`):
- `breakdown.basePrice` — base price before multipliers
- `breakdown.vehicleMultiplier` — vehicle type multiplier
- `breakdown.finalTotal` — final price charged
- `breakdown.services[]` — per-service pricing detail

**Files** (`files` array):
- `id`, `filename`, `isOriginal`, `isVisibleToClient`, `createdAt`
- `internalNotes`, `clientComment`
- `ecuDecodeMetadata` — decoded ECU info (if available)

**Order History** (`history` array):
- `changeDescription` — type of change (see list below)
- `changeComment` — user notes on the change
- `previousValues`, `newValues` — JSONB snapshots of what changed
- `changedBy.email` — who made the change
- `createdAt` — when the change happened

**History Change Types:**
`VEHICLE_DETAILS`, `SERVICES`, `MODEL`, `FILE_VISIBILITY`, `ORDER_STATUS`, `FILE_UPLOAD`, `FILE_DELETE`, `FILE_UPDATE`, `FILE_DOWNLOAD`, `FILE_ENCRYPTION`, `FILE_DECRYPTION`, `FILE_ACCESS`, `TECH_ASSIGNMENT`, `REFUND`

---

## 3 — Get Orders for a Specific User

First find the user ID by searching orders:
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders?unifiedSearch=user@email.com&page=1&limit=1" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq '.data[0].client.id'
```

Then fetch all their orders:
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders/user/USER_ID_HERE?page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

Supports the same filtering parameters as the main list endpoint (`status[]`, `modelName`, `sortOrder`, etc.).

---

## 4 — Get New Orders Count

```bash
curl -s "$TUNESUITE_API_URL/tenant-orders/new-count" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

Returns a number representing orders with `CREATED` status.

---

## 5 — Update Order Status

```bash
curl -s -X PATCH "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE/status" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "NEW_STATUS_HERE", "comment": "Optional reason for status change"}' | jq
```

### Valid Status Transitions

| Current Status | Can Transition To |
|---------------|-------------------|
| `CREATED` | `PENDING_ASSIGNMENT`, `IN_PROGRESS`, `CANCELLED` |
| `PENDING_ASSIGNMENT` | `ASSIGNED`, `IN_PROGRESS`, `CANCELLED` |
| `ASSIGNED` | `IN_PROGRESS`, `CANCELLED` |
| `IN_PROGRESS` | `REVIEWING`, `COMPLETED`, `WAITING_CREDITS`, `CANCELLED` |
| `REVIEWING` | `IN_PROGRESS`, `COMPLETED`, `WAITING_CREDITS` |
| `WAITING_CREDITS` | `IN_PROGRESS`, `COMPLETED`, `CANCELLED` |
| `COMPLETED` | `REFUNDED` |

**IMPORTANT:** Always confirm with the user before changing status. Status changes trigger notifications and credit operations.

---

## 6 — Assign Technician

```bash
curl -s -X PATCH "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE/assign-technician" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"technicianEmail": "tech@example.com", "comment": "Optional assignment comment"}' | jq
```

---

## 7 — Update Vehicle Details

```bash
curl -s -X PATCH "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE/vehicle-details" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userEmail": "client@example.com",
    "vehicleDetails": {
      "brand": "BMW",
      "model": "335i",
      "year": 2015,
      "power": 306,
      "displacement": "2979cc",
      "vin": "WBAXXXXXXXXXXXXXX",
      "comments": "Updated info"
    },
    "changeReason": "Client provided corrected details"
  }' | jq
```

All fields in `vehicleDetails` are optional — only include the fields you want to change. The `userEmail` is the client's email (order owner). `changeReason` is optional but recommended for audit trail.

---

## 8 — Update Order Services (Change Selected Services)

```bash
curl -s -X PATCH "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE/services" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userEmail": "client@example.com",
    "newQuotation": {
      "modelId": "model-uuid",
      "services": ["service-uuid-1", "service-uuid-2"],
      "price": 200,
      "currency": "EUR",
      "breakdown": {
        "services": [
          { "amount": 100, "isSingle": false, "serviceId": "service-uuid-1", "percentage": "100", "serviceName": "Stage 1" },
          { "amount": 100, "isSingle": false, "serviceId": "service-uuid-2", "percentage": "100", "serviceName": "DPF Delete" }
        ],
        "basePrice": 200,
        "finalTotal": 200,
        "vehicleMultiplier": "1"
      }
    },
    "changeReason": "Client requested additional service"
  }' | jq
```

**WARNING:** Changing services recalculates the order price and may deduct or refund credits. Always confirm with the user first.

---

## 9 — Change ECU Model

```bash
curl -s -X PATCH "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE/model" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "modelId": "new-model-uuid",
    "userEmail": "client@example.com",
    "changeReason": "Wrong model selected initially"
  }' | jq
```

---

## 10 — Download Files

### Download Original File (with optional decryption)

**Without decryption:**
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders/ORDER_ID/files/FILE_ID/download-original" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -o downloaded_file.bin
```

**With decryption (for Alientech/MMS encrypted files):**
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders/ORDER_ID/files/FILE_ID/download-original?decrypt=true" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -o decrypted_file.bin
```

Decryption requires the tenant to have valid Alientech or Magic Motorsport API keys configured.

### Listing Files for an Order

Files are included in the order detail response. To see just the files:
```bash
curl -s "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq '.files[] | {id, filename, isOriginal, isVisibleToClient, createdAt, internalNotes, clientComment}'
```

---

## 11 — Upload Modified File

```bash
curl -s -X POST "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE/files?encrypt=false" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -F "file=@/path/to/modified_file.bin" | jq
```

### With encryption (auto-encrypts for the client's ECU tool):
```bash
curl -s -X POST "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE/files?encrypt=true" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -F "file=@/path/to/modified_file.bin" | jq
```

### For Magic Motorsport tools (requires memoryType):
```bash
curl -s -X POST "$TUNESUITE_API_URL/tenant-orders/ORDER_ID_HERE/files?encrypt=true" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -F "file=@/path/to/modified_file.bin" \
  -F "memoryType=int_flash" | jq
```

Valid `memoryType` values: `int_flash`, `ext_flash`, `int_eeprom`, `ext_eeprom`, `maps`, `full_dump`

### Response:
```json
{
  "orderFile": {
    "id": "uuid",
    "filename": "modified_file.bin",
    "isOriginal": false,
    "isVisibleToClient": true
  },
  "encryptionStatus": "success" | "skipped" | "failed"
}
```

---

## 12 — Update File Metadata

```bash
curl -s -X PATCH "$TUNESUITE_API_URL/tenant-orders/ORDER_ID/files/FILE_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "isVisibleToClient": true,
    "internalNotes": "Modified with Stage 1 map",
    "clientComment": "Stage 1 tune applied"
  }' | jq
```

---

## 13 — Rename File

```bash
curl -s -X PATCH "$TUNESUITE_API_URL/tenant-orders/ORDER_ID/files/FILE_ID/rename" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"newFileName": "BMW_335i_Stage1_Modified.bin"}' | jq
```

---

## 14 — Delete Modified File

```bash
curl -s -X DELETE "$TUNESUITE_API_URL/tenant-orders/ORDER_ID/files/FILE_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq
```

**Note:** Only modified files (isOriginal = false) can be deleted. Original uploads cannot be deleted.

---

## 15 — Search by VIN (Public Endpoint)

This endpoint is public and does not require authentication:
```bash
curl -s "$TUNESUITE_API_URL/orders/public/by-vin/WBAXXXXXXXXXXXXXX" | jq
```

Returns completed orders matching the VIN.

---

## Order Status Reference

| Status | Meaning |
|--------|---------|
| `CREATED` | New order, awaiting processing |
| `PENDING_ASSIGNMENT` | Needs technician assignment |
| `ASSIGNED` | Technician assigned, not yet started |
| `IN_PROGRESS` | Technician actively working |
| `REVIEWING` | Work done, under review |
| `WAITING_CREDITS` | Client needs to add credits |
| `COMPLETED` | Finished and delivered |
| `CANCELLED` | Order cancelled |
| `REFUNDED` | Credits refunded after completion |

---

## Error Handling

Common HTTP status codes:
- `200` — Success
- `201` — Created (new order, new file)
- `400` — Bad request (invalid data, validation error)
- `401` — Unauthorized (token expired or invalid — re-authenticate)
- `403` — Forbidden (insufficient permissions)
- `404` — Not found (order/file doesn't exist or wrong tenant)
- `429` — Rate limited (too many requests)

If you get `401`, re-run Step 0 to get a fresh token.

Parse error messages from the response body:
```bash
curl -s ... | jq '.message'
```

---

## Tips for the Agent

1. **Always authenticate first** before any operation. Store the token in `$TUNESUITE_TOKEN`.
2. **Use `unifiedSearch`** for flexible searching — it covers order ID, email, name, model name, and comments simultaneously.
3. **Present data clearly** — format order lists as tables and order details as structured sections.
4. **Confirm destructive actions** — always ask the user before changing status, updating services (affects credits), or deleting files.
5. **Handle pagination** — check `meta.totalPages` and inform the user if there are more pages.
6. **Token expiry** — instance tokens last 4 hours. If you get 401 errors, re-authenticate.
7. **File downloads** — binary files are streamed. Use `-o filename` to save them.
8. **Encryption** — only use `encrypt=true` or `decrypt=true` when the tenant has valid tool API keys configured.

---

## Setup

### Environment Variables

Only the API base URL is required as an environment variable. Tenant code and credentials are provided by the user at runtime.

```bash
export TUNESUITE_API_URL="https://api.tunersuite.com/api"   # TuneSuite multi-tenant API base URL (REQUIRED /api suffix)
```

### How It Works

1. The TuneSuite API (`https://api.tunersuite.com/api`) serves **all tenants** — it's a multi-tenant API
2. The user tells the agent their **tenant code** (e.g., "mycompany") and **admin credentials**
3. The agent resolves the code to a tenant UUID via `GET /tenants/public/code/{code}`
4. The agent authenticates via `POST /auth/login` with the resolved UUID
5. All subsequent operations use the JWT token and tenant-specific endpoints

### Verifying Setup

```bash
# Test that the API is reachable
curl -s "$TUNESUITE_API_URL/tenants/public/code/any-tenant-code" | jq '.id'
```

If this returns a UUID, the API URL is correct.

### Multi-Tenant Support

The agent can switch between tenants in a single session. Each time the user says "connect to [tenant-code]", the agent re-resolves and re-authenticates. No restart needed.

---

## Troubleshooting

### Tenant code returns null ID
- Verify the tenant code is spelled correctly (it's the subdomain slug, not the display name)
- Ask the user to confirm their tenant code from their URL: `CODE.tunersuite.com`

### "Unauthorized" or null token
- Verify the email and password are correct for this specific tenant
- Ensure the user has admin role on the instance
- Check `TUNESUITE_API_URL` has no trailing slash

### "Not Found" on order endpoints
- Verify the order ID is correct and belongs to this tenant
- Orders from other tenants return 404

### "Rate Limited" (429)
- Login: max 5 attempts per 60 seconds
- Wait and retry, or check credentials first

### File download returns HTML/error instead of binary
- Ensure you're using the correct file ID from the order's `files` array
- Check if the file requires decryption (`decrypt=true` query param)

### Token expired mid-session
- Instance access tokens expire after 4 hours
- Re-run Step 0b to get a fresh token

### Switching tenants doesn't work
- Make sure you re-resolve the tenant code (Step 0a) AND re-authenticate (Step 0b)
- The JWT token is tenant-specific — you can't reuse it across tenants
