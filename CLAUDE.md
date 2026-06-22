# OpenDecree Demos — Claude Context

## Overview

Hands-on examples for OpenDecree. Each demo is self-contained, runs via Docker Compose against a released decree server image.

## Status

Alpha — `quickstart`, `rest-walkthrough`, and `multi-tenant` are shipped and CI-tested. Remaining demos planned (see `.agents/context/demos-setup.md`). Everything subject to change.

## Structure

```
demos/
├── README.md          # Social-friendly landing page with scenario index
├── CONTRIBUTING.md    # How to add a demo
├── SECURITY.md        # Points to main repo advisories
├── CLAUDE.md          # This file
├── .agents/           # AI agent context
└── .github/           # Templates, workflows
```

When demos are added, each gets its own directory:
```
demo-name/
├── README.md              # What and why
├── docker-compose.yml     # Self-contained setup
├── test.sh                # CI validation
└── ...                    # Demo files
```

## Conventions

- Demos run against released Docker image (`ghcr.io/opendecree/decree:<version>`), not built from source
- Each demo must be independently runnable — no shared state between demos
- `docker compose up` from demo directory must work from a clean state
- Apache 2.0 license
- Alpha status — everything subject to change

### 0.12 server requirements

- **DB bootstrap:** a `migrate` service (decree-cli image, `command: ["migrate","up"]`) runs the migrations before `decree-server` starts — the 0.12 server assumes the unprivileged `decree_app` role on every connection and will not start against an unmigrated database. The server `depends_on` `migrate` with `condition: service_completed_successfully`. Do **not** create the schema via a postgres `init.sql`.
- **Local auth:** the demo server runs plaintext (`INSECURE_LISTEN=1`), so CLI/seed commands pass `--insecure`. The server also sets `DECREE_GATEWAY_TRUSTED_PROXY=1` so the HTTP gateway (admin UI + curl) accepts `x-subject` / `x-role` identity headers, which it rejects from clients by default. Cross-tenant REST calls use `x-role: superadmin`.

## Project Management

- Parent issue: opendecree/decree#30
- Milestone: SDK Examples
- `.agents/context/` holds design context for AI agents
