#!/bin/bash
# Multi-tenant demo walkthrough.
# Shows how two tenants share one schema with independent config values.
# Safe to re-run — every step is idempotent.
set -euo pipefail

DECREE_CLI="docker compose run --rm --no-TTY"
COMPOSE="docker compose"
SERVER="localhost:8080"
SUBJECT="demo-user"

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
  curl -sf "http://${SERVER}/v1/server/info" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin" >/dev/null 2>&1 && break
  sleep 2
done

echo ""
echo "=== Looking up tenant IDs ==="
TENANTS=$(curl -sf "http://${SERVER}/v1/tenants" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin")
TENANT1_ID=$(echo "$TENANTS" | python3 -c "import sys,json; print(next(t['id'] for t in json.load(sys.stdin)['tenants'] if t['name']=='tenant1'))")
TENANT2_ID=$(echo "$TENANTS" | python3 -c "import sys,json; print(next(t['id'] for t in json.load(sys.stdin)['tenants'] if t['name']=='tenant2'))")
echo "    tenant1: $TENANT1_ID"
echo "    tenant2: $TENANT2_ID"

echo ""
echo "=== Reading tenant1 config ==="
echo "    (US store — USD, 8% tax, 100 free-tier orders)"
curl -s "http://${SERVER}/v1/tenants/${TENANT1_ID}/config" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin" | \
  python3 -m json.tool

echo ""
echo "=== Reading tenant2 config ==="
echo "    (EU store — EUR, 20% tax, 50 free-tier orders)"
curl -s "http://${SERVER}/v1/tenants/${TENANT2_ID}/config" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin" | \
  python3 -m json.tool

echo ""
echo "=== Demonstrating isolation: changing tenant1 does not affect tenant2 ==="
echo "    Setting tenant1 checkout.tax_rate to 0.10 (a runtime override)..."
curl -s -X PUT "http://${SERVER}/v1/tenants/${TENANT1_ID}/config/fields/checkout.tax_rate" \
  -H "Content-Type: application/json" \
  -H "x-subject: ${SUBJECT}" -H "x-role: superadmin" \
  -d '{"value": {"numberValue": 0.10}, "description": "Runtime override demo"}' | python3 -m json.tool

echo ""
echo "    tenant1 checkout.tax_rate after update:"
curl -s "http://${SERVER}/v1/tenants/${TENANT1_ID}/config/fields/checkout.tax_rate" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin" | \
  python3 -m json.tool

echo ""
echo "    tenant2 checkout.tax_rate (unchanged — still 0.20):"
curl -s "http://${SERVER}/v1/tenants/${TENANT2_ID}/config/fields/checkout.tax_rate" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin" | \
  python3 -m json.tool

echo ""
echo "=== Done ==="
echo "    Admin panel (all tenants): http://localhost:3000"
echo "    REST API:                  http://localhost:8080"
echo ""
echo "    Try it:"
echo "      curl http://localhost:8080/v1/tenants/${TENANT1_ID}/config -H 'x-subject: ${SUBJECT}' -H 'x-role: superadmin'"
echo "      curl http://localhost:8080/v1/tenants/${TENANT2_ID}/config -H 'x-subject: ${SUBJECT}' -H 'x-role: superadmin'"
echo ""
echo "    Run 'docker compose down -v' to tear down and remove all data."
