#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(pwd)}"

echo "== TuneSuite Agent Freshness Check =="
echo "Root: $ROOT_DIR"
echo

cd "$ROOT_DIR"

required_files=(
  "docs/agent/00-INDEX.md"
  "docs/agent-platform/agent-platform-current-state-handoff-2026-02-25.md"
  "packages/api/src/modules/agent/agent.controller.ts"
  "packages/api/src/modules/agent/controllers/hub-openclaw.controller.ts"
  "packages/api/src/modules/agent/services/openclaw-orchestration.service.ts"
)

echo "-- Required files --"
for f in "${required_files[@]}"; do
  if [[ -f "$f" ]]; then
    echo "OK  $f"
  else
    echo "MISS $f"
  fi
done
echo

echo "-- Latest commits (docs + agent core) --"
git log -1 --date=short --pretty=format:'%ad %h %s' -- docs/agent/00-INDEX.md || true
echo
git log -1 --date=short --pretty=format:'%ad %h %s' -- docs/agent-platform/agent-platform-current-state-handoff-2026-02-25.md || true
echo
git log -1 --date=short --pretty=format:'%ad %h %s' -- packages/api/src/modules/agent || true
echo

echo "-- Route markers --"
rg -n "Post\\('chat/public'\\)|Post\\('chat/client'\\)|Post\\('chat/admin'\\)|Post\\('chat/public/context'\\)|Controller\\(\\['hub/agent', 'hub/openclaw'\\]\\)" \
  packages/api/src/modules/agent \
  || true
echo

echo "-- Policy markers --"
rg -n "TENANT_SCOPE_VIOLATION|SESSION_SCOPE_VIOLATION|AGENT_MEMORY_WRITE_FORBIDDEN|AGENT_MEMORY_SCOPE_FORBIDDEN|AGENT_MEMORY_KEY_FORBIDDEN" \
  packages/api/src/modules/agent \
  || true
echo

echo "-- Transport markers --"
rg -n "OPENCLAW_ORCHESTRATION_TRANSPORT|control_api|ssh_cli|/v1/gateway/call|/v1/models/status|/v1/files/list|/v1/files/read" \
  packages/api/src/modules/agent/services/openclaw-orchestration.service.ts \
  || true
echo

if [[ -n "${TUNESUITE_API_URL:-}" && -n "${TUNESUITE_TOKEN:-}" ]]; then
  echo "-- Live runtime probe (optional) --"
  curl -sS "$TUNESUITE_API_URL/hub/agent/runtime" \
    -H "Authorization: Bearer $TUNESUITE_TOKEN" \
    | jq '{runtime: .runtime, gatewayStatus: .gateway.status}' || true

  echo
  curl -sS "$TUNESUITE_API_URL/hub/agent/models/status?probe=1" \
    -H "Authorization: Bearer $TUNESUITE_TOKEN" \
    | jq '{status, defaultModel: .defaultModelId, modelsPath: .modelsPath}' || true
  echo
else
  echo "-- Live runtime probe skipped --"
  echo "Set TUNESUITE_API_URL and TUNESUITE_TOKEN to enable hub runtime/model checks."
  echo
fi

echo "Freshness check done."
