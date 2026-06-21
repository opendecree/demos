#!/bin/bash
# Validate the multi-tenant demo: start, verify both tenants, check isolation, tear down.
set -euo pipefail

COMPOSE="docker compose"
SERVER="localhost:8080"
SUBJECT="demo-user"

echo "=== Starting demo ==="
./run.sh

echo ""
echo "=== Looking up tenant IDs ==="
TENANTS=$(curl -sf "http://${SERVER}/v1/tenants" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin")
TENANT1_ID=$(echo "$TENANTS" | python3 -c "import sys,json; print(next(t['id'] for t in json.load(sys.stdin)['tenants'] if t['name']=='tenant1'))")
TENANT2_ID=$(echo "$TENANTS" | python3 -c "import sys,json; print(next(t['id'] for t in json.load(sys.stdin)['tenants'] if t['name']=='tenant2'))")

echo ""
echo "=== Verifying tenant1 config ==="
T1=$(curl -sf "http://${SERVER}/v1/tenants/${TENANT1_ID}/config" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin")
echo "tenant1 snapshot: $T1"
echo "$T1" | grep -q "checkout.currency" || { echo "FAIL: tenant1 missing checkout.currency"; exit 1; }
echo "$T1" | grep -q "USD" || { echo "FAIL: tenant1 currency should be USD"; exit 1; }

echo ""
echo "=== Verifying tenant2 config ==="
T2=$(curl -sf "http://${SERVER}/v1/tenants/${TENANT2_ID}/config" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin")
echo "tenant2 snapshot: $T2"
echo "$T2" | grep -q "checkout.currency" || { echo "FAIL: tenant2 missing checkout.currency"; exit 1; }
echo "$T2" | grep -q "EUR" || { echo "FAIL: tenant2 currency should be EUR"; exit 1; }

echo ""
echo "=== Verifying tenant isolation (different tax rates) ==="
T1_TAX=$(curl -sf "http://${SERVER}/v1/tenants/${TENANT1_ID}/config/fields/checkout.tax_rate" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin")
T2_TAX=$(curl -sf "http://${SERVER}/v1/tenants/${TENANT2_ID}/config/fields/checkout.tax_rate" -H "x-subject: ${SUBJECT}" -H "x-role: superadmin")
echo "tenant1 tax_rate: $T1_TAX"
echo "tenant2 tax_rate: $T2_TAX"
# tenant1 was updated to 0.10 by run.sh; tenant2 must still be 0.20
echo "$T1_TAX" | grep -q "0.1" || { echo "FAIL: tenant1 tax_rate should be 0.1 after override"; exit 1; }
echo "$T2_TAX" | grep -q "0.2" || { echo "FAIL: tenant2 tax_rate should be 0.2 (unchanged)"; exit 1; }

echo ""
echo "=== Verifying idempotency ==="
$COMPOSE run --rm seed-schema
$COMPOSE run --rm seed-tenant1
$COMPOSE run --rm seed-tenant2
echo "Re-seed completed without error."

echo ""
echo "=== All checks passed ==="

echo "=== Tearing down ==="
$COMPOSE down -v
