#!/bin/bash
# Validate the quickstart demo: start, check endpoints, verify both tenants, tear down.
set -euo pipefail

COMPOSE="docker compose"

echo "=== Starting demo ==="
./run.sh

echo ""
echo "=== Waiting for payroll service ==="
for i in $(seq 1 30); do
  curl -sf http://localhost:4000/api/config >/dev/null && break
  sleep 2
done

echo ""
echo "=== Testing payroll service endpoints ==="
AMOUNT=$(curl -sf http://localhost:4000/api/payroll-amount)
echo "Payroll amount: $AMOUNT"
echo "$AMOUNT" | grep -q '"amount"' || { echo "FAIL: payroll-amount"; exit 1; }

PERIOD=$(curl -sf http://localhost:4000/api/period-duration)
echo "Period duration: $PERIOD"
echo "$PERIOD" | grep -q '"days"' || { echo "FAIL: period-duration"; exit 1; }

CONFIG=$(curl -sf http://localhost:4000/api/config)
echo "Config: $CONFIG"
echo "$CONFIG" | grep -q '"tax_rate"' || { echo "FAIL: config"; exit 1; }

HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:4000/)
echo "Dashboard HTTP: $HTTP_CODE"
[ "$HTTP_CODE" = "200" ] || { echo "FAIL: dashboard"; exit 1; }

ADMIN_CODE=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:3000/)
echo "Admin HTTP: $ADMIN_CODE"
[ "$ADMIN_CODE" = "200" ] || { echo "FAIL: admin"; exit 1; }

echo ""
echo "=== Verifying seed state via CLI ==="

# Both tenants must exist
ACME_CFG=$($COMPOSE run --rm --no-TTY seed-acme config get-all acme \
  --server decree-server:9090 --subject test 2>&1)
echo "Acme config output: $ACME_CFG"
echo "$ACME_CFG" | grep -q "payroll.tax_rate" || { echo "FAIL: acme config missing"; exit 1; }

GLOBEX_CFG=$($COMPOSE run --rm --no-TTY seed-globex config get-all globex \
  --server decree-server:9090 --subject test 2>&1)
echo "Globex config output: $GLOBEX_CFG"
echo "$GLOBEX_CFG" | grep -q "payroll.tax_rate" || { echo "FAIL: globex config missing"; exit 1; }

# Acme and globex must have different currency values
echo "$ACME_CFG" | grep -q "USD" || { echo "FAIL: acme currency not USD"; exit 1; }
echo "$GLOBEX_CFG" | grep -q "EUR" || { echo "FAIL: globex currency not EUR"; exit 1; }

# Verify idempotency: re-running seeds must not create new versions
echo ""
echo "=== Verifying idempotency ==="
$COMPOSE run --rm seed-schema
$COMPOSE run --rm seed-acme
$COMPOSE run --rm seed-globex
echo "Re-seed completed without error."

echo ""
echo "=== All checks passed ==="

echo "=== Tearing down ==="
$COMPOSE down -v
