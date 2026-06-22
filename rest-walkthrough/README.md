# REST Walkthrough

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/opendecree/demos?devcontainer_path=.devcontainer%2Frest-walkthrough%2Fdevcontainer.json)

> Drive the full OpenDecree API with nothing but `curl`. No SDK, no language runtime — just HTTP.

## What you'll learn

- How to create a schema and publish it
- How to create a tenant and set config values
- How to read individual fields and the full config snapshot
- How to watch for real-time changes via server-sent events

## Prerequisites

- Docker and Docker Compose
- `curl` and `jq`

## Start the stack

```bash
docker compose up -d
```

The stack runs the `migrate` service (database migrations) before the server
starts. Once `docker compose up` settles, confirm the server is up:

```bash
curl -s http://localhost:8080/v1/server/info | jq .
```

Expected output includes `"version"` and `"commit"`.

> **Identity headers:** the API authorizes every request by `x-subject` (who is
> acting) and `x-role` (what they may do). This demo's server sets
> `DECREE_GATEWAY_TRUSTED_PROXY=1` so the HTTP gateway accepts these headers
> directly — by default it rejects client-set identity headers to prevent
> impersonation. Creating schemas and tenants requires `x-role: superadmin`,
> which the commands below use throughout.

---

## Step 1 — Create a schema

A schema defines the shape of your configuration: field names, types, and constraints.

```bash
SCHEMA=$(curl -s -X POST http://localhost:8080/v1/schemas \
  -H "Content-Type: application/json" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" \
  -d '{
    "name": "app-config",
    "description": "Runtime configuration for a web application",
    "fields": [
      {
        "path": "app.maintenance_mode",
        "type": "FIELD_TYPE_BOOL",
        "description": "Disable traffic during maintenance windows"
      },
      {
        "path": "app.max_connections",
        "type": "FIELD_TYPE_INT",
        "description": "Maximum concurrent database connections",
        "constraints": { "minimum": 1, "maximum": 1000 }
      },
      {
        "path": "app.rate_limit_rps",
        "type": "FIELD_TYPE_NUMBER",
        "description": "API rate limit (requests per second)",
        "constraints": { "minimum": 0 }
      },
      {
        "path": "app.support_url",
        "type": "FIELD_TYPE_STRING",
        "description": "URL shown to users on error pages"
      }
    ]
  }')

echo "$SCHEMA" | jq .
SCHEMA_ID=$(echo "$SCHEMA" | jq -r '.schema.id')
echo "Schema ID: $SCHEMA_ID"
```

The schema is created as **version 1** in draft state — not yet usable by tenants.

---

## Step 2 — Publish the schema

Publishing locks the version and makes it available for tenant assignment.

```bash
curl -s -X POST "http://localhost:8080/v1/schemas/${SCHEMA_ID}/publish" \
  -H "Content-Type: application/json" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" \
  -d '{"version": 1}' | jq .
```

---

## Step 3 — Create a tenant

A tenant is an isolated config namespace (e.g., a customer, environment, or region).

```bash
TENANT=$(curl -s -X POST http://localhost:8080/v1/tenants \
  -H "Content-Type: application/json" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" \
  -d "{
    \"name\": \"my-app\",
    \"schemaId\": \"${SCHEMA_ID}\",
    \"schemaVersion\": 1
  }")

echo "$TENANT" | jq .
TENANT_ID=$(echo "$TENANT" | jq -r '.tenant.id')
echo "Tenant ID: $TENANT_ID"
```

---

## Step 4 — Set config values

### Set individual fields

```bash
# Enable maintenance mode
curl -s -X PUT \
  "http://localhost:8080/v1/tenants/${TENANT_ID}/config/fields/app.maintenance_mode" \
  -H "Content-Type: application/json" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" \
  -d '{"value": {"boolValue": false}, "description": "initial values"}' | jq .

# Set max connections
curl -s -X PUT \
  "http://localhost:8080/v1/tenants/${TENANT_ID}/config/fields/app.max_connections" \
  -H "Content-Type: application/json" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" \
  -d '{"value": {"integerValue": "100"}}' | jq .
```

### Set multiple fields at once

`batchSet` commits all changes as a single config version:

```bash
curl -s -X POST \
  "http://localhost:8080/v1/tenants/${TENANT_ID}/config:batchSet" \
  -H "Content-Type: application/json" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" \
  -d "{
    \"description\": \"set rate limit and support URL\",
    \"updates\": [
      {
        \"fieldPath\": \"app.rate_limit_rps\",
        \"value\": {\"numberValue\": 500.0}
      },
      {
        \"fieldPath\": \"app.support_url\",
        \"value\": {\"stringValue\": \"https://support.example.com\"}
      }
    ]
  }" | jq .
```

---

## Step 5 — Query config

### Full snapshot

```bash
curl -s \
  "http://localhost:8080/v1/tenants/${TENANT_ID}/config" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" | jq .
```

### Single field

```bash
curl -s \
  "http://localhost:8080/v1/tenants/${TENANT_ID}/config/fields/app.rate_limit_rps" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" | jq .
```

### Multiple fields in one request

```bash
curl -s -X POST \
  "http://localhost:8080/v1/tenants/${TENANT_ID}/config:batchGet" \
  -H "Content-Type: application/json" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" \
  -d '{"fieldPaths": ["app.maintenance_mode", "app.max_connections", "app.rate_limit_rps"]}' | jq .
```

---

## Step 6 — Watch for changes

Open a second terminal and start a live subscription — the server pushes events whenever config changes:

```bash
curl -N \
  "http://localhost:8080/v1/tenants/${TENANT_ID}/config:subscribe" \
  -H "x-subject: walkthrough" -H "x-role: superadmin"
```

Back in the first terminal, flip maintenance mode on:

```bash
curl -s -X PUT \
  "http://localhost:8080/v1/tenants/${TENANT_ID}/config/fields/app.maintenance_mode" \
  -H "Content-Type: application/json" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" \
  -d '{"value": {"boolValue": true}, "description": "maintenance window"}' | jq .
```

The subscription terminal receives a `ConfigChange` event within milliseconds — no polling needed.

Press `Ctrl-C` to end the stream.

---

## Step 7 — Explore the audit log

Every write is recorded. Query the full history for your tenant:

```bash
curl -s \
  "http://localhost:8080/v1/audit/logs?tenantId=${TENANT_ID}" \
  -H "x-subject: walkthrough" -H "x-role: superadmin" | jq '.logs[] | {actor, action, fieldPath, newValue, createdAt}'
```

---

## Clean up

```bash
docker compose down -v
```

---

## Next steps

- [Quickstart demo](../quickstart/) — see the SDK and live dashboard in action
- [OpenDecree docs](https://github.com/opendecree/decree) — full API, CLI, and SDK reference
