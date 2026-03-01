---
name: tunesuite-agent-platform-builder
description: Build and evolve the TuneSuite multi-tenant agent platform end-to-end (foundation to production) using canonical docs, current code, and OpenClaw runtime introspection with strict tenant isolation and freshness checks.
metadata: {"openclaw":{"emoji":"brain","requires":{"bins":["rg","jq","curl","git"]}}}
---

# TuneSuite Agent Platform Builder

Use this skill when the task is to design, implement, validate, or harden the multi-tenant agent platform.

## Non-Negotiables

- Treat tenant isolation as absolute.
- Execute through API/service layers only; no direct DB shortcuts for agent behavior.
- Never trust docs alone; verify against current code and runtime.
- For risky or destructive actions, require explicit approval flow.

## Canonical Sources (Load In This Order)

1. `docs/agent/00-INDEX.md`
2. `docs/agent-platform/agent-platform-current-state-handoff-2026-02-25.md`
3. `docs/agent-platform/00-MULTI-TENANT-AGENT-PLATFORM-SPEC.md`
4. `docs/agent-platform/01-VERIFIABLE-FOUNDATION-STEP.md` (historical baseline)
5. `docs/meta-crm-agent-handoff-2026-02-19.md`
6. `docs/meta-crm-multitenant-smoke-test-runbook.md`

Then verify implementation in:

- `packages/api/src/modules/agent/**`
- `packages/api/src/modules/tickets/**` (Meta CRM and channel wiring)
- `apps/tunesuite-hub/src/pages/dashboard/AgentUtilityPanel.tsx`
- `apps/tunesuite-hub/src/services/hub-agent.service.ts`
- `apps/tunesuite-instance/src/services/agent-chat.service.ts`

## Build Program (Foundation -> Top)

1. Baseline and drift scan.
2. Core platform implementation/repair.
3. Safety and policy hardening.
4. Tooling expansion with approvals.
5. Knowledge ingestion and retrieval.
6. Operationalization and rollout evidence.

### 1) Baseline and Drift Scan

- Run:
  - `bash openclaw-skills/tunesuite-agent-platform-builder/freshness-check.sh`
- Confirm route and policy invariants:
  - scoped routes: `/agent/chat/public|client|admin`
  - public context token path: `/agent/chat/public/context`
  - session scope violation blocking
  - tenant scope violation blocking

### 2) Core Platform Implementation/Repair

Minimum required surface:

- API:
  - `GET /agent/health`
  - `POST /agent/chat/public|client|admin`
  - `GET /agent/sessions/:id`
  - Hub control routes under `/hub/agent/*`
- UI:
  - Instance chat route selection by panel (`public`, `client`, `admin`)
  - Hub agent admin panel runtime/models/inspector workflows

### 3) Safety and Policy Hardening

Validate:

- Tenant context cannot be overridden by request body.
- Cross-scope session reuse is rejected.
- Public context token is required and short-lived.
- Memory writes are policy-gated by actor tier and scope.

### 4) Tooling Expansion with Approvals

When adding tools:

- Define capability by scope (`public`, `client`, `admin`).
- Record tool calls with trace IDs.
- Mark risk level and whether approval is mandatory.
- Ensure idempotency and rollback strategy.

### 5) Knowledge Ingestion and Retrieval

When implementing tenant knowledge:

- Keep strict per-tenant namespace separation.
- Track document version/provenance.
- Prefer curated playbooks over ad-hoc content.
- Reject unverified external corpora by default.

### 6) Operationalization and Rollout Evidence

Deliverables per increment:

- changed routes/modules
- policy changes
- tests added/updated
- smoke drill results
- go/no-go decision with explicit failure reasons

## OpenClaw Freshness Workflow

Use both local/runtime truth and official upstream truth.

1. Runtime truth (first):
   - Hub/API routes:
     - `/hub/agent/runtime`
     - `/hub/agent/models/status?probe=1`
     - `/hub/agent/models/providers/endpoints`
     - `/hub/agent/inspector`
2. Code truth (second):
   - `packages/api/src/modules/agent/services/openclaw-orchestration.service.ts`
   - `packages/api/src/modules/agent/controllers/hub-openclaw.controller.ts`
3. Official OpenClaw truth (third):
   - Check official OpenClaw release notes/changelog and docs before adopting new features.
   - Treat unofficial blog posts/videos as non-authoritative.

If upstream introduces new transport/methods/features:

- add compatibility notes in docs/agent-platform handoff
- add contract tests
- update this skill references

## Test Gates (Minimum)

- API focused tests:
  - `pnpm --filter @tunesuite/api test -- agent-route-matrix.spec.ts`
  - `pnpm --filter @tunesuite/api test -- tenant-scope.guard.spec.ts`
  - `pnpm --filter @tunesuite/api test -- public-agent-context.guard.spec.ts`
- Manual smoke:
  - hub runtime refresh + connection test + model probe
  - one chat flow per scope
  - one negative cross-scope session test

## Execution Style

- Make small, verifiable increments.
- Update canonical docs in the same change when behavior changes.
- When docs and code conflict, fix docs immediately after code verification.

## References

- `references/current-setup-map.md`
- `references/openclaw-freshness-sources.md`
