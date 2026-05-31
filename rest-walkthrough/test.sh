#!/bin/bash
# CI validation for the rest-walkthrough demo.
# Starts the stack, exercises each API operation, tears down.
set -euo pipefail

BASE="http://localhost:8080"
SUBJECT="test-runner"

fail() { echo "FAIL: $1"; docker compose down -v; exit 1; }
check() { echo "$1" | grep -q "$2" || fail "$3"; }

echo "=== Starting stack ==="
docker compose up -d

echo "=== Waiting for server ==="
for i in $(seq 1 30); do
  curl -sf "${BASE}/v1/server/info" -H "x-subject: ${SUBJECT}" >/dev/null && break
  [ "$i" = "30" ] && fail "server never became ready"
  sleep 2
done

echo "=== Create schema ==="
SCHEMA=$(curl -sf -X POST "${BASE}/v1/schemas" \
  -H "Content-Type: application/json" \
  -H "x-subject: ${SUBJECT}" \
  -d '{
    "name": "app-config",
    "description": "CI test schema",
    "fields": [
      {"path": "app.maintenance_mode", "type": "FIELD_TYPE_BOOL"},
      {"path": "app.max_connections",  "type": "FIELD_TYPE_INT"},
      {"path": "app.rate_limit_rps",   "type": "FIELD_TYPE_NUMBER"},
      {"path": "app.support_url",      "type": "FIELD_TYPE_STRING"}
    ]
  }')
SCHEMA_ID=$(echo "$SCHEMA" | python3 -c "import sys,json; print(json.load(sys.stdin)['schema']['id'])")
echo "Schema ID: $SCHEMA_ID"

echo "=== Publish schema ==="
curl -sf -X POST "${BASE}/v1/schemas/${SCHEMA_ID}/publish" \
  -H "Content-Type: application/json" \
  -H "x-subject: ${SUBJECT}" \
  -d '{"description": "CI publish"}' >/dev/null

echo "=== Create tenant ==="
TENANT=$(curl -sf -X POST "${BASE}/v1/tenants" \
  -H "Content-Type: application/json" \
  -H "x-subject: ${SUBJECT}" \
  -d "{\"name\": \"ci-tenant\", \"schemaId\": \"${SCHEMA_ID}\", \"schemaVersion\": 1}")
TENANT_ID=$(echo "$TENANT" | python3 -c "import sys,json; print(json.load(sys.stdin)['tenant']['id'])")
echo "Tenant ID: $TENANT_ID"

echo "=== Set individual fields ==="
curl -sf -X PUT "${BASE}/v1/tenants/${TENANT_ID}/config/fields/app.maintenance_mode" \
  -H "Content-Type: application/json" \
  -H "x-subject: ${SUBJECT}" \
  -d '{"value": {"boolValue": false}, "description": "ci init"}' >/dev/null

curl -sf -X PUT "${BASE}/v1/tenants/${TENANT_ID}/config/fields/app.max_connections" \
  -H "Content-Type: application/json" \
  -H "x-subject: ${SUBJECT}" \
  -d '{"value": {"integerValue": "100"}}' >/dev/null

echo "=== Batch set ==="
curl -sf -X POST "${BASE}/v1/tenants/${TENANT_ID}/config:batchSet" \
  -H "Content-Type: application/json" \
  -H "x-subject: ${SUBJECT}" \
  -d "{
    \"description\": \"ci batch\",
    \"updates\": [
      {\"fieldPath\": \"app.rate_limit_rps\", \"value\": {\"numberValue\": 500.0}},
      {\"fieldPath\": \"app.support_url\",    \"value\": {\"stringValue\": \"https://example.com\"}}
    ]
  }" >/dev/null

echo "=== Get full config ==="
CONFIG=$(curl -sf "${BASE}/v1/tenants/${TENANT_ID}/config" -H "x-subject: ${SUBJECT}")
check "$CONFIG" "app.maintenance_mode" "config missing maintenance_mode"
check "$CONFIG" "app.rate_limit_rps"   "config missing rate_limit_rps"
echo "Full config: OK"

echo "=== Get single field ==="
FIELD=$(curl -sf "${BASE}/v1/tenants/${TENANT_ID}/config/fields/app.max_connections" \
  -H "x-subject: ${SUBJECT}")
check "$FIELD" "max_connections" "single field response missing path"
echo "Single field: OK"

echo "=== Batch get ==="
BATCH=$(curl -sf -X POST "${BASE}/v1/tenants/${TENANT_ID}/config:batchGet" \
  -H "Content-Type: application/json" \
  -H "x-subject: ${SUBJECT}" \
  -d '{"fieldPaths": ["app.maintenance_mode", "app.max_connections"]}')
check "$BATCH" "maintenance_mode" "batch get missing maintenance_mode"
check "$BATCH" "max_connections"  "batch get missing max_connections"
echo "Batch get: OK"

echo "=== Audit log ==="
AUDIT=$(curl -sf "${BASE}/v1/audit/logs?tenantId=${TENANT_ID}" -H "x-subject: ${SUBJECT}")
check "$AUDIT" "app.maintenance_mode" "audit log missing write event"
echo "Audit log: OK"

echo "=== All checks passed ==="

echo "=== Tearing down ==="
docker compose down -v
