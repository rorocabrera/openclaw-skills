---
name: tunesuite-tenant-ops
description: Manage TuneSuite tenant operations through the multi-tenant API, including tenant login, orders, users, assignments, statuses, and file workflows.
metadata: {"openclaw":{"emoji":"🔧","requires":{"bins":["curl","jq"],"env":["TUNESUITE_API_URL"]}}}
---

# TuneSuite Tenant Operations

Use this skill for TuneSuite tenant admin operations (orders + users) through the multi-tenant API.

## Guardrails

- Use API endpoints only. Do not use direct DB queries or server file access.
- Treat credentials and tokens as secrets. Never echo raw credentials in summaries.
- Include `x-tenant-id` in every authenticated request.
- Confirm with the user before destructive or financially impactful actions.
- If a request changes state, show a short impact summary before execution.

## API Base URL

`https://api.tunersuite.com/api`

Set once per session:

```bash
export TUNESUITE_API_URL="https://api.tunersuite.com/api"
```

## Session Bootstrap (Required)

1. Collect tenant code, admin email, and admin password.
2. Resolve tenant ID:

```bash
TUNESUITE_TENANT_ID=$(curl -s "$TUNESUITE_API_URL/tenants/public/code/TENANT_CODE" | jq -r '.id')
```

3. Authenticate:

```bash
TUNESUITE_TOKEN=$(curl -s -X POST "$TUNESUITE_API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -H "x-client-type: instance" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-panel-type: admin" \
  -d '{"email":"ADMIN_EMAIL","password":"PASSWORD"}' \
  | jq -r '.tokens.accessToken')
```

4. Verify identity and roles:

```bash
curl -s "$TUNESUITE_API_URL/auth/me" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq '{email, roles}'
```

5. Fetch effective RBAC capabilities (required before operations):

```bash
TUNESUITE_CAPABILITIES=$(curl -s "$TUNESUITE_API_URL/auth/capabilities" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID")

echo "$TUNESUITE_CAPABILITIES" | jq '{roles, policyVersion, capabilities, constraints}'
```

Before mutating data, verify the needed capability key:

```bash
echo "$TUNESUITE_CAPABILITIES" | jq -r '.capabilities["orders.updateStatus"]'
echo "$TUNESUITE_CAPABILITIES" | jq -r '.capabilities["users.delete"]'
```

If capability is `false`, do not execute the action.

## Module Docs

- [Orders](./orders.md)
- [Users](./users.md)
- [Progress](./PROGRESS.md)

## Error Handling

- `401`: Re-authenticate and retry once.
- `404`: Re-check tenant scope and IDs.
- `429`: Wait and retry with backoff.
- `403`: Refresh `/auth/capabilities` once, then report permission limitation if still denied.

## Output Style

- List results in concise tables where possible.
- For mutations, include: action, target, tenant, and resulting status.
- For no-op/failed operations, include concrete API error message.
