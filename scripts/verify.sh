#!/usr/bin/env bash
# Deployment-stack gate: the repo must describe the stack without leaking secrets.
set -euo pipefail

cd "$(dirname "$0")/.."

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok: $*"; }

[[ -f docker-compose.yaml ]] || fail "docker-compose.yaml is missing"
[[ -f README.md ]] || fail "README.md is missing"

grep -q 'nocodb/nocodb:2026\.10\.1' docker-compose.yaml \
  || fail "NocoDB image is not pinned to the reviewed stable tag"
! grep -q 'nocodb/nocodb:latest' docker-compose.yaml \
  || fail "NocoDB image uses the floating :latest tag"
ok "NocoDB image pinned"

for var in NOCODB_DB_PASSWORD NOCODB_JWT_SECRET NOCODB_ADMIN_EMAIL NOCODB_ADMIN_PASSWORD; do
  grep -q "\${${var}}" docker-compose.yaml \
    || fail "compose does not reference \${${var}}"
done
ok "all secrets are injected via environment"

# No literal assignments of a secret-looking value in the compose file:
# every one of these keys must interpolate a \${VAR}.
if grep -E '^[[:space:]]*(POSTGRES_PASSWORD|NC_AUTH_JWT_SECRET|NC_ADMIN_PASSWORD):' docker-compose.yaml \
     | grep -qv '\${'; then
  fail "a secret is hard-coded in docker-compose.yaml"
fi
ok "no hard-coded secrets"

for svc in nocodb:8080 db:5432; do
  name=${svc%%:*}
  grep -q "^  ${name}:" docker-compose.yaml || fail "service ${name} is missing"
done
ok "services present"

grep -q 'nocodb_data:' docker-compose.yaml || fail "nocodb_data volume missing"
grep -q 'pgdata:' docker-compose.yaml || fail "pgdata volume missing"
grep -q 'postgres:17-alpine' docker-compose.yaml || fail "PostgreSQL image missing"
ok "persistent volumes declared"

grep -q 'healthcheck:' docker-compose.yaml || fail "no healthcheck declared"
ok "healthchecks declared"

grep -q 'https://nocodb.382972.xyz' docker-compose.yaml || fail "public URL not set"
ok "public URL configured"

echo "verify: PASS"
