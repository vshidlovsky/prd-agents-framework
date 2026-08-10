# Order History — PRD Review

<!--
Deliberately broken review file. Each LINT-10N check has at least one instance
here, annotated on the offending line for scripts/tests/run-tests.sh.
Lint with: python3 scripts/prd-lint.py <this file> --mode review
-->

Cell counts, in the fenced form the reviewer scaffold actually emits:

```
SUB_AGENT_CELLS: 8
ORCHESTRATOR_CELLS: 3
TOTAL_CELLS: 12 <!-- expect: LINT-103 -->
```

## Summary

Review of the order history PRD. Assembly is incomplete — this file is a fixture.

## Verdict: NEEDS_REVISION

## Review Matrices

<!-- MATRIX:A:START -->
**Matrix A: API Endpoints**

| ID | Endpoint | Exists | Params Match | Response Match | Auth | Errors | Verdict |
|---|---|---|---|---|---|---|---|
| A-1 | `GET /v1/orders` | PASS | PASS | PASS | PASS | PASS | PASS |
| A-2 | `POST /v1/orders/{id}/cancellation` | PASS | PASS | PASS | PASS | WARN | WARN: conflict handling unclear <!-- expect: LINT-102 --> |
| A-3 | Missing endpoints check | N/A | N/A | N/A | N/A | N/A | PASS |
<!-- MATRIX:A:END -->

<!-- MATRIX:B:START -->
**Matrix B: FR Quality**

| ID | FR | Atomic | Necessary | Feasible | Verdict |
|---|---|---|---|---|---|
| B-1 | FR-001: list orders newest first | PASS | PASS | PASS | PASS |
| B-2 | FR-002: show reference and status | PASS | PASS | PASS | [PENDING] <!-- expect: LINT-101 --> |
| B-X | Orphan entity check | N/A | N/A | N/A | PASS |
<!-- MATRIX:B:END -->

<!-- MATRIX:F:START -->
**Matrix F: Structure**

| ID | Check | Verdict | Notes |
|---|---|---|---|
| F-1 | Context: "What" section states capability | PASS | Present. |
| F-10 | Boundaries: Open Questions is empty | FAIL: OQ-1 unresolved | Resolve before approval. |
| F-30 | Template conformance | INFO | Section renamed to Scope Boundaries <!-- expect: LINT-102 --> |
<!-- MATRIX:F:END -->

## Defect Taxonomy Scorecard

| Category | Count |
|----------|-------|
| Omission | 1 |
| Ambiguity | 0 |
| Inconsistency | 1 |
| Incorrect Fact | 0 |
| Extraneous Info | 0 |
| Misplaced Requirement | 0 |
