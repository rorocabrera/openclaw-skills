# TuneSuite Users Management

> ⚠️ **IMPORTANT**: Use API endpoints only. Do not use direct DB or server file access.

> 📡 **API Endpoint**: `https://api.tunersuite.com/api`

> 🔐 **Authentication Required**: See [./SKILL.md](./SKILL.md).

---

## When to Use

- "List users and filter by role/status"
- "Find a user by email/name"
- "Create or update a tenant user"
- "Delete a user"
- "Reset a user password"
- "Assign users to client groups"
- "Manage client access request/approval"

## Capability Preflight

Before user operations, verify capabilities from `/auth/capabilities`:

- `users.list`, `users.view`, `users.create`, `users.update`
- `users.delete`, `users.resetPassword`
- `users.assignClientGroup`, `users.setClientAccess`

Example:

```bash
echo "$TUNESUITE_CAPABILITIES" | jq -r '.capabilities["users.delete"]'
```

---

## 1 — List Users

```bash
curl -s "$TUNESUITE_API_URL/users?page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

### Common Filters

```bash
# Role filter
curl -s "$TUNESUITE_API_URL/users?role=technician&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Text search across email/name fields
curl -s "$TUNESUITE_API_URL/users?search=john@example.com&page=1&limit=20" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Additional filters
curl -s "$TUNESUITE_API_URL/users?status=active&country=ES&sortBy=createdAt&sortOrder=desc" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

---

## 2 — Get Single User

```bash
curl -s "$TUNESUITE_API_URL/users/USER_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

---

## 3 — List Technicians

```bash
curl -s "$TUNESUITE_API_URL/users/technicians" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

---

## 4 — Create User

```bash
curl -s -X POST "$TUNESUITE_API_URL/users" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "new.user@example.com",
    "password": "TempPass123$",
    "roles": ["client"],
    "profile": { "name": "New User", "country": "ES" }
  }' | jq
```

---

## 5 — Update User

```bash
curl -s -X PUT "$TUNESUITE_API_URL/users/USER_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "profile": { "name": "Updated Name", "phone": "+1234567890" }
  }' | jq
```

---

## 6 — Delete User

```bash
curl -s -X DELETE "$TUNESUITE_API_URL/users/USER_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

Requires `userDelete` permission.

---

## 7 — Password Operations

### User changes own password

```bash
curl -s -X POST "$TUNESUITE_API_URL/users/USER_ID/change-password" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"currentPassword":"OldPass123$","newPassword":"NewPass123$"}' | jq
```

### Admin/manager reset another user password

```bash
curl -s -X POST "$TUNESUITE_API_URL/users/USER_ID/admin-reset-password" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"newPassword":"TempReset123$"}' | jq
```

---

## 8 — Client Access Flow

### Request client access (self-service)

```bash
curl -s -X POST "$TUNESUITE_API_URL/users/client-access/request" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

### Set client access for a user (admin)

```bash
curl -s -X PATCH "$TUNESUITE_API_URL/users/USER_ID/client-access" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"clientAccess":"active"}' | jq
```

Allowed values: `none`, `pending`, `active`, `null`.

---

## 9 — Client Group Assignment

Assign/unassign users to a client group:

```bash
curl -s -X PATCH "$TUNESUITE_API_URL/users/client-group" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"userIds":["USER_ID_1","USER_ID_2"],"clientGroupId":"GROUP_ID"}' | jq
```

Set `"clientGroupId": null` to unassign.

---

## 10 — Client Groups CRUD

### List groups

```bash
curl -s "$TUNESUITE_API_URL/client-groups" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

### Create group (admin)

```bash
curl -s -X POST "$TUNESUITE_API_URL/client-groups" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"name":"VIP","description":"High value clients"}' | jq
```

### Update group (admin)

```bash
curl -s -X PUT "$TUNESUITE_API_URL/client-groups/GROUP_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"name":"VIP Updated"}' | jq
```

### Delete group (admin)

```bash
curl -s -X DELETE "$TUNESUITE_API_URL/client-groups/GROUP_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

---

## 11 — Counts and Validation Helpers

```bash
# Admin users usage
curl -s "$TUNESUITE_API_URL/users/admin/count" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Clients usage
curl -s "$TUNESUITE_API_URL/users/clients/count" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Country facets
curl -s "$TUNESUITE_API_URL/users/countries?search=jo" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Tax number uniqueness
curl -s "$TUNESUITE_API_URL/users/validate-tax-number/TAX123" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

---

## 12 — Admin Client Group Scopes (Advanced)

Manage per-admin group visibility scopes:

```bash
# Get visible scopes for admin user
curl -s "$TUNESUITE_API_URL/admin-client-group-scopes/ADMIN_USER_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Set visible scopes for admin user
curl -s -X PUT "$TUNESUITE_API_URL/admin-client-group-scopes/ADMIN_USER_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"groupIds":["GROUP_ID_1","GROUP_ID_2"]}' | jq
```

Hidden scope endpoints require `owner_ops` session:

```bash
# Get hidden group scopes
curl -s "$TUNESUITE_API_URL/admin-client-group-scopes/ADMIN_USER_ID/hidden" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# Set hidden group scopes
curl -s -X PUT "$TUNESUITE_API_URL/admin-client-group-scopes/ADMIN_USER_ID/hidden" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"groupIds":["GROUP_ID_3"]}' | jq
```

---

## Error Handling

- `401`: Re-authenticate and retry once.
- `403`: Refresh `/auth/capabilities` once; if still denied, report RBAC limitation.
- `404`: Confirm tenant scope and target user/group IDs.
- `400`: Show server validation message (role constraints, max users, invalid payload).

---

## Tips for the Agent

1. Always run `/auth/capabilities` before sensitive mutations.
2. Prefer `search=` (not `unifiedSearch`) for user lookup.
3. Include `x-tenant-id` in every request.
4. For destructive operations (`DELETE`, password reset, group deletion), confirm intent first.
5. Treat client-group visibility constraints as authoritative for list and assignment behavior.
