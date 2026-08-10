# Order History Violations Fixture — PRD <!-- expect: LINT-009 -->

<!--
Deliberately broken PRD. Every LINT-00N check has at least one instance here,
annotated with `<!- - expect: LINT-00N - ->` on the offending line so
scripts/tests/run-tests.sh can assert the linter reports it at that line.
Do not "fix" this file — it is the negative fixture.
LINT-009 is annotated on line 1 because missing/renamed top-level sections are
reported against line 1; here `## Boundaries` is renamed to `## Scope Boundaries`.
-->

## Changelog

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-01-12 | v1 | PM | Initial draft. |
| 2026-01-19 | v3 | PM | Added the cancellation flow. |
| 2026-01-26 | v2 | PM | Reworded the empty state. <!-- expect: LINT-004 --> |

---

## Context

### What

> **GUIDE** <!-- expect: LINT-006 -->
> **What**: One sentence describing what the user/system can do after this is built.

Users can review every order they have placed and cancel an order that has not yet shipped.

---

### User Story

As a returning shopper, I want to see my past orders so that I do not have to contact support.

---

## Behavioral Contract

### Functional Requirements

- **FR-001**: System MUST list every order belonging to the signed-in shopper, newest first by order placement time [V2].
- **FR-002**: System MUST show each order's order reference number [V1] and fulfillment status [V5].
- **FR-003**: System MUST show the shipment carrier name [V9] for every shipped order. <!-- expect: LINT-001 -->

#### Key Entities

- **Order**: A single purchase made by the shopper, identified by a human-readable order reference number.

---

### Acceptance Criteria

#### Order List

- [ ] **AC-001**: Opening the order history page shows every order for the signed-in shopper, newest first.
- [ ] **AC-002**: Each order row shows the order reference number and the fulfillment status.
- [ ] **AC-003**: An order whose `fulfillment_state` is unshipped shows a cancel affordance. <!-- expect: LINT-008 -->
- [ ] **AC-004**: Opening the order history page fires `order_history_viewed`. <!-- expect: LINT-007 -->
- [ ] **AC-005**: Opening the order history page fires AE-001 with the order-count property.

#### Error States

- [ ] **AC-006**: When the initial order list request fails, the page shows a retry-able error state.

#### Empty States

- [ ] **AC-007**: A shopper who has never placed an order sees an empty state explaining no orders exist yet.

---

#### Analytics Events

| # | Event Name | Trigger | Properties | Description |
|---|---|---|---|---|
| AE-001 | `order_history_viewed` | Order history page becomes visible | `order_count` (integer) | Page view event. |
| AE-002 | `order_cancellation_confirmed` | Backend confirms a cancellation | `motive` (enum) | Successful cancellation. <!-- expect: LINT-007 --> |

---

### Edge Cases

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| 1 | The shopper has exactly one order | The list renders that single order. |
| 2 | The order list request times out | The page shows the retry-able error state. |

---

## Technical Contract

### Data Sources

| ID | Semantic Name | Endpoint | Method | Full URL Pattern | Canonical Ref | Auth |
|---|---|---|---|---|---|---|
| DS-001 | Order list | `GET /v1/orders` | GET | `<ORDERS_API_BASE_URL>/v1/orders` | [router](https://github.com/example-org/orders-service/blob/main/src/orders/router.py) | Session bearer token <!-- expect: LINT-003 --> |
| DS-002 | Order cancellation | `POST /v1/orders/{id}/cancellation` | POST | `<ORDERS_API_BASE_URL>/v1/orders/{id}/cancellation` | [router](https://github.com/example-org/orders-service/blob/9f2c1ab/src/orders/router.py) | Session bearer token |

---

### Error Classification

| Error Class | Condition | error_status_code | failure_reason | UI Behavior |
|---|---|---|---|---|
| Transport error | Request never reaches the service | 0 | `transport_failure` | Retry-able error state. |
| Auth expiry | Service rejects the session token | 401 | `session_expired` | Hand off to the sign-in flow. |

---

### Route Mapping

| Behavioral Description | URL | Code Constant |
|---|---|---|
| Order history page | `/account/orders` | `routes.account.orders()` |

---

### GET /v1/orders — Order List

#### Vocabulary

| V# | Semantic Name | API Field | Type | Required | Notes |
|----|---------------|-----------|------|----------|-------|
| V1 | order reference number | `order_reference` | string | yes | Human-readable. |
| V2 | order placement time | `placed_at` | string (ISO 8601) | no | Absent on legacy orders. |
| V5 | fulfillment status | `fulfillment_state` | enum | yes | Unrecognised values render neutrally. |

#### Error Handling

| HTTP Status | Behavior |
|-------------|----------|
| 401 | Hand off to the sign-in flow. |
| 4xx / 5xx / network | Retry-able error state. |

---

### POST /v1/orders/{id}/cancellation — Order Cancellation

#### Vocabulary

| V# | Semantic Name | API Field | Type | Required | Notes |
|----|---------------|-----------|------|----------|-------|
| V7 | cancellation motive | `cancellation_reason` | enum | yes | Fixed list. |
| V2 | cancellation time | `cancelled_at` | string (ISO 8601) | yes | Duplicate V-number. <!-- expect: LINT-001 --> |

#### Error Handling

| HTTP Status | Behavior |
|-------------|----------|
| 409 | Explain the order can no longer be cancelled. |

---

### Configuration Attributes

| Attribute | Description | Example value (dev) |
|-----------|-------------|---------------------|
| `<ORDERS_API_BASE_URL>` | Base URL of the orders service. | `https://api-dev.example.com/orders` |

---

### Component Mapping

| UI Element | Component | Source File |
|-----------|-----------|-------------|
| Order row | `<DataRow expandable />` | `src/components/ui/data-row.tsx` |

**Component mapping confirmation**:
- [ ] Every Source File path opened and verified (not inferred from naming conventions) <!-- expect: LINT-002 -->
- [x] Every cited prop verified against the component's prop definitions
- [x] Existing composed page/template components compared against FRs; additions flagged as gaps or justified divergences

---

### Dependencies

| Dependency | Source | Status |
|-----------|--------|--------|
| Cancellation endpoint on the orders service | Orders platform team | Merged |

---

## Scope Boundaries

### Out of Scope

- **OS-001**: **Returns and refunds** — owned by a separate initiative.

---

### Assumptions

| ID | Assumption | Source | Impact if Wrong |
|----|-----------|--------|-----------------|
| ASM-001 | Monetary totals arrive as decimal strings. | API reference | Float comparison would drift. |

---

### Open Questions

- OQ-1 [ASK:PM]: Should cancelled orders stay in the list or move to a separate tab? <!-- expect: LINT-005 -->
