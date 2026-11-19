# ECMS MVP Implementation Plan

**Basis:** Product Requirements Document Version 1.0 plus user clarifications  
**Status:** Proposed delivery plan and first-build defaults

## Product decisions for this plan

- TypeScript web app: React + Vite; Supabase Auth/Postgres/RLS; Cloudflare Pages for static hosting.
- UI language English; University of Ibadan Indigo-Blue and Gold brand direction.
- MVP excludes relay control and solar integration.
- Prototype data is simulated and visibly labelled.
- Initial billing default is calendar-monthly, with tariff changes prorated across reading intervals and final bill rounded half-up to whole NGN.
- A device-ingestion path is included; prototype readings are simulated at 15-minute intervals. Delayed readings are processed by observed time, duplicate submissions are idempotent, and questionable cumulative resets are held for review.
- Reports include CSV for data and printable/PDF bills and aggregate reports.
- Free tiers are for prototype evaluation. Real pilot deployment requires an institutional service owner, backup/restore plan, monitoring, and a decision on paid/managed hosting because free plans can pause and lack automatic backup/SLA assurances.

## Work sequence

| Stage | Work | Exit evidence |
|---|---|---|
| 0. Foundation | Confirm data ownership, set up TypeScript app, Supabase schema/migrations, demo seed, design tokens, CI/deployment preview. | A working demo environment; secrets separated; test/demo data marked. |
| 1. Access and records | Sign-in, role routing, profile, residences, occupancy history, meters, server/database access rules. | Resident/Administrator/Management access matrix enforced at database layer; no household access by Management. |
| 2. Readings | Manual entry, CSV preview/import, validation queue, idempotency, correction history, chronological recomputation. | Mixed-validity import yields row outcomes; totals reconcile; delayed/duplicate cases handled. |
| 3. Resident and admin views | Responsive dashboards, charts, latest readings, cost estimates, alerts and data freshness. | Phone-sized task walkthroughs; totals match accepted interval records; simulated banner visible. |
| 4. Tariffs and bills | Effective-dated tariffs, monthly bill preview/finalization, history/revisions, print/PDF layout. | Bill line items reconcile to tariff windows and accepted reading intervals; Works format mapped before operational billing. |
| 5. Management, exports, audit | Aggregate-only area reports, CSV exports, printable reports, append-only audit timeline. | Household detail absent from management APIs/exports; sensitive actions auditable. |
| 6. Pilot readiness | Performance/accessibility review, backup and restore demonstration, data migration/import rehearsal, operational runbook, field hardware review if nodes are included. | Works/product owner signs readiness and success thresholds; backup restore and role review pass; 20-house go/no-go. |

## Suggested delivery cadence

1. **Week 1:** Foundation and access/data model.
2. **Week 2:** Readings, CSV flow and validation.
3. **Week 3:** Dashboards and alerts.
4. **Week 4:** Tariffs, bill workflow, reports and audit.
5. **Week 5:** Pilot hardening, import rehearsal, usability/accessibility and operational readiness.

This is a five-week working estimate for a small focused team after access to the Supabase project and sample Works data; hardware procurement, institutional approval, email configuration and integration delays can extend it.

## Defaults to tune with pilot data

- Performance: p95 screen/API reads under 2 seconds; new readings visible within 60 seconds.
- High-use alert: rolling 24-hour consumption over the greater of 2× trailing household daily average or 20 kWh.
- No-data alert: no accepted reading for 2× expected interval, with 2-hour minimum grace.
- Pilot backup objective: RPO 24 hours, RTO 8 hours, with daily export/backup and demonstrated restore.
- Bill rounding: nearest whole NGN using half-up rounding; retain unrounded totals and tariff/rate precision for reconciliation.

Thresholds and service targets must be calibrated against baseline data. Alert thresholds should be configured and reviewed before residents receive notifications.

## Risks and dependencies

- **Free tier is not operational resilience:** Supabase Free currently pauses inactive projects and excludes automatic backups; treat it as a development/demo environment. Before live household or billing data, secure a supported environment, access ownership, backups, monitoring and recovery responsibility.
- **University logo:** use the official source asset unchanged. Public UI guidance identifies Indigo-Blue and Gold as University colours; exact digital color values are approximations until an authorized brand file/guide is supplied.
- **Works inputs:** tariff schedule, approved bill template, billing exceptions, export needs, and approval owner must be supplied before final bills.
- **Meter hardware:** pilot recommendation is ESP32 gateway + one appropriately certified single-phase DIN-rail meter with isolated RS-485/Modbus or pulse output, protected enclosure, isolated supply, surge protection and local buffering. Avoid layering separate sensor sets onto a meter that already measures the required values. Have the final model, enclosure and installation reviewed by qualified electrical personnel before deployment.
- **Data privacy:** define retention and resident move-out access policy before importing real household data.

## Immediate build order

1. Create repo/app shell and design tokens.
2. Add database migrations and secure RLS for profiles/residences/occupancies/meters/readings.
3. Seed a small synthetic neighborhood and implement role-specific dashboards.
4. Implement shared manual/CSV validation and audit/correction workflow.
5. Add tariffs, billing and exports after core consumption logic reconciles.
6. Add realistic latency/error/loading states and deploy preview.
7. Use the readiness checklist before connecting any live readings or bills.
