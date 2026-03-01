# Current Setup Map

## Canonical Docs

- `docs/agent/00-INDEX.md`
- `docs/agent-platform/agent-platform-current-state-handoff-2026-02-25.md`
- `docs/agent-platform/00-MULTI-TENANT-AGENT-PLATFORM-SPEC.md`
- `docs/meta-crm-agent-handoff-2026-02-19.md`
- `docs/meta-crm-multitenant-smoke-test-runbook.md`

## Core API Modules

- `packages/api/src/modules/agent/agent.controller.ts`
- `packages/api/src/modules/agent/agent.service.ts`
- `packages/api/src/modules/agent/agent.module.ts`
- `packages/api/src/modules/agent/controllers/hub-openclaw.controller.ts`
- `packages/api/src/modules/agent/services/hub-openclaw-admin.service.ts`
- `packages/api/src/modules/agent/services/openclaw-orchestration.service.ts`
- `packages/api/src/modules/agent/services/public-agent-context-token.service.ts`
- `packages/api/src/modules/agent/services/agent-memory-policy.service.ts`

## Integration/Channel Modules

- `packages/api/src/modules/tickets/controllers/ticket-channel-meta-oauth.controller.ts`
- `packages/api/src/modules/tickets/controllers/ticket-channel-connections.controller.ts`
- `packages/api/src/modules/tickets/controllers/ticket-channel-webhooks.controller.ts`
- `packages/api/src/modules/tickets/services/ticket-channel-meta-oauth.service.ts`
- `packages/api/src/modules/tickets/services/ticket-channel-connections.service.ts`

## Frontend Touchpoints

- `apps/tunesuite-hub/src/pages/dashboard/AgentUtilityPanel.tsx`
- `apps/tunesuite-hub/src/services/hub-agent.service.ts`
- `apps/tunesuite-instance/src/services/agent-chat.service.ts`
- `apps/tunesuite-instance/src/pages/admin/settings/MetaIntegrationsSettings.tsx`

## Key Route Contracts

- `GET /agent/health`
- `POST /agent/chat/public`
- `POST /agent/chat/public/context`
- `POST /agent/chat/client`
- `POST /agent/chat/admin`
- `GET /agent/sessions/:id`
- `GET /hub/agent/runtime`
- `POST /hub/agent/test-connection`
- `POST /hub/agent/chat`
- `GET /hub/agent/models/status`
- `GET /hub/agent/models/providers/endpoints`
- `POST /hub/agent/models/providers/endpoint`
- `POST /hub/agent/models/auth/paste-token`
- `GET /hub/agent/inspector`
- `POST /hub/agent/inspector/files/list`
- `POST /hub/agent/inspector/files/read`
