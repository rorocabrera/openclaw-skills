# TuneSuite Users Management

> ⚠️ **IMPORTANT**: This skill provides the ONLY interface to TuneSuite. Agents using this skill must use these API endpoints exclusively. Do NOT use direct database access, file system access to TuneSuite servers, or any other method. All data access must go through the API defined below.

> 📡 **API Endpoint**: `https://api.tunersuite.com/api` — This is the multi-tenant API that serves ALL TuneSuite tenants.

> 🔐 **Authentication Required**: See [./SKILL.md](./SKILL.md) for authentication setup.

---

## When to Use

- "List all users"
- "Show me technicians"
- "Find user by email"
- "Update user profile"
- "What roles does user X have?"

## Capability Preflight

Before user operations, ensure these capabilities are `true`:

- `users.list`, `users.view`, `users.update` for read/update flows
- `users.delete`, `users.resetPassword`, `users.assignClientGroup`, `users.changeCredits` for sensitive mutations

Check example:

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

### Filter by Role

```bash
# List only technicians
curl -s "$TUNESUITE_API_URL/users?role=technician" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# List only clients
curl -s "$TUNESUITE_API_URL/users?role=client" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq

# List admins
curl -s "$TUNESUITE_API_URL/users?role=admin" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

### Available Roles
- `admin` — Full access
- `manager` — Management functions
- `sales` — Sales functions
- `technician` — Can process orders
- `client` — End customers

### Response Format

```json
{
  "items": [
    {
      "id": "uuid",
      "email": "user@example.com",
      "roles": ["client"],
      "status": "active"
    }
  ],
  "meta": { "currentPage": 1, "itemsPerPage": 20, "totalItems": 45, "totalPages": 3 }
}
```

---

## 2 — Get Single User

```bash
curl -s "$TUNESUITE_API_URL/users/USER_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

### Response Fields

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "username": "username",
  "roles": ["client"],
  "status": "active",
  "profile": {
    "name": "Full Name",
    "phone": "+1234567890",
    "address": "...",
    "country": "ES",
    "zipCode": "28001",
    "taxNumber": "..."
  },
  "creditBalance": "100.00",
  "clientGroupId": null,
  "createdAt": "2025-01-15T10:30:00Z"
}
```

---

## 3 — Update User Profile

```bash
curl -s -X PUT "$TUNESUITE_API_URL/users/USER_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "profile": {
      "name": "New Name",
      "phone": "+1234567890"
    }
  }' | jq
```

### ⚠️ RBAC Note

Different roles have different permissions. If you get a permission error, check:
1. Are you using an admin/manager account?
2. Is your role allowed to modify this user's data?

---

## 4 — Find Users

### By Email

```bash
# Use unifiedSearch to find by email
curl -s "$TUNESUITE_API_URL/users?unifiedSearch=user@example.com" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

---

## 5 — User Status

User objects include a `status` field:
- `active` — User can login
- `inactive` — User cannot login

*(Status update endpoint to be verified)*

---

## 5 — Delete User

```bash
curl -s -X DELETE "$TUNESUITE_API_URL/users/USER_ID" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

⚠️ **Warning:** This permanently deletes the user. There is no trash/recovery.

---

## Handling Access Denied (RBAC)

When the authenticated user doesn't have permission:

### What to Check

1. **Your role** — Are you admin/manager?
2. **Target user's role** — Can you modify users with this role?
3. **Group scoping** — Are you limited to a specific group?

### Common Error Responses

```json
{
  "message": "Cannot add admin role. This tenant already has an admin user.",
  "statusCode": 400
}
```

Or filtered results (you only see what your role allows).

### RBAC Test Results (ecuengineers)

| Action | Manager | Notes |
|--------|---------|-------|
| List users | ✅ Allowed | Sees all users |
| Update user | ✅ Allowed | Can modify others |
| Delete user | ✅ Allowed | No restrictions! |
| Add admin role | ❌ Blocked | Proper error message |

**Note:** Manager role has broad permissions. Test with your own tenant to understand restrictions.

### How to Handle

1. **Check your permissions first:**
```bash
curl -s "$TUNESUITE_API_URL/auth/me" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" | jq '{email, roles}'
```

2. **If access denied:**
   - Inform the user they don't have permission
   - Suggest using an admin account
   - Don't attempt to bypass

---

## Groups (Under Investigation)

⚠️ **Groups feature is not fully tested.**

What we know:
- `clientGroupId` field exists on user objects (currently null in test tenant)
- `GET /client-groups` returns empty array
- Group assignment endpoints return 404

**Need:** A tenant with groups configured to test properly.

---

## Tips for the Agent

1. **Always authenticate first** — Store token in `$TUNESUITE_TOKEN`
2. **Include x-tenant-id header** on ALL requests
3. **Filter by role** — Use `?role=technician` to find technicians
4. **Check your permissions** — Use `/auth/me` to see your role
5. **Respect RBAC** — Don't try to bypass access restrictions
6. **Handle errors gracefully** — 403 means your role can't do this

---

## To Be Verified

- [ ] Update user status (activate/deactivate)
- [ ] Reset password
- [ ] Manage credits
- [ ] Assign to group
- [ ] Test RBAC with non-admin user

*See [./PROGRESS.md](./PROGRESS.md) for investigation status.*
