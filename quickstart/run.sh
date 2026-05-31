#!/bin/bash
# End-to-end quickstart: demonstrates decoupled schema + config seeding.
# Safe to re-run — every step is idempotent.
set -euo pipefail

COMPOSE="docker compose"

echo "=== Starting infrastructure ==="
$COMPOSE up -d postgres redis decree-server

echo ""
echo "=== Step 1: App deploys the schema ==="
echo "    The schema is a deployment artifact — it ships with the application,"
echo "    independent of any tenant or config values."
$COMPOSE run --rm seed-schema

echo ""
echo "=== Step 2: Acme Corp provisions its config ==="
echo "    The tenant references the schema by name; it does not redeclare it."
echo "    schema_version is omitted — binds to the latest published version."
$COMPOSE run --rm seed-acme

echo ""
echo "=== Step 3: Globex Corp onboards ==="
echo "    A second tenant shares the same schema with independent config values."
$COMPOSE run --rm seed-globex

echo ""
echo "=== Starting demo services ==="
$COMPOSE up -d admin payroll-service

echo ""
echo "=== Done ==="
echo "    Payroll Service dashboard: http://localhost:4000"
echo "    Admin panel (acme config): http://localhost:3000"
echo ""
echo "    Run 'docker compose down -v' to tear down and remove all data."
