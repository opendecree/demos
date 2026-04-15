# OpenDecree Demos

> See what schema-driven config management actually feels like.

This repo is a collection of hands-on examples that let you experience [OpenDecree](https://github.com/opendecree/decree) — from a 5-minute quickstart to production-grade patterns. Each demo is self-contained and runs with a single `docker compose up`.

## Prerequisites

- **Docker** and **Docker Compose**

That's it. No language runtimes, no database setup, no fuss.

## Pick Your Path

> **Coming soon** — demos are being built. Star the repo to get notified!

| Demo | What You'll See | Difficulty |
|------|----------------|------------|
| **Quickstart** | Create a schema, set config values, watch them update live | Beginner |
| **No SDK (curl only)** | The full REST API with nothing but curl — zero install | Beginner |
| **Pick Your Language** | The same scenario in Go, Python, and TypeScript side by side | Intermediate |
| **Multi-Tenant** | Shared schemas, isolated config per tenant | Intermediate |
| **Schema Evolution** | Evolve your schema safely — add fields, tighten constraints, migrate tenants | Intermediate |
| **Config as Code** | Version-controlled config with CI/CD — seed, validate, promote | Advanced |

Each demo includes:
- A `README.md` explaining what it does and why you'd care
- A `docker-compose.yml` that starts everything you need
- A step-by-step walkthrough you can follow or just read

## What Is OpenDecree?

OpenDecree is an open-source business configuration management service. You define **schemas** (what config looks like), then manage **config values** per tenant — with types, constraints, validation, audit trails, and live updates built in.

Think of it as "database migrations, but for your business config."

- **Schema-driven** — define once, get validation + docs + type safety everywhere
- **Multi-tenant** — one service, many tenants, shared or independent schemas
- **Live updates** — SDKs watch for changes in real time, no polling
- **Language-agnostic** — Go, Python, TypeScript SDKs, plus a full REST/gRPC API

## Want to Contribute a Demo?

We'd love that. Check out [CONTRIBUTING.md](CONTRIBUTING.md) for how to add a new demo. If you have an idea but aren't sure where to start, open a [Discussion](https://github.com/opendecree/decree/discussions) in the main repo.

## What's Next?

- [OpenDecree](https://github.com/opendecree/decree) — the core service, CLI, and Go SDKs
- [Python SDK](https://github.com/opendecree/decree-python) — `pip install opendecree`
- [TypeScript SDK](https://github.com/opendecree/decree-typescript) — `npm install @opendecree/sdk`
- [Admin GUI](https://github.com/opendecree/decree-ui) — browser-based config management

## License

Apache License 2.0 — see [LICENSE](LICENSE).
