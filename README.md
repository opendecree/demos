# OpenDecree Demos

> See what schema-driven config management actually feels like.

This repo is a collection of hands-on examples that let you experience [OpenDecree](https://github.com/opendecree/decree) — from a 5-minute quickstart to production-grade patterns. Each demo is self-contained and runs with a single `docker compose up`.

> **Alpha Software** — OpenDecree is under active development. These demos track the latest release and may change between versions.

## Prerequisites

- **Docker** and **Docker Compose**

That's it. No language runtimes, no database setup, no fuss.

## Pick Your Path

> **Coming soon** — demos are being built. Star the repo to get notified!

| Demo | What You'll Learn | Difficulty |
|------|------------------|------------|
| **[Quickstart](quickstart/)** | Create a schema, set config values, watch them update live | Beginner |
| **[No SDK (curl only)](rest-walkthrough/)** | Drive the full REST API with nothing but curl — zero install | Beginner |
| **[Pick Your Language](multi-language/)** | The same scenario in Go, Python, and TypeScript side by side | Intermediate |
| **[Multi-Tenant](multi-tenant/)** | Shared schemas, isolated config per tenant | Intermediate |
| **[Schema Evolution](schema-evolution/)** | Evolve your schema safely — add fields, tighten constraints, migrate tenants | Intermediate |
| **[Config as Code](config-as-code/)** | Version-controlled config with CI/CD — seed, validate, promote | Advanced |

### Just want one demo?

You don't need to clone the entire repo:

```bash
# Grab a single demo with sparse checkout
git clone --no-checkout https://github.com/opendecree/demos.git
cd demos
git sparse-checkout set quickstart
git checkout
```

### What each demo includes

- A **README** with what you'll learn, step-by-step walkthrough, and things to try yourself
- A **docker-compose.yml** that starts everything (decree server, Postgres, Redis)
- A **`test.sh`** script that CI runs to verify the demo works
- **Cleanup** instructions — `docker compose down -v` and you're back to clean

## What Is OpenDecree?

OpenDecree is an open-source business configuration management service. You define **schemas** (what config looks like), then manage **config values** per tenant — with types, constraints, validation, audit trails, and live updates built in.

Think of it as "database migrations, but for your business config."

- **Schema-driven** — define once, get validation + docs + type safety everywhere
- **Multi-tenant** — one service, many tenants, shared or independent schemas
- **Live updates** — SDKs watch for changes in real time, no polling
- **Language-agnostic** — Go, Python, TypeScript SDKs, plus a full REST/gRPC API

## Want to Contribute a Demo?

We'd love that. Check out [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines and the demo README template. If you have an idea but aren't sure where to start, open a [Discussion](https://github.com/orgs/opendecree/discussions) on our community hub.

## What's Next?

- [OpenDecree](https://github.com/opendecree/decree) — the core service, CLI, and Go SDKs
- [Python SDK](https://github.com/opendecree/decree-python) — `pip install opendecree`
- [TypeScript SDK](https://github.com/opendecree/decree-typescript) — `npm install @opendecree/sdk`
- [Admin GUI](https://github.com/opendecree/decree-ui) — browser-based config management

## Questions?

Head to [OpenDecree Discussions](https://github.com/orgs/opendecree/discussions) — our community hub covers all OpenDecree repos.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
