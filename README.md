# TuneSuite OpenClaw Skills

OpenClaw skill pack that lets AI agents manage TuneSuite tenant operations through the API. Handles orders, tickets, users, payments, leads, CRM tasks, and automation — all via authenticated `curl` calls.

## What's inside

```
tunesuite-tenant-ops/
  SKILL.md          # Auth bootstrap, guardrails, session setup
  orders.md         # Order lifecycle, status updates, file handling
  tickets.md        # Ticket CRUD, close, message, assign, escalate
  users.md          # User management, roles, profiles
  payments.md       # Credit purchases, payment reports
  leads.md          # Lead submission, status tracking
  distributors.md   # Distributor management
  tasks.md          # CRM tasks, calendar, timeline, automation rules

tunesuite-agent-platform-builder/
  SKILL.md                           # End-to-end build workflow for multi-tenant agent platform
  references/current-setup-map.md    # Canonical docs, code touchpoints, route contracts
  references/openclaw-freshness-sources.md # Runtime/code/upstream freshness strategy
  freshness-check.sh                 # Quick drift and runtime freshness audit
```

## Quick start

1. Point to your API:

```bash
export TUNESUITE_API_URL="https://api.tunersuite.com/api"
```

2. Authenticate (the skill handles this automatically, but here's the manual flow):

```bash
# Resolve tenant
TUNESUITE_TENANT_ID=$(curl -s "$TUNESUITE_API_URL/tenants/public/code/YOUR_CODE" | jq -r '.id')

# Login
AUTH=$(curl -s -X POST "$TUNESUITE_API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -H "x-client-type: instance" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "x-panel-type: admin" \
  -d '{"email":"you@tenant.com","password":"..."}')

TUNESUITE_TOKEN=$(echo "$AUTH" | jq -r '.tokens.accessToken')
```

3. Use any endpoint. Example — close a ticket:

```bash
curl -s -X PUT "$TUNESUITE_API_URL/admin/tickets/TICKET_ID/status" \
  -H "Authorization: Bearer $TUNESUITE_TOKEN" \
  -H "x-tenant-id: $TUNESUITE_TENANT_ID" \
  -H "Content-Type: application/json" \
  -d '{"status":"closed"}'
```

## Requirements

- `curl` and `jq` available in PATH
- A TuneSuite tenant admin account
- `TUNESUITE_API_URL` env var set

## License

MIT
