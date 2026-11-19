# ECMS Design System

**Revision:** 0.1 — MVP foundation  
**Audience:** Residents, Works administrators, Energy Management  
**Language:** English

## 1. Design intent

Make electricity use and charges understandable at a glance. Use familiar terms, calm visual hierarchy, readable charts, and clear data-quality states. Prioritize small screens and constrained connections. Separate operational status from consumption performance so an alert does not look like a bill.

## 2. Brand foundation

The University of Ibadan identifies its University colours as **Indigo-Blue and Gold**. Use the official logo asset without recolouring, cropping, or redrawing. The public logo page links an asset; the University's ITeMS policy says the logo should appear in official colors and should not be altered. Confirm the current authorized file with the Registrar before formal institutional publication.

Digital token values below are interface approximations for the named official colours, not asserted official HEX values:

| Token | Value | Use |
|---|---|---|
| `brand.indigo.700` | `#253B73` | Primary navigation, primary buttons, headings |
| `brand.indigo.900` | `#17264A` | Deep contrast, sidebar active state |
| `brand.indigo.100` | `#E8EDF6` | Tinted panels and selected states |
| `brand.gold.600` | `#B88919` | Highlights, chart accent; avoid small gold text on white |
| `brand.gold.100` | `#FBF4DE` | Warm callout background |
| `surface.canvas` | `#F6F7F9` | App background |
| `surface.card` | `#FFFFFF` | Cards and tables |
| `text.primary` | `#172033` | Main text |
| `text.secondary` | `#596579` | Secondary labels |
| `border.default` | `#DCE1E8` | Dividers and control boundaries |
| `state.success` | `#18794E` | Valid/closed states |
| `state.warning` | `#9A5B00` | Attention needed |
| `state.danger` | `#B42318` | Rejected/critical states |
| `state.info` | `#175CD3` | Neutral information |

Status colors always pair with text and/or an icon; never rely on color alone. Verify all combinations for WCAG AA contrast before release.

## 3. Typography and layout

- Typeface: **Inter** with system sans-serif fallback. Use locally bundled/system fallback for reliable rendering and low data use.
- Body: 16 px / 1.5 line height. Compact table text may use 14 px, never below 12 px for essential labels.
- Page title: 28–32 px desktop, 24 px mobile. Section title: 20 px. Card title: 16 px semibold.
- Spacing scale: 4, 8, 12, 16, 24, 32, 48 px. Card radius 12 px; controls 8 px; focus ring 2 px.
- Content max width: 1440 px; desktop sidebar 248 px; mobile navigation collapses to a menu with persistent role context.
- Chart minimum height: 220 px desktop / 190 px mobile. Pair charts with summary values and accessible table/data alternative.

## 4. Role-based information architecture

| Role | Primary navigation | Landing view |
|---|---|---|
| Resident | Overview, Usage, Bills, Alerts, Account | Month-to-date kWh and estimated NGN, trend, latest reading, current bill, open alerts |
| Administrator | Overview, Residences, Meters, Readings, Tariffs, Bills, Alerts, Reports, Audit, Users | Active meters, readings needing review, open alerts, recent operations |
| Management | Overview, Areas, Reports | Aggregate consumption/load trend, area comparisons, period controls |

Every screen displays the signed-in user's role and active area/house context. Management has no household drill-down. Residents see a clear SIMULATED banner when viewing prototype data.

## 5. Core components

- **App shell:** responsive header/sidebar, role badge, page title, date/period selector, account menu.
- **Metric card:** label, value, unit, optional period comparison, data freshness label.
- **Consumption chart:** kWh by day/week/month; tooltip includes timestamp and value; keyboard-accessible alternative table.
- **Data freshness chip:** Current, Delayed, No recent data; includes last-reading time.
- **Alert row/card:** severity icon + label, plain-language reason, affected meter/period, status, next action.
- **State badge:** Draft, Final, Open, Acknowledged, Closed, Valid, Needs review, Rejected, Simulated.
- **Reading table:** timestamp, kWh, delta, source, validation status, actor; row detail exposes validation reason/history.
- **Import flow:** select CSV, map/preview fields, validation summary, downloadable rejected-row file, confirm import.
- **Tariff editor:** rate, effective-from date, prior-period preview and confirmation.
- **Bill summary:** billing period, kWh, tariff breakdown, estimated/approved amount, generation state and print action.
- **Audit timeline:** actor/action/entity/time/reason in append-only chronological order.
- **Empty/error/loading states:** explain what happened and offer one safe next action; preserve entered form data on recoverable failures.

## 6. Interaction and content rules

- Show `kWh`, `NGN`, and the applicable date range beside numbers. Use “Estimated cost” until a bill is finalized.
- Use dates in `18 Nov 2026` format and show local time only when needed. Store UTC; display Africa/Lagos.
- Explain status plainly: “Reading needs review: cumulative kWh is lower than the previous reading.”
- Use confirmation for tariff changes, bill finalization, disabling accounts/meters, and corrections. Ask for a correction reason.
- Avoid destructive edits for readings and bills. Use correction/revision flows that show previous and new values.
- Toasts confirm completion but do not replace persistent inline error/status messages.

## 7. Accessibility and responsive behavior

- Support keyboard-only navigation, logical focus order, visible focus indicators, semantic headings, form labels, chart summaries, and screen-reader announcements for saved/imported states.
- Ensure text and controls meet WCAG 2.2 AA contrast. Minimum interactive target 44×44 px on touch screens.
- Tables become horizontally scrollable with pinned identifying columns or a stacked card presentation on narrow screens.
- Keep key actions reachable at 360 px width; no interaction requires hover.
- Respect reduced-motion settings; no information is conveyed through animation alone.

## 8. Design review checklist

1. Is consumption in kWh and cost in NGN understandable without training?
2. Can a resident identify their bill, latest reading, and open alert quickly on a phone?
3. Does each role see only relevant navigation and data?
4. Are simulated values distinguished from operational records?
5. Can each color-coded state also be understood by text, shape, or icon?
6. Does every sensitive change show its effect and preserve a history?

## 9. Brand references

- Official UI logo page: https://ui.edu.ng/content/anthems-and-ui-logo
- Official ITeMS policy on logo usage: https://ui.edu.ng/sites/default/files/ITeMS%20policy%20including%20elearning-%20edited%20ecopy.pdf
- UI colours source: University of Ibadan web publication describing the University colour scheme as Indigo-Blue and Gold: https://ui.edu.ng/sites/default/files/pages%201%20to%2010_0.pdf
