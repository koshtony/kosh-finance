# Kosh API

A simple multi-tenant finance API built with Django + Django REST Framework.
Data lives in Postgres; there's no custom frontend — the Django admin is the
data-browsing/management UI, and the DRF endpoints are for programmatic
clients (e.g. a mobile app).

**Live deployment:** https://kosh-api-production.up.railway.app/admin/
(Railway project `independent-education`, service `kosh-api`, same project
as the `Postgres` service it connects to via the internal `DATABASE_URL`
reference variable.)

## Multi-tenancy model

- **Tenant** — an organization/workspace. Every finance row belongs to
  exactly one tenant.
- **Membership** — links a Django `User` to a `Tenant` with a role
  (owner/admin/member). A user can belong to multiple tenants.
- Row visibility is enforced in one place (`tenants/scoping.py`) and used by
  both the Django admin (`TenantScopedAdmin`) and the API
  (`TenantScopedViewSetMixin`): a superuser sees everything; everyone else
  only sees rows for tenants they have a Membership in.
- Admins create Tenants and Memberships via `/admin/` — there's no
  self-service tenant signup, to keep this simple.

## Data model

`IncomeSource`, `Business`, `EmploymentIncome`, `EmploymentExpense`,
`BusinessRevenue`, `BusinessExpense`, `DailySale`, `InvestmentEntry`,
`Customer`, `CustomerCheckin`, `RevenueTarget` — all tenant-scoped (directly,
or via `customer__tenant` for checkins).

## API

Auth: `POST /api/auth/token/` with `username`/`password` → `{"token": "..."}`.
Send it as `Authorization: Token <token>` on every other request (DRF's
browsable API also accepts session auth, so you can click around
`/api/tenants/1/businesses/` while logged into `/admin/` in the same browser).

- `GET /api/me/` — current user + tenant memberships
- `GET /api/tenants/` — tenants you belong to (all, for a superuser)
- Everything else is nested under a tenant:
  `/api/tenants/<tenant_id>/income-sources/`,
  `/api/tenants/<tenant_id>/businesses/`,
  `/api/tenants/<tenant_id>/employment-income/`,
  `/api/tenants/<tenant_id>/employment-expenses/`,
  `/api/tenants/<tenant_id>/business-revenue/`,
  `/api/tenants/<tenant_id>/business-expenses/`,
  `/api/tenants/<tenant_id>/daily-sales/`,
  `/api/tenants/<tenant_id>/investments/`,
  `/api/tenants/<tenant_id>/customers/`,
  `/api/tenants/<tenant_id>/customer-checkins/`,
  `/api/tenants/<tenant_id>/revenue-targets/`

  Standard DRF ModelViewSet routes on each (`GET`/`POST` on the list URL,
  `GET`/`PUT`/`PATCH`/`DELETE` on `<id>/`). Requesting a tenant you're not a
  member of returns an empty list rather than leaking a 403 that confirms
  the tenant exists.

## Running locally

Needs network access to Postgres on port 5432 (this repo's sandbox could
not reach it directly — only the live Railway deployment could, over its
internal network).

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
# reads ../.env (repo root) automatically
python manage.py migrate
DJANGO_SUPERUSER_USERNAME=admin DJANGO_SUPERUSER_EMAIL=you@example.com \
  DJANGO_SUPERUSER_PASSWORD=changeme python manage.py ensure_superuser
python manage.py runserver
```

## Deploying changes

```bash
railway up -s <kosh-api-service-id> -e <environment-id> -p <project-id> -c
```

The start command (`Procfile`) runs `migrate`, then `ensure_superuser`
(idempotent — only acts if the env vars are set *and* the user doesn't
already exist), then `collectstatic`, then `gunicorn`.

## Environment variables (set on the Railway service)

- `DATABASE_URL` — `${{Postgres.DATABASE_URL}}` reference (internal network)
- `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=false`
- `DJANGO_ALLOWED_HOSTS`, `DJANGO_CSRF_TRUSTED_ORIGINS` — the service's domain
- `DJANGO_SUPERUSER_USERNAME` / `_EMAIL` / `_PASSWORD` — first-boot admin
  (rotate the password after first login; the command is idempotent, so
  changing these after the user already exists has no further effect — use
  `/admin/` or `changepassword` to rotate it instead)
