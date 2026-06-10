# Demos Repo Setup

## Purpose

Hands-on examples repo for OpenDecree — the "front door" for newcomers. Social-friendly, fun, easy to try.

## Decisions

- **Name:** `opendecree/demos` (not `decree-demos` — already under opendecree org)
- **Runtime:** demos run against released Docker image, not built from source
- **Independence:** each demo is self-contained, `docker compose up` from its directory
- **CI:** one job per shipped demo, runs `test.sh` (which does `docker compose up` + checks + teardown)
- **No releases:** this repo doesn't publish packages

## Parent Issue

opendecree/decree#30 — "Create decree-demos repo with end-to-end solution examples"

## Shipped Demos

1. **Quickstart** (`quickstart/`) — single tenant, create schema, set values, watch updates (beginner)
2. **No SDK (curl only)** (`rest-walkthrough/`) — full REST API walkthrough, zero install (beginner)
3. **Multi-Tenant** (`multi-tenant/`) — shared schemas, isolated config per tenant (intermediate)

## Planned Demos

4. **Pick Your Language** — same scenario in Go, Python, TypeScript (intermediate)
5. **Schema Evolution** — evolve schema safely, migrate tenants (intermediate)
6. **Config as Code** — version-controlled config with CI/CD (advanced)

## Scaffold Contents

Standard community files (LICENSE, CONTRIBUTING, SECURITY, CLAUDE.md), GitHub templates (bug report, PR template), workflows (CI, project automation, welcome bot), .agents context.
