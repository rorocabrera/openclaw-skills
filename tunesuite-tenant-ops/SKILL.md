---
name: tunesuite-tenant-ops
description: Manage all TuneSuite tenant operations through the multi-tenant API, including auth, orders, users, tickets, payments, leads, distributors, tasks, timeline, and automation.
metadata: {"openclaw":{"emoji":"🔧","requires":{"bins":["curl","jq"],"env":["TUNESUITE_API_URL"]}}}
---

# TuneSuite Tenant Operations

Use this as the single TuneSuite operations skill for tenant admin workflows through the multi-tenant API.

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

3. Authenticate (store access + refresh tokens):

```bash
AUTH_JSON=$(curl -s -X POST "$TUNESUITE_API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -H "x-client-type: instance" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-panel-type: admin" \
  -d '{"email":"ADMIN_EMAIL","password":"PASSWORD"}')

TUNESUITE_TOKEN=$(echo "$AUTH_JSON" | jq -r '.tokens.accessToken')
TUNESUITE_REFRESH_TOKEN=$(echo "$AUTH_JSON" | jq -r '.tokens.refreshToken')
TUNESUITE_ACCESS_EXPIRES_AT=$(echo "$AUTH_JSON" | jq -r '.tokens.accessTokenExpiresAt')
TUNESUITE_REFRESH_EXPIRES_AT=$(echo "$AUTH_JSON" | jq -r '.tokens.refreshTokenExpiresAt')
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

Before mutating orders/users data, verify the needed capability key:

```bash
echo "$TUNESUITE_CAPABILITIES" | jq -r '.capabilities["orders.updateStatus"]'
echo "$TUNESUITE_CAPABILITIES" | jq -r '.capabilities["users.delete"]'
```

If capability is `false`, do not execute the action.

For CRM routes (`leads`, `distributors`, `tasks`, `timeline`, `automation`, `task-series`),
current capabilities may not include explicit keys. Preflight with `/auth/me` roles and enforce
runtime `403` handling.

## Token Lifecycle

- Instance access token TTL: ~4h
- Refresh token TTL: ~30d
- Avoid repeated `/auth/login` calls (login is rate-limited to 5/minute per IP).

Refresh access token without re-login:

```bash
REFRESH_JSON=$(curl -s -X POST "$TUNESUITE_API_URL/auth/refresh-token" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$TUNESUITE_REFRESH_TOKEN\"}")

TUNESUITE_TOKEN=$(echo "$REFRESH_JSON" | jq -r '.tokens.accessToken')
TUNESUITE_REFRESH_TOKEN=$(echo "$REFRESH_JSON" | jq -r '.tokens.refreshToken')
TUNESUITE_ACCESS_EXPIRES_AT=$(echo "$REFRESH_JSON" | jq -r '.tokens.accessTokenExpiresAt')
TUNESUITE_REFRESH_EXPIRES_AT=$(echo "$REFRESH_JSON" | jq -r '.tokens.refreshTokenExpiresAt')
```

## Module Docs

- [Orders](./orders.md)
- [Users](./users.md)
- [Tickets](./tickets.md)
- [Payments](./payments.md)
- [Leads](./leads.md)
- [Distributors](./distributors.md)
- [Tasks](./tasks.md)

## Error Handling

- `401`: Refresh token once via `/auth/refresh-token`, then retry once.
- `404`: Re-check tenant scope and IDs.
- `429`: Use exponential backoff with jitter. Start `1s`, then `2s`, `4s`, `8s` (max `30s`).
- `403`: Refresh `/auth/capabilities` once, then report permission limitation if still denied.

## Output Style

- List results in concise tables where possible.
- For mutations, include: action, target, tenant, and resulting status.
- For no-op/failed operations, include concrete API error message.
