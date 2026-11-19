# ECMS Technical Requirements

**Product:** Energy Consumption Monitoring System for University of Ibadan staff quarters  
**Revision:** 0.1 — implementation baseline  
**Status:** Draft for MVP build

## 1. Purpose and scope

ECMS will provide residents with their household electricity-use history, estimated cost, bills and alerts. Works administrators will manage the underlying records and operations. Management users will see aggregate area and block summaries only.

The MVP includes authentication, role-aware access, residence and meter records, occupancy history, manual, CSV and device reading paths, a shared validation path, consumption summaries, effective-dated tariffs, periodic bills, operational alerts, report exports and audit history. The prototype will use clearly marked simulated data. Physical metering hardware is a separate pilot readiness gate; SMS, remote load control and solar integration are excluded from this MVP.

## 2. Recommended implementation stack

- **Web:** React + TypeScript + Vite, responsive browser app.
- **UI:** Tailwind CSS, accessible component primitives, Recharts for consumption charts.
- **Data/auth:** Supabase Auth + PostgreSQL + Row Level Security (RLS); Supabase JS client.
- **Privileged operations:** PostgreSQL functions/RPC for bill generation, import validation, correction workflow and audit writes. A narrow ingestion endpoint will accept registered device submissions in the pilot; no service-role key in browser code.
- **Hosting:** Cloudflare Pages for static web delivery; Supabase Free for prototype only.
- **Versioned database:** Supabase CLI migrations committed with the app.

The Vite/React choice keeps the app TypeScript-based and deployable as static files; Supabase handles auth and database services. Cloudflare Pages provides a free static-hosting path. Supabase Free currently includes a 500 MB database, but projects pause after one week of inactivity and do not include automatic backups. That makes it suitable for demonstration and early development, not an unattended operational pilot. Before real bills or household data are used, move to an approved deployment with backups, monitoring, and institutional ownership.

## 3. Roles and authorization

| Role | Permitted access |
|---|---|
| Resident | Read only own active/previous residence data according to occupancy policy: dashboard, readings, bills, alerts; change own password. |
| Administrator | Manage users, residence, occupancy, meters, readings, tariffs, bills, alerts, reports, and audit log. Corrections must create a new version/event. |
| Management | Read aggregate summaries by area, block, and period. No household-level records, user administration, or drill-down. |
| Device | A registered device credential may submit idempotent readings for exactly one meter through a narrow server-side ingestion endpoint. Prototype uses a simulator; pilot hardware is a separate readiness gate. |

Authorization must be enforced in PostgreSQL RLS and privileged RPCs, not only in UI routes. All exposed tables must have explicit grants and RLS policies. Management summary views must be designed to avoid exposing household records and use `security_invoker` where applicable.

## 4. Data model

Core entities: `profiles` (auth user and role), `residences`, `occupancies`, `meters`, `readings`, `reading_revisions`, `tariffs`, `bills`, `bill_lines`, `alerts`, `audit_events`, and `import_batches`.

- IDs are UUIDs. Store all event timestamps in UTC; render in Africa/Lagos local time.
- A meter has one active residence assignment at a time; preserve historical assignments.
- Readings contain meter, observed timestamp, received timestamp, cumulative kWh, source, optional voltage/current/power, idempotency key, status, validation reason, and actor where applicable.
- Imported files retain batch metadata and per-row outcomes; do not retain unnecessary personal data in uploaded files.
- A bill snapshots its billing period, valid interval readings, tariff segments, unrounded amount, rounded amount, currency (`NGN`), and generation time. Re-generation creates a new version and preserves the prior bill.
- Audit events record actor, action, entity, entity ID, timestamp, and request metadata. Avoid storing secrets or full sensitive payloads.

## 5. Reading and consumption rules

1. Manual, CSV, and future device readings enter the same validation rules.
2. Required fields are meter, observed timestamp, cumulative kWh, and source. Reject malformed, inactive-meter, unauthorized, or out-of-range submissions with a row-level reason.
3. Deduplicate by stable reading UUID/idempotency key. CSV imports use a generated batch ID and row key; re-uploading an identical row must not double count.
4. Accept valid delayed readings and order calculations by observed timestamp, not arrival time. For each meter, recompute affected intervals against chronological neighbors. A cumulative decrease relative to the preceding or following accepted reading is flagged for review; do not silently delete or rewrite history.
5. Calculate interval kWh as `current cumulative kWh - previous valid cumulative kWh`. The first reading establishes a baseline and is not billed as an interval. Store enough lineage to reproduce each roll-up.
6. Prototype/default node cadence: one reading every 15 minutes. This is a pilot starting value; Works may change it after baseline and network review.

## 6. Tariffs, bills, and money

- Default billing cadence: calendar month, one bill per residence per month.
- Apply effective-dated tariff rates to consumption intervals by the interval's observed time; do not apply one current rate retroactively across the whole month.
- Default estimated cost: sum of `interval kWh × applicable NGN/kWh rate`, retain precision internally, then round the final bill amount to the nearest whole naira using half-up rounding. Show kWh to 2 decimal places and rate to 2 decimal places.
- Bills are marked **Draft** until an administrator confirms generation; preserve a snapshot and source readings/tariff versions when finalized. Corrections produce a revised bill with an audit trail.
- The Works bill template, tariff schedule, billing-cycle exceptions, and approval role remain inputs required before operational billing. Prototype PDFs/print view are illustrative until Works supplies the format.

## 7. Alerts and reporting defaults

- **High usage:** default trigger if a household's rolling 24-hour use exceeds the greater of 2× its trailing 30-day daily average or 20 kWh. Suppress repeat alerts until the current alert is acknowledged/closed and record the threshold used. Administrators may tune it.
- **No data:** default when no accepted reading arrives for 2× the configured interval, with a minimum grace period of 2 hours. Manual-only meters use an expected-reading schedule configured by Works.
- **Invalid reading:** raise an operational alert when validation rejects or quarantines a reading; include reason and source.
- Alert states: Open, Acknowledged, Closed. Every transition is audited. Defaults are pilot starting values and must be tuned against real baseline data before resident-facing alerting.
- Reports: dashboard view plus CSV exports for readings, bills, alerts and aggregate summaries; printable/PDF monthly bill and aggregate period report. Management exports remain aggregate-only.

## 8. Initial non-functional targets

Targets are for the 20-house software pilot under normal network conditions; measure them before accepting the pilot:

- Dashboard/API reads: p95 under 2 seconds on a typical supported mobile connection.
- Manual/CSV write acknowledgement: p95 under 2 seconds, excluding large-file parsing; 100% of accepted/rejected CSV rows receive an outcome.
- Newly received reading visible to refreshed dashboard within 60 seconds.
- Monthly pilot service availability target: 99% excluding planned maintenance and upstream provider outage. Free-tier service does not provide an SLA, so this is an observed target, not a guarantee.
- Responsive layout from 360 px viewport width; support current Chrome, Safari, Edge and Firefox.
- Keyboard-operable workflows, visible focus, semantic labels, error text tied to fields, and WCAG 2.2 AA contrast for text and controls.
- Pilot retention and recovery objective: daily export/backup before real pilot records, target RPO 24 hours and RTO 8 hours; verify restoration before go-live. Supabase Free does not provide automatic backups.

## 9. Privacy, security, and operations

- Use Supabase Auth password flows; role membership is assigned by an administrator via a protected database function, never self-selected from the browser.
- Enable RLS on every exposed table and explicitly grant only required operations. Protect resident queries using auth identity + active/historical occupancy rules.
- Use publishable/anon keys only in the client. Secret/service-role credentials are server-side only and not required for basic client reads.
- Validate and bound CSV file size, row count, dates, numeric ranges, and formulas; escape spreadsheet formula prefixes on exported CSV values.
- Rate-limit or otherwise protect sign-in and future ingestion endpoints; use HTTPS; log failed imports and privileged actions without secrets.
- Before pilot, configure admin MFA where available, operational account recovery, backup/export procedure, ownership of Supabase/Cloudflare accounts, incident response contact and monitoring.
- Seed data must be visibly labelled **SIMULATED** and must never be mixed with actual bills.

## 10. MVP acceptance gates

1. Resident A cannot read Resident B's readings, alerts, residence, or bill through UI, URL, API, or direct database client.
2. Management can compare areas and periods but cannot access household detail through API or exports.
3. Manual and CSV readings run through shared validation; a mixed CSV reports accepted and rejected rows with reasons and safe retry behavior.
4. Delayed readings are ordered by observation time; duplicate submissions do not double count; corrections preserve prior values and actor/reason.
5. Daily/monthly kWh totals reconcile to stored valid intervals. Bill calculations reproduce tariff segments and rounding rules.
6. High-use, no-data, and invalid-reading alerts can be opened, acknowledged and closed with audit history.
7. Reports export in the approved format; audit log is available only to administrators.
8. Simulated versus live data is unambiguous in every relevant screen/export.
9. Before a real pilot: Works approves tariff schedule/template and baseline/exit thresholds; backup restore is demonstrated; device electrical/connectivity design receives appropriate field review.

## 11. Pilot hardware recommendation

Use an ESP32 as the communications/buffering gateway paired with one appropriately certified single-phase DIN-rail energy meter exposing an isolated RS-485/Modbus or pulse output. Use a certified isolated low-voltage supply, protected enclosure, surge protection, and local non-volatile buffer. Do not add separate SCT-013/ZMPT101B/PZEM sensor sets on top of a meter that already provides the required measurements; that creates duplicate measurement paths and calibration work. Final meter model, electrical installation, enclosure rating, and surge design must be reviewed by qualified electrical personnel and approved for University procurement before installation. Firmware queues readings with a stable event ID and original timestamp, then resends safely when connectivity returns.

## 12. Decisions made for the first build

The user selected a TypeScript stack with Supabase; this draft chooses React/Vite, Supabase Auth/Postgres/RLS, and Cloudflare Pages. English is the only MVP language. Solar and relay control stay out of MVP. Monthly bills, 15-minute readings, delayed/out-of-order reconciliation, dashboard performance targets, and CSV + printable/PDF reports use the defaults above. These defaults can be revised before production configuration; hardware electrical review and institutional billing approval remain explicit release gates.

## 13. Source references

- PRD: `ECMS_Product_Requirements_Document.pdf`, Version 1.0.
- University of Ibadan official logo page: https://ui.edu.ng/content/anthems-and-ui-logo
- University of Ibadan ITeMS policy, logo reproduced in official colors and not modified: https://ui.edu.ng/sites/default/files/ITeMS%20policy%20including%20elearning-%20edited%20ecopy.pdf
- Supabase pricing and Free plan limits: https://supabase.com/pricing
- Supabase Row Level Security guidance: https://supabase.com/docs/guides/database/postgres/row-level-security
- Cloudflare Pages Free plan limits: https://developers.cloudflare.com/pages/platform/limits/
- Vercel Hobby use restriction (reason Vercel is not the default for an institutional deployment): https://vercel.com/docs/plans/hobby
