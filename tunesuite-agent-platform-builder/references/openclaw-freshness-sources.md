# OpenClaw Freshness Sources

Use these in priority order.

## 1) Runtime Truth (Most Reliable For Current Behavior)

Inspect live behavior through Hub/API endpoints:

- `/hub/agent/runtime`
- `/hub/agent/models/status?probe=1`
- `/hub/agent/models/providers/endpoints`
- `/hub/agent/inspector`
- `/hub/agent/inspector/files/list`
- `/hub/agent/inspector/files/read`

These reflect active transport mode (`control_api` or `ssh_cli`), model routing, provider endpoint state, and runtime diagnostics.

## 2) Code Truth (Most Reliable For Intended Behavior)

Primary file:

- `packages/api/src/modules/agent/services/openclaw-orchestration.service.ts`

What to verify there:

- supported transports
- gateway methods used (`status`, `agent`, `agent.wait`)
- control API paths used (`/v1/gateway/call`, `/v1/models/*`, `/v1/files/*`)
- runtime file safety constraints and allowed root logic
- token provisioning and provider endpoint behavior

## 3) Official Upstream Truth (Latest Features / Versions)

Before planning new OpenClaw features:

- check official OpenClaw release notes/changelog
- check official OpenClaw docs for gateway/models/auth behavior
- confirm any breaking changes that affect current transport or command contract

Guideline:

- If official upstream conflicts with local runtime behavior, trust local runtime for immediate ops and open a migration task.
