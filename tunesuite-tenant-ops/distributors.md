# CRM Distributors

## 1 — List Distributors (Admin)

```bash
curl -s "$TUNESUITE_API_URL/distributors/admin?page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 2 — Get Distributor

```bash
curl -s "$TUNESUITE_API_URL/distributors/admin/DISTRIBUTOR_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## 3 — Create Distributor

```bash
curl -s -X POST "$TUNESUITE_API_URL/distributors/admin" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Distributor",
    "contact": {
      "email": "dist@example.com",
      "mobile": null,
      "telephone": null,
      "website": null
    },
    "location": {
      "lat": 40.4168,
      "lng": -3.7038,
      "city": "Madrid",
      "region": "Madrid",
      "country": "Spain",
      "address": null,
      "zip": null
    },
    "services": {
      "autos": true,
      "boats": false,
      "heavyMachinery": false,
      "motorcycles": true,
      "vehicles": true,
      "authorizedMechanic": false,
      "homeTechnician": false
    },
    "status": "active"
  }' | jq
```

## 4 — Update Distributor

```bash
curl -s -X PUT "$TUNESUITE_API_URL/distributors/admin/DISTRIBUTOR_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Distributor","status":"inactive"}' | jq
```

## 5 — Booking Settings

```bash
# Get
curl -s "$TUNESUITE_API_URL/distributors/admin/DISTRIBUTOR_ID/booking-settings" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Update
curl -s -X PUT "$TUNESUITE_API_URL/distributors/admin/DISTRIBUTOR_ID/booking-settings" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"bookingEnabled":true,"slotDurationMinutes":60}' | jq
```

## 6 — Delete Distributor

```bash
curl -s -X DELETE "$TUNESUITE_API_URL/distributors/admin/DISTRIBUTOR_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

## Public Helpers

```bash
# Public list by header
curl -s "$TUNESUITE_API_URL/distributors/public" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Unique filter values
curl -s "$TUNESUITE_API_URL/distributors/public/unique-values/country" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```
