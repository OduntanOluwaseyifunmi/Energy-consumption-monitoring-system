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

## Database

Supabase schema and security policies are in `supabase/migrations`. Apply migrations with the Supabase CLI after the project is configured; review RLS policies before connecting real data.
