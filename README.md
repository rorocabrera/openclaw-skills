# OpenClaw Skills

AI agent skills for TBase/TuneSuite tenant operations via the multi-tenant API.

## Available Skills

| Skill | Description |
|-------|-------------|
| [`tunesuite-tenant-ops/`](./tunesuite-tenant-ops/) | Full tenant operations: auth, orders, users, tickets, payments, leads, distributors, tasks, timeline, automation |

## Installation

Install via OpenClaw CLI:

```bash
openclaw skills add tbase/openclaw-skills/tunesuite-tenant-ops
```

Or clone directly:

```bash
git clone https://github.com/tbase-ai/openclaw-skills.git
```

## Updating

Pull latest changes:

```bash
git pull origin main
```

## Skill Structure

Each skill folder contains:
- `SKILL.md` — Main skill definition (entry point, auth bootstrap, guardrails)
- `package.json` — Skill metadata and module list
- `*.md` — Module docs (one per API domain: orders, tickets, users, etc.)

## Configuration

Set the API base URL before using any skill:

```bash
export TUNESUITE_API_URL="https://api.tunersuite.com/api"
```

For development/staging:
```bash
export TUNESUITE_API_URL="http://localhost:3000/api"
```

## Contributing

1. Edit skill modules in this repo
2. Test against local API (`localhost:3000`)
3. Submit a PR

## License

MIT
