# NocoDB — NYC Real Estate CRM

Self-hosted NocoDB on the Coolify VPS, backed by PostgreSQL with durable named
volumes. No Redis: a single small instance runs NocoDB's in-process cache, which
keeps the stack to two containers. Deployed from this repo by Coolify (`dockercompose` build pack, service
`nocodb`, domain `https://nocodb.382972.xyz`).

## What runs

| Service | Image | Purpose |
| --- | --- | --- |
| `nocodb` | `nocodb/nocodb:2026.10.1` | NocoDB application (port 8080) |
| `db` | `postgres:17-alpine` | NocoDB metadata + base data |

Both keep their state on named Docker volumes (`nocodb_data`, `pgdata`), so
redeploys and container restarts do not touch the data.

## Required environment variables

Set these on the Coolify application. The compose file only references them.

- `NOCODB_DB_PASSWORD` — PostgreSQL password for the `nocodb` role
- `NOCODB_JWT_SECRET` — JWT signing secret (32+ random bytes)
- `NOCODB_ADMIN_EMAIL` — bootstrap super-admin email
- `NOCODB_ADMIN_PASSWORD` — bootstrap super-admin password

`NC_ADMIN_EMAIL` / `NC_ADMIN_PASSWORD` create the super-admin on first boot, so
there is no unauthenticated "first visitor becomes admin" window.

## Post-deploy hardening

1. Sign in at `https://nocodb.382972.xyz` with the bootstrap admin.
2. Account settings → disable public sign-up (invite-only).
3. Keep the base private (no public shared views).

## Verify

```sh
bash scripts/verify.sh
```
