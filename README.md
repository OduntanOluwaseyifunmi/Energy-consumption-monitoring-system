# Energy-consumption-monitoring-system
# ECMS

Energy Consumption Monitoring System for University of Ibadan staff quarters.

## MVP starting point

This repository starts with the responsive resident dashboard prototype and role preview. Dashboard values are simulated. Other navigation areas are placeholders until their MVP workflows are implemented. No live household data is connected.

## Stack

- React + TypeScript + Vite
- Supabase Auth + PostgreSQL + Row Level Security
- Cloudflare Pages deployment target

## Run locally

1. Install Node.js 20.19+ or 22.12+ and npm.
2. Run `npm install`.
3. Copy `.env.example` to `.env.local` and fill in the Supabase project URL and publishable key when a project is available.
4. Run `npm run dev`.

Without Supabase credentials the prototype still uses local simulated dashboard data. Never put a Supabase secret/service-role key in a `VITE_` variable.

## Documents

- `docs/ECMS_Technical_Requirements.md`
- `docs/ECMS_Design_System.md`
- `docs/ECMS_MVP_Implementation_Plan.md`

## Database foundation (Supabase)

The initial migration in `supabase/migrations` creates profiles, residences, occupancy history, administrator-to-residence assignments, meters, meter assignment history, and meter readings. It enables Row Level Security (RLS): residents are scoped to their own occupancy periods, administrators to assigned residences, and management has no direct access to household tables. Management summaries are exposed only through the aggregate `management_daily_usage` RPC. Client applications cannot write readings directly; add a validated ingestion workflow before accepting readings.

New Auth accounts receive a resident profile. Role changes and administrator-to-residence assignments must be made by a trusted project operator; users cannot grant themselves administrator or management access. Do not place service-role credentials in the app or repository.

### Run migrations locally

1. Install Docker Desktop and the Supabase CLI, then start Docker.
2. If this checkout does not yet have `supabase/config.toml`, initialize the CLI configuration from the repository root:

   ```sh
   npx supabase init
   ```

   Keep the existing migration file under `supabase/migrations`.
3. Start the local Supabase stack and apply migrations:

   ```sh
   npx supabase start
   npx supabase db reset
   ```

`db reset` applies the committed migrations to the local database. This repository does not include demo records or connect to a hosted project. Stop the local stack with `npx supabase stop` when finished.

### Apply to a hosted development project

Only after choosing a Supabase development project, authenticate and link it from the repository root:

```sh
npx supabase login
npx supabase link --project-ref <project-ref>
npx supabase db push --remote
```

Review the target project before pushing. The migration creates schema and access rules only; it does not add household data. A first administrator and administrator-to-residence assignments must be provisioned securely by a trusted project operator before role-specific administrator actions are available.
