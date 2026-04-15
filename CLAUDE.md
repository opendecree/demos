# OpenDecree Demos — Claude Context

## Overview

Hands-on examples for OpenDecree. Each demo is self-contained, runs via Docker Compose against a released decree server image.

## Status

Alpha — scaffold only, no demos yet.

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

## Project Management

- Parent issue: opendecree/decree#30
- Milestone: SDK Examples
- `.agents/context/` holds design context for AI agents
