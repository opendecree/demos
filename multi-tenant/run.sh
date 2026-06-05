#!/bin/bash
# Multi-tenant demo walkthrough.
# Shows how two tenants share one schema with independent config values.
# Safe to re-run — every step is idempotent.
set -euo pipefail

DECREE_CLI="docker compose run --rm --no-TTY"
COMPOSE="docker compose"
SERVER="localhost:8080"

echo "=== Starting infrastructure ==="
$COMPOSE up -d postgres redis decree-server

echo ""
echo "=== Step 1: App deploys the schema ==="
echo "    The 'saas-ecommerce' schema is a deployment artifact."
echo "    It defines the config contract for all tenants — deployed once."
$COMPOSE run --rm seed-schema

echo ""
echo "=== Step 2: Tenant 1 (US store) provisions its config ==="
echo "    tenant1 references the schema by name and sets its own values:"
echo "      checkout.currency = USD"
echo "      checkout.tax_rate = 0.08"
echo "      pricing.free_tier_limit = 100"
$COMPOSE run --rm seed-tenant1

echo ""
echo "=== Step 3: Tenant 2 (EU store) onboards ==="
echo "    tenant2 shares the same schema but has completely independent values:"
echo "      checkout.currency = EUR"
echo "      checkout.tax_rate = 0.20"
echo "      pricing.free_tier_limit = 50"
$COMPOSE run --rm seed-tenant2

echo ""
echo "=== Starting admin panel ==="
$COMPOSE up -d admin

echo ""
echo "=== Waiting for decree REST API ==="
for i in $(seq 1 30); do
  curl -sf "http://${SERVER}/v1/server/info" >/dev/null 2>&1 && break
  sleep 2
done

echo ""
echo "=== Reading tenant1 config ==="
echo "    (US store — USD, 8% tax, 100 free-tier orders)"
curl -s "http://${SERVER}/v1/config/tenant1/snapshot" | \
  python3 -m json.tool 2>/dev/null || \
  curl -s "http://${SERVER}/v1/config/tenant1/snapshot"

echo ""
echo "=== Reading tenant2 config ==="
echo "    (EU store — EUR, 20% tax, 50 free-tier orders)"
curl -s "http://${SERVER}/v1/config/tenant2/snapshot" | \
  python3 -m json.tool 2>/dev/null || \
  curl -s "http://${SERVER}/v1/config/tenant2/snapshot"

echo ""
echo "=== Demonstrating isolation: changing tenant1 does not affect tenant2 ==="
echo "    Setting tenant1 checkout.tax_rate to 0.10 (a runtime override)..."
curl -s -X PUT "http://${SERVER}/v1/config/tenant1/values/checkout.tax_rate" \
  -H "Content-Type: application/json" \
  -H "X-Decree-Subject: demo-user" \
  -d '{"value": "0.10"}' | python3 -m json.tool 2>/dev/null || true

echo ""
echo "    tenant1 checkout.tax_rate after update:"
curl -s "http://${SERVER}/v1/config/tenant1/values/checkout.tax_rate" | \
  python3 -m json.tool 2>/dev/null || \
  curl -s "http://${SERVER}/v1/config/tenant1/values/checkout.tax_rate"

echo ""
echo "    tenant2 checkout.tax_rate (unchanged — still 0.20):"
curl -s "http://${SERVER}/v1/config/tenant2/values/checkout.tax_rate" | \
  python3 -m json.tool 2>/dev/null || \
  curl -s "http://${SERVER}/v1/config/tenant2/values/checkout.tax_rate"

echo ""
echo "=== Done ==="
echo "    Admin panel (all tenants): http://localhost:3000"
echo "    REST API:                  http://localhost:8080"
echo ""
echo "    Try it:"
echo "      curl http://localhost:8080/v1/config/tenant1/snapshot"
echo "      curl http://localhost:8080/v1/config/tenant2/snapshot"
echo ""
echo "    Run 'docker compose down -v' to tear down and remove all data."
