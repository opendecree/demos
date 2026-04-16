#!/bin/bash
# Validate the quickstart demo: start, check endpoints, tear down.
set -euo pipefail

echo "=== Starting demo ==="
docker compose up -d --wait --build

echo "=== Waiting for services ==="
for i in $(seq 1 30); do
  curl -sf http://localhost:4000/api/config >/dev/null && break
  sleep 2
done

echo "=== Testing API endpoints ==="
# Payroll amount
AMOUNT=$(curl -sf http://localhost:4000/api/payroll-amount)
echo "Payroll amount: $AMOUNT"
echo "$AMOUNT" | grep -q '"amount"' || { echo "FAIL: payroll-amount"; exit 1; }

# Period duration
PERIOD=$(curl -sf http://localhost:4000/api/period-duration)
echo "Period duration: $PERIOD"
echo "$PERIOD" | grep -q '"days"' || { echo "FAIL: period-duration"; exit 1; }

# Config snapshot
CONFIG=$(curl -sf http://localhost:4000/api/config)
echo "Config: $CONFIG"
echo "$CONFIG" | grep -q '"tax_rate"' || { echo "FAIL: config"; exit 1; }

# Dashboard serves HTML
HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:4000/)
echo "Dashboard HTTP: $HTTP_CODE"
[ "$HTTP_CODE" = "200" ] || { echo "FAIL: dashboard"; exit 1; }

# Admin panel
ADMIN_CODE=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:3000/)
echo "Admin HTTP: $ADMIN_CODE"
[ "$ADMIN_CODE" = "200" ] || { echo "FAIL: admin"; exit 1; }

echo "=== All checks passed ==="

echo "=== Tearing down ==="
docker compose down -v
