---
name: tunesuite-stalwart-mail-ops
description: Audit, debug, refine, and smoke-test TuneSuite CRM email mailbox behavior and Stalwart production wiring, including mailbox scopes, alias sync, provisioning, and tenant mailbox caps.
metadata: {"openclaw":{"emoji":"mailbox","requires":{"bins":["rg","curl","jq"],"env":["TUNESUITE_API_URL"]}}}
---

# TuneSuite Stalwart Mail Ops

Use this skill for fast end-to-end diagnostics of TuneSuite CRM email behavior backed by Stalwart.

## When to use

- Tenant mailbox provisioning is failing or inconsistent.
- Existing Stalwart aliases are not reflected in CRM.
- Non-admin admin-like users can see unexpected email tickets.
- Mailbox cap behavior is unclear or misconfigured.
- You need a quick production smoke test before/after changes.

## Guardrails

- Never expose secrets (Stalwart admin creds, SMTP passwords, JWTs).
- Treat tenant isolation as absolute in every check.
- Prefer read/verify steps first; only run mutations when needed.
- For production mutations, confirm expected impact before execution.

## Canonical context (load in this order)

1. `docs/stalwart-mail-server.md`
2. `docs/CRM/crm-mailbox-access-control.md`
3. `docs/meta-crm-multitenant-smoke-test-runbook.md`
4. `docker/stalwart/server/config.toml`
5. `docker/stalwart/server/StalwartServerNotes.md`
6. `packages/api/src/modules/tickets/services/admin-mailbox-scopes.service.ts`
7. `packages/api/src/modules/tickets/services/tickets.service.ts`
8. `packages/api/src/modules/tenants/services/tenant-mailbox.service.ts`

## Expected behavior baseline (as of 2026-03-02)

- `ADMIN` and `SUPER_ADMIN`: always read all CRM email mailboxes.
- `MANAGER` / `SALES` / `TECHNICIAN`: default-deny for email mailbox visibility if no scopes assigned.
- Mailbox settings UI is admin-only.
- `maxTenantMailboxAddresses` default is `3`; `0` means unlimited.
- `POST /admin/tickets/mailbox-access/sync-stalwart` imports aliases from Stalwart and returns cap telemetry.

## Workflow

### 1) Validate API/runtime prerequisites

Confirm API base and tenant context are available:

```bash
: "${TUNESUITE_API_URL:?Set TUNESUITE_API_URL}"
: "${TUNESUITE_TENANT_ID:?Set TUNESUITE_TENANT_ID}"
: "${TUNESUITE_TOKEN:?Set TUNESUITE_TOKEN}"
```

### 2) Inspect mailbox registry and scopes

List tenant mailbox addresses:

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets/mailbox-access/mailbox-addresses" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

Inspect a target admin-like user's mailbox scopes:

```bash
curl -s "$TUNESUITE_API_URL/admin/tickets/mailbox-access/users/$TARGET_ADMIN_USER_ID/scopes" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" | jq
```

### 3) Sync aliases from Stalwart

```bash
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/mailbox-access/sync-stalwart" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" | jq
```

Expected response shape includes: `inboundUser`, `imported`, `existing`, `cap`, `currentCount`, `overLimit`.

### 4) Validate cap enforcement

Try adding one mailbox address beyond the expected cap and confirm API error:

```bash
curl -s -X POST "$TUNESUITE_API_URL/admin/tickets/mailbox-access/mailbox-addresses" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"emailAddress":"overflow-check@EXAMPLE_DOMAIN","isPrimary":false,"isActive":true}' | jq
```

Expected failure when limit reached: `MAILBOX_LIMIT_REACHED`.

### 5) Production Stalwart config audit

Verify these from production host/Coolify runtime:

- Server hostname and listeners are aligned with deployed domain.
- TLS certificate paths are valid and mounted.
- `proxy-protocol = true` is only enabled where Traefik sends it.
- Logging path/strategy is known and retrievable.
- Fallback admin account is present but secret never exposed in outputs.

Reference baseline in repo:
- `docker/stalwart/server/config.toml`
- `docker/stalwart/server/traefik.yaml`

### 6) CRM visibility smoke test

Run this matrix:

1. `ADMIN` sees all email tickets.
2. `MANAGER` with no scopes sees no email tickets.
3. Assign exactly one mailbox scope to that manager.
4. Manager now sees only that mailbox's email tickets.

If step 2 fails, inspect `getMailboxVisibilityScopeForAdminUser` and `applyAdminMailboxVisibility` in `tickets.service.ts`.

## Triage map

- Provisioning/sync anomalies:
  - `packages/api/src/modules/tickets/services/admin-mailbox-scopes.service.ts`
  - `packages/api/src/modules/tenants/services/tenant-mailbox.service.ts`
- Ticket visibility mismatches:
  - `packages/api/src/modules/tickets/services/tickets.service.ts`
- Inbound ingestion/tagging issues:
  - `packages/api/src/modules/tickets/services/ticket-inbox-polling.service.ts`
- Hub internal mailbox ops:
  - `packages/api/src/modules/tickets/services/hub-inbox-ops.service.ts`

## Output format for investigations

Return:

1. Tenant and environment checked.
2. Mailbox registry state (count, primary, active/inactive).
3. Scope state per target user.
4. Sync/cap findings (`imported`, `existing`, `cap`, `currentCount`, `overLimit`).
5. Visibility matrix pass/fail.
6. Concrete fix proposal with file paths and risk level.
