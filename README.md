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

## CRM base layout

The base `NYC Real Estate CRM` is plain NocoDB metadata — no custom code.

| Table | Rows | Purpose |
| --- | --- | --- |
| `Properties` | 8 | One row per tax lot; every source property field, plus lender link |
| `Lenders` | 6 | Lender id, name and lending stats |
| `Contacts` | 17 | Owners / officers / managers with phone, email, role, call status |
| `Property Contacts` | 17 | Junction: property ↔ contact, preserving the source Contact1/2/3 slot and role |
| `Calls` | 0 | One row per call: date, outcome, notes, follow-up date |

`Properties.Lender` is a belongs-to link; `Property Contacts` carries the
many-to-many relation used by the `Owners & Contacts` lookup fields on
Properties (`Owner / Contact`, `Phone`, `Contact Status`, `Lender Name`), plus
`Last Call` / `Next Follow-Up` rollups from `Calls`.

### Views

- Properties → **All Properties** (editable grid), **Call List** (address,
  phone, owner, status, next follow-up), **Property Cards** (gallery),
  **Full Record** (every imported column).
- Contacts → **Call Queue** (status not closed), **Call Pipeline** (kanban by
  contact status), **Do Not Call**, **All Contacts**.
- Calls → **Call Log**, **Follow-Ups** (dated follow-ups, ascending).
- Every grid supports NocoDB's native search, filter, sort and inline editing.

### Cold-call loop

1. Open **Properties → Call List** or **Contacts → Call Queue**.
2. Click a record to expand it; the linked owner/contact record is one click
   away.
3. Log the call in **Calls** (or from the property's *Call History* link) with
   outcome, notes and a follow-up date.
4. Move the contact's **Contact Status** in **Call Pipeline**; it leaves the
   Call Queue when it reaches a closed status.
5. **Calls → Follow-Ups** lists every call with a follow-up date, soonest first.
