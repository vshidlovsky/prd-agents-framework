# Order History Slim Violations Fixture — PRD <!-- expect: LINT-009 -->

> Deliberately broken slim-mode PRD for `scripts/tests/run-tests.sh`.
> Sibling of `violations-prd.md`, which covers the full-mode shape. Each planted
> defect is annotated with `<!- - expect: LINT-00N - ->` on the offending line so
> the harness can assert the linter fires there. Do not "fix" this file.
>
> Planted here: no `## Technical Contract` **and** no `### Display Rules`
> (LINT-009 slim-anchor branch), a `[V#]` marker with no Semantic Vocabulary row
> and a duplicate V-number inside the behavioral layer (LINT-001), an unused
> Product Constant and a bare inline bound in an AC (LINT-010), transport
> taxonomy in an Analytics Events property cell (LINT-011), a wire encoding in
> a Semantic Vocabulary Type cell (LINT-012).

---

## Context

### What

Users can review every order they have placed and cancel one that has not yet shipped.

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

- **Order**: A single purchase made by the shopper, carrying a placement time and a fulfillment status.

---

### Product Constants

| ID | Constant | Value | What it bounds | Referenced by |
|----|----------|-------|----------------|---------------|
| PC-001 | order list request deadline | 30 seconds | How long the page waits before showing the retry-able error state. | FR-004 |
| PC-002 | order list freshness window | 60 seconds | How long a loaded list is treated as current. | (none) <!-- expect: LINT-010 --> |

---

### Semantic Vocabulary

| V# | Semantic Name | Type | Required | Notes |
|----|---------------|------|----------|-------|
| V1 | order reference number | string | yes | Human-readable, shown to the shopper. |
| V2 | order placement time | timestamp | no | Absent on legacy orders. |
| V5 | fulfillment status | enumeration | yes | Unrecognised members render neutrally. |
| V2 | cancellation time | timestamp | yes | Duplicate V-number inside one layer. <!-- expect: LINT-001 --> |
| V6 | order placement epoch | number (epoch milliseconds) | no | Wire encoding planted in the Type cell. <!-- expect: LINT-012 --> |

---

### Acceptance Criteria

#### Order List

- [ ] **AC-001**: Opening the order history page shows every order for the signed-in shopper, most recently placed first.
- [ ] **AC-002**: An order list request that has not responded within 30 seconds is abandoned and the retry-able error state appears. <!-- expect: LINT-010 -->

#### Error States

- [ ] **AC-003**: When the initial order list request fails, the page shows a retry-able error state.
- [ ] **AC-004**: When the initial order list request fails, AE-001 fires with the failure-reason property.

---

#### Analytics Events

| # | Event Name | Trigger | Properties | Description |
|---|---|---|---|---|
| AE-001 | `order_history_load_failed` | The initial order list request fails | `error_status_code: number` (`0` for transport failure; the real response status otherwise), `failure_reason: "transport" / "http_error" / "parse_error"` | Wire taxonomy planted. <!-- expect: LINT-011 --> |

---

### Edge Cases

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| 1 | The shopper has exactly one order | The list renders that single order. |
| 2 | The order list request exceeds the order list request deadline (PC-001) | The page shows the retry-able error state. |

---

## Boundaries

### Out of Scope

- **OS-001**: **Returns and refunds** — a separate initiative owns the returns flow.

---

### Open Questions

None — all questions resolved.
