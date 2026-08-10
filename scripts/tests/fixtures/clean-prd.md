# Order History — PRD

## Changelog

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-01-12 | v1 | PM | Initial draft. |
| 2026-01-19 | v2 | PM | Added cancellation flow, background-refetch failure handling, and the cancellation reason vocabulary rows. |

---

## Context

### What

Users can review every order they have placed, see its current fulfillment status, and cancel an order that has not yet shipped. Support currently answers order-status questions by hand because the storefront exposes no order history, which makes it the single largest driver of contact volume.

---

### User Story

As a returning shopper, I want to see my past orders and cancel one that has not shipped yet so that I do not have to contact support for routine status questions.

---

## Behavioral Contract

> **Notation**: This section uses semantic concept names for data attributes. Each semantic name that maps to an API field is linked via a `[V#]` marker on first use, pointing to a row in the per-endpoint vocabulary tables in the [Technical Contract](#technical-contract).

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

#### Key Entities

- **Order**: A single purchase made by the shopper. Identified to the shopper by a human-readable order reference number, and carries a placement time, a monetary total with its billing currency, a fulfillment status, and one or more ordered items. See the vocabulary tables for the endpoint field mapping.
- **Ordered Item**: One product line inside an order — product name, quantity, and per-unit price. Always at least one per order.
- **Cancellation**: A shopper-initiated request to stop an order that has not yet shipped. Carries a motive chosen from a fixed list and, once accepted, a cancellation time.

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
| 2 | An order's billing currency is absent | The order total is shown without a currency symbol and the order is flagged in the silent-failure event rather than hidden. |
| 3 | An order's placement time is absent | The order sorts to the end of the list and shows a dash where the placement date would appear. |
| 4 | An order carries zero ordered items | The row still renders and expanding it shows an explanation that the item detail is unavailable. |
| 5 | Two browser tabs cancel the same order at once | The second cancellation is rejected as already-cancelled and that tab refreshes to the cancelled fulfillment status. |
| 6 | The order list request times out after 30 seconds | The page shows the retry-able error state; a retry starts a fresh request. |
| 7 | The shopper's session expires mid-cancellation | The cancellation is abandoned and the page hands off to the sign-in flow. |
| 8 | The order list request is rate-limited | The page shows the retry-able error state and does not auto-retry. |
| 9 | An order's fulfillment status is a value the storefront does not recognise | The row renders with a neutral status label and the cancel affordance is absent. |
| 10 | The shopper rapidly double-submits a cancellation | Only one cancellation request is sent; the duplicate submit is ignored within a 400 ms window and AE-002 fires exactly once. |

---

### Feature Flags / Remote Config

| Field | Value |
|-------|-------|
| **Flag name** | `order-history-page` |
| **Fallback** | With the flag off, the order history route is not registered and the account menu shows no order history entry. |

---

## Technical Contract

> This section maps the behavioral concepts used in the [Behavioral Contract](#behavioral-contract) to their API implementations.

### Data Sources

| ID | Semantic Name | Endpoint | Method | Full URL Pattern | Canonical Ref | Auth |
|---|---|---|---|---|---|---|
| DS-001 | Order list | `GET /v1/orders` | GET | `<ORDERS_API_BASE_URL>/v1/orders` | [orders-service router](https://github.com/example-org/orders-service/blob/9f2c1ab/src/orders/router.py) | Session bearer token |
| DS-002 | Order cancellation | `POST /v1/orders/{id}/cancellation` | POST | `<ORDERS_API_BASE_URL>/v1/orders/{id}/cancellation` | [orders-service router](https://github.com/example-org/orders-service/blob/9f2c1ab/src/orders/router.py) | Session bearer token |

---

### Query Configuration

| Data Source | Query Key | staleTime | retry | Invalidation Trigger | Owner |
|---|---|---|---|---|---|
| DS-001 | `['orders','list']` | 60000 | 2 | Successful cancellation | Storefront web |
| DS-002 | `['orders','cancel']` | n/a (mutation) | 0 | — | Storefront web |

---

### Error Classification

| Error Class | Condition | error_status_code | failure_reason | UI Behavior |
|---|---|---|---|---|
| Transport error | Request never reaches the service | 0 | `transport_failure` | Retry-able error state; cached list preserved on refetch. |
| Auth expiry | Service rejects the session token | 401 | `session_expired` | Hand off to the sign-in flow. |
| Rate limited | Service throttles the caller | 429 | `rate_limited` | Retry-able error state; no automatic retry. |
| Conflict | Cancellation target already shipped | 409 | `order_already_shipped` | Explain the order can no longer be cancelled; refresh the order. |
| Schema validation failure | Body is not valid JSON | 200 | `malformed_json` | Retry-able error state. |
| Content-incomplete | Body parses but an order lacks its reference | 200 | `required_field_missing` | Order omitted from the list; silent-failure event fires. |

---

### Route Mapping

| Behavioral Description | URL | Code Constant |
|---|---|---|
| Order history page | `/account/orders` | `routes.account.orders()` |
| Catalog entry from the empty state | `/catalog` | `routes.catalog.root()` |

---

### GET /v1/orders — Order List

#### Vocabulary

| V# | Semantic Name | API Field | Type | Required | Notes |
|----|---------------|-----------|------|----------|-------|
| V1 | order reference number | `order_reference` | string | yes | Human-readable, shown to the shopper. |
| V2 | order placement time | `placed_at` | string (ISO 8601) | no | Absent for orders migrated from the legacy platform. |
| V3 | order total | `total_amount` | string (decimal) | yes | Decimal string; compare in integer minor units. |
| V4 | billing currency | `currency_code` | string (ISO 4217) | no | Absent on legacy orders. |
| V5 | fulfillment status | `fulfillment_state` | enum | yes | Values documented in the API reference; unrecognised values render neutrally. |
| V6 | ordered items | `line_items` | array | yes | Each element carries product name, quantity, and unit price. |

#### Error Handling

| HTTP Status | Behavior |
|-------------|----------|
| 401 | Hand off to the sign-in flow. |
| 429 | Retry-able error state, no automatic retry. |
| 4xx / 5xx / network | Retry-able error state; cached list preserved on background refresh. |
| 200 with malformed body | Retry-able error state. |

---

### POST /v1/orders/{id}/cancellation — Order Cancellation

#### Vocabulary

| V# | Semantic Name | API Field | Type | Required | Notes |
|----|---------------|-----------|------|----------|-------|
| V7 | cancellation motive | `cancellation_reason` | enum | yes | Fixed list published in the API reference. |
| V8 | cancellation time | `cancelled_at` | string (ISO 8601) | yes | Server-assigned on acceptance. |

#### Error Handling

| HTTP Status | Behavior |
|-------------|----------|
| 401 | Abandon the cancellation and hand off to the sign-in flow. |
| 409 | Explain the order can no longer be cancelled and refresh the order. |
| 4xx / 5xx / network | Keep the cancellation dialog open with a retry-able message. |

---

### Configuration Attributes

| Attribute | Description | Example value (dev) |
|-----------|-------------|---------------------|
| `<ORDERS_API_BASE_URL>` | Base URL of the orders service, including its gateway prefix. | `https://api-dev.example.com/orders` |

---

### Component Mapping

| UI Element | Component | Source File |
|-----------|-----------|-------------|
| Order row | `<DataRow expandable />` | `src/components/ui/data-row.tsx` |
| Placeholder list | `<SkeletonList rows={5} />` | `src/components/ui/skeleton-list.tsx` |
| Cancellation dialog | `<Dialog />` | `src/components/ui/dialog.tsx` |

**Component mapping confirmation**:
- [x] Every Source File path opened and verified (not inferred from naming conventions)
- [x] Every cited prop verified against the component's prop definitions
- [x] Existing composed page/template components compared against FRs; additions flagged as gaps or justified divergences

---

### Visual References

| Screen / Step | Visual Reference | Notes |
|---|---|---|
| Order history page | DS component: `src/components/ui/data-row.tsx` | Uses component as-is. |
| Cancellation dialog | DS component: `src/components/ui/dialog.tsx` | Uses component as-is. |

**Visual reference confirmation**:
- [x] Every row above points to a Figma frame or DS component, or cites a `ds-gap` issue
- [x] No `__prototype__/` files are referenced as visual authority
- [x] Tickets generated from this PRD will reference the visual source

---

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
| ASM-002 | A shopper has fewer than 200 orders, so the list needs no pagination in this release. | Analytics query on order counts | The unpaginated list would degrade for high-volume shoppers. |
| ASM-003 | The cancellation endpoint is idempotent for an already-cancelled order. | Verbal confirmation from the orders platform team | A double submit could produce two cancellation records. |

---

### Open Questions

None — all questions resolved.
