# Order History — PRD

## Changelog

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-01-12 | v1 | PM | Initial draft. |
| 2026-01-19 | v2 | PM | Added cancellation flow, background-refetch failure handling, and the cancellation motive vocabulary rows. |

---

## Context

### What

Users can review every order they have placed, see its current fulfillment status, and cancel an order that has not yet shipped. Support currently answers order-status questions by hand because the storefront exposes no order history, which makes it the single largest driver of contact volume.

---

### User Story

As a returning shopper, I want to see my past orders and cancel one that has not shipped yet so that I do not have to contact support for routine status questions.

---

## Behavioral Contract

> **Notation**: This section uses semantic concept names for data attributes. Each semantic name that maps to an API field is linked via a `[V#]` marker on first use, pointing to a row in the Semantic Vocabulary table below. Every bound the requirements depend on is cited by its Product Constant ID.

### Shared Requirements

This feature inherits all shared requirements from `docs/shared-requirements.md`:
- SR-01 — authenticated-route guard
- SR-04 — global request failure handling

**Feature-specific overrides:**
- SR-04: N/A — no override needed; the standard failure handling covers every state in this feature.

---

### Functional Requirements

- **FR-001**: System MUST list every order belonging to the signed-in shopper, newest first by order placement time [V2].
- **FR-002**: System MUST show each order's order reference number [V1], order total [V3] in the order's billing currency [V4], and fulfillment status [V5].
- **FR-003**: System MUST show the ordered items [V6] for an order when the shopper expands that order's row.
- **FR-004**: System MUST offer a cancel affordance only for orders whose fulfillment status is not-yet-shipped; for every other fulfillment status the affordance is absent.
- **FR-005**: System MUST require the shopper to pick a cancellation motive [V7] before the cancellation can be submitted.
- **FR-006**: System MUST show the cancellation time [V8] on an order once the cancellation is confirmed by the backend.
- **FR-007**: System MUST keep the previously loaded order list on screen when a background refresh fails, rather than replacing it with an error state.
- **FR-008**: System MUST show an empty state, distinct from the error state, when the shopper has never placed an order.
- **FR-009**: System MUST abandon an order list request that has not responded within the order list request deadline (PC-001) and surface the retry-able error state.
- **FR-010**: System MUST treat a loaded order list as current for the order list freshness window (PC-002) before refreshing it in the background.

#### Key Entities

- **Order**: A single purchase made by the shopper. Identified to the shopper by a human-readable order reference number, and carries a placement time, a monetary total with its billing currency, a fulfillment status, and one or more ordered items. See the Semantic Vocabulary table for the concept definitions.
- **Ordered Item**: One product line inside an order — product name, quantity, and per-unit price. Always at least one per order.
- **Cancellation**: A shopper-initiated request to stop an order that has not yet shipped. Carries a motive chosen from a fixed list and, once accepted, a cancellation time.

---

### Product Constants

| ID | Constant | Value | What it bounds | Referenced by |
|----|----------|-------|----------------|---------------|
| PC-001 | order list request deadline | 30 seconds | How long the page waits for the order list before giving up and showing the retry-able error state. | FR-009, AC-017 |
| PC-002 | order list freshness window | 60 seconds | How long a loaded order list is treated as current before a background refresh is started. | FR-010, AC-018 |
| PC-003 | order list refresh attempts | 2 retries | How many times a failed order list request is retried in the background before the failure is reported. | AC-019 |
| PC-004 | duplicate cancellation window | 400 milliseconds | How long after a cancellation submit a second submit on the same order is ignored as a duplicate. | AC-020 |
| PC-005 | unpaginated order ceiling | 200 orders | The list size this release renders without pagination; beyond it the shopper sees the oldest orders truncated with a notice. | AC-021 |

---

### Semantic Vocabulary

| V# | Semantic Name | Type | Required | Notes |
|----|---------------|------|----------|-------|
| V1 | order reference number | string | yes | Human-readable, shown to the shopper. |
| V2 | order placement time | timestamp | no | Absent for orders migrated from the legacy platform. |
| V3 | order total | decimal amount | yes | Compared and summed in integer minor units, never as a float. |
| V4 | billing currency | currency code | no | Absent on legacy orders. |
| V5 | fulfillment status | enumeration | yes | The storefront branches on not-yet-shipped vs everything else; unrecognised members render neutrally. |
| V6 | ordered items | list | yes | Each element carries product name, quantity, and unit price. |
| V7 | cancellation motive | enumeration | yes | Fixed list; the shopper picks one before submitting. |
| V8 | cancellation time | timestamp | yes | Server-assigned on acceptance. |

---

### Display Rules

| ID | Rendered Value | Presentation Determinant | Worked Example |
|----|----------------|--------------------------|----------------|
| DR-001 | order placement date | Rendered in the shopper's device timezone, date only, no clock time. | Placed at 2026-01-12T23:40Z, shopper in UTC-5 → "Jan 12, 2026". |
| DR-002 | order total | Rendered in the order's billing currency with that currency's minor-unit precision and its symbol, not its code; a missing currency renders the amount alone. | Total 1234 minor units, currency EUR → "€12.34"; currency absent → "12.34". |
| DR-003 | order list order | Sorted by order placement time, most recent first; orders with no placement time sort last, in order reference order. | Orders placed Jan 12, Jan 3, and one undated → Jan 12, Jan 3, undated. |
| DR-004 | cancellation time | Rendered in the shopper's device timezone with date and clock time. | Cancelled at 2026-01-13T09:05Z, shopper in UTC+1 → "Jan 13, 2026, 10:05". |
| DR-005 | product name in an ordered item | Truncated with an ellipsis at the end of the second line; the full name stays available on hover and to assistive technology. | A 140-character name → two lines ending "…". |

---

### Acceptance Criteria

#### Order List

- [ ] **AC-001**: Opening the order history page shows every order for the signed-in shopper, ordered from most recently placed to least recently placed.
- [ ] **AC-002**: Each order row shows the order reference number, the order total formatted for the order's billing currency, and the fulfillment status.
- [ ] **AC-003**: Expanding an order row reveals each ordered item with its product name, quantity, and per-unit price.
- [ ] **AC-004**: Opening the order history page fires AE-001 with the order-count property.

#### Cancellation

- [ ] **AC-005**: An order whose fulfillment status is not-yet-shipped shows a cancel affordance; an order in any other fulfillment status shows none.
- [ ] **AC-006**: Submitting a cancellation is blocked until a cancellation motive is selected.
- [ ] **AC-007**: After the backend confirms a cancellation, the order shows the cancelled fulfillment status and its cancellation time.
- [ ] **AC-008**: Confirming a cancellation fires AE-002 with the motive property.

#### Loading States

- [ ] **AC-009**: With no cached orders, the order history page shows a placeholder list until the orders arrive.
- [ ] **AC-010**: While a background refresh is in flight and cached orders are on screen, the cached orders stay visible unchanged — no placeholder and no overlay indicator.
- [ ] **AC-011**: When a background refresh fails while cached orders are on screen, the cached orders stay visible, no error state is shown, and AE-OH-003 fires with the failure-reason property.
- [ ] **AC-012**: While a cancellation is being submitted, the confirm affordance is disabled and shows an in-progress indicator.

#### Error States

- [ ] **AC-013**: When the initial order list request fails, the page shows a retry-able error state that explains the orders could not be loaded.
- [ ] **AC-014**: When the shopper's session has expired, the page hands off to the sign-in flow instead of showing the error state.
- [ ] **AC-015**: When a cancellation is rejected because the order has already shipped, the page explains the order can no longer be cancelled and refreshes the order's fulfillment status.

#### Empty States

- [ ] **AC-016**: A shopper who has never placed an order sees an empty state explaining no orders exist yet, with a route into the catalog.

#### Bounds

- [ ] **AC-017**: An order list request that has not responded within the order list request deadline (PC-001) is abandoned and the retry-able error state appears.
- [ ] **AC-018**: Returning to the order history page within the order list freshness window (PC-002) shows the loaded list with no background refresh; returning after it starts one.
- [ ] **AC-019**: A failing background refresh is retried up to the order list refresh attempts (PC-003) before AE-OH-003 fires.
- [ ] **AC-020**: A second cancellation submit on the same order within the duplicate cancellation window (PC-004) is ignored, and AE-002 fires exactly once.
- [ ] **AC-021**: A shopper with more orders than the unpaginated order ceiling (PC-005) sees the most recent orders up to the ceiling plus a notice that older orders are not shown.

---

#### Analytics Events

| # | Event Name | Trigger | Properties | Description |
|---|---|---|---|---|
| AE-001 | `order_history_viewed` | Order history page becomes visible | `order_count` (integer) | Page view event. |
| AE-002 | `order_cancellation_confirmed` | Backend confirms a cancellation | `motive` (enum) | Successful cancellation. |
| AE-OH-003 | `order_history_refetch_failed` | Background refresh fails with cached data on screen | `failure_reason` (enum) | Silent background failure — the sole signal of this state. |

---

### Edge Cases

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| 1 | The shopper has exactly one order | The list renders that single order; no pagination affordance appears. |
| 2 | An order's billing currency is absent | The order total is shown without a currency symbol (DR-002) and the order is flagged in the silent-failure event rather than hidden. |
| 3 | An order's placement time is absent | The order sorts to the end of the list (DR-003) and shows a dash where the placement date would appear. |
| 4 | An order carries zero ordered items | The row still renders and expanding it shows an explanation that the item detail is unavailable. |
| 5 | Two browser tabs cancel the same order at once | The second cancellation is rejected as already-cancelled and that tab refreshes to the cancelled fulfillment status. |
| 6 | The order list request exceeds the order list request deadline (PC-001) | The page shows the retry-able error state; a retry starts a fresh request. |
| 7 | The shopper's session expires mid-cancellation | The cancellation is abandoned and the page hands off to the sign-in flow. |
| 8 | The order list request is rate-limited | The page shows the retry-able error state and does not auto-retry. |
| 9 | An order's fulfillment status is a value the storefront does not recognise | The row renders with a neutral status label and the cancel affordance is absent. |
| 10 | The shopper rapidly double-submits a cancellation | Only one cancellation request is sent; the duplicate submit is ignored within the duplicate cancellation window (PC-004). |
| 11 | The shopper has more orders than the unpaginated order ceiling (PC-005) | The most recent orders up to the ceiling render, followed by a notice that older orders are not shown in this release. |

---

### Feature Flags / Remote Config

| Field | Value |
|-------|-------|
| **Flag name** | `order-history-page` |
| **Fallback** | With the flag off, the order history route is not registered and the account menu shows no order history entry. |

---

## Technical Contract

> Slim mode: the PRD-owned technical tables are omitted. Data sources, query and cache configuration, error-code mappings, route constants, component paths and configuration attributes live in the team's technical design. What remains here is the section packs that insert into this area and the dependencies that gate delivery.

### Dependencies

| Dependency | Source | Status |
|-----------|--------|--------|
| Cancellation endpoint on the orders service | Orders platform team | Merged |
| Session bearer token in the storefront request layer | Storefront web | Merged |

---

## Boundaries

### Out of Scope

- **OS-001**: **Returns and refunds** — a separate initiative owns the returns flow; this PRD covers cancellation of unshipped orders only.
- **OS-002**: **Order editing** — changing address, quantity, or payment method after placement is not supported.
- **OS-003**: **Guest order lookup** — only signed-in shoppers see order history in this release.

---

### Assumptions

| ID | Assumption | Source | Impact if Wrong |
|----|-----------|--------|-----------------|
| ASM-001 | The orders service returns monetary totals as decimal strings, never floats. | API reference | Totals compared as floats would drift and mis-render. |
| ASM-002 | Almost every shopper stays under the unpaginated order ceiling. | Analytics query on order counts | The truncation notice would become the common case rather than the exception. |
| ASM-003 | The cancellation endpoint is idempotent for an already-cancelled order. | Verbal confirmation from the orders platform team | A double submit could produce two cancellation records. |

---

### Open Questions

None — all questions resolved.
