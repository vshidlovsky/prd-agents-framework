# Behavioral/Technical Separation

PRDs MUST separate behavioral requirements from technical implementation details into two distinct sections: the **Behavioral Contract** and the **Technical Contract**.

## Core Principle

A requirement passes the behavioral test if a QA engineer can verify it without reading source code. If a requirement would break when an API field is renamed — but the observable behavior hasn't changed — it belongs in the Technical Contract.

## Behavioral Contract

Contains: FRs, ACs, Edge Cases, Key Entities, Success Criteria, Security, Accessibility, Compliance, Support/Observability.

Rules for this layer:
- Use **semantic concept names** for data attributes (e.g., "transaction identifier" not `tx_id`)
- Add **`[V#]` markers** on first use of each semantic name, linking it to the vocabulary table in the Technical Contract
- Each semantic name maps to exactly one API field — if ambiguous, make it more specific
- **Use vocabulary files when they exist** — if `semantic-vocabulary/` contains a file for an endpoint, use the semantic names defined there. Do not invent alternatives for fields that already have vocabulary entries. See `rules/semantic-vocabulary.md`
- **Never include API vocabulary**: API field names, endpoint paths, query keys, enum values, URL patterns, analytics event names, constructor signatures, framework-specific terminology
- **Never make design decisions**: Do not specify UI components (toast, modal, carousel), layout arrangements (inline, sticky, full-surface), or visual treatments (pixel values, color variants, spacing). Describe what the user sees, learns, or does — let design decide how to render it. Exception: interaction patterns that *are* the product requirement (drag-to-reorder, swipe-to-dismiss) are behavioral

## Technical Contract

Contains: Data Sources, Query Configuration, Error Classification, Route Mapping, per-endpoint Vocabulary tables + Error Handling, Component Mapping, Localization Keys, Visual References, Screen Flow, MSW Mock Data, Configuration Attributes, Feature Flags.

Rules for this layer:
- **Cross-cutting concerns defined once**: Error classification, query config, route mapping each live in one table as implementation reference
- **Per-endpoint blocks** include: Vocabulary table (V-numbered rows mapping semantic names to API fields) and Error Handling (HTTP status → behavior)

## `[V#]` Vocabulary References

FRs and ACs use `[V#]` markers to link semantic names to their definitions in per-endpoint vocabulary tables inside the Technical Contract.

**Format**: `[V1]`, `[V2]`, `[V3]`, etc. — sequential across all endpoints in the PRD.

**First-use rule**: The first time a semantic name appears in an FR or AC, it gets a `[V#]` marker. Subsequent uses of the same term do not repeat the marker.

**Example**:
```
- FR-001: System MUST display the transaction identifier [V1] and delivery method label [V2].
- FR-002: System MUST display the transaction identifier and the transaction status [V3].
```

Each `[V#]` resolves to exactly one row in a per-endpoint vocabulary table:

```
### GET /v1/transactions/{id}

#### Vocabulary

| V# | Semantic Name | API Field | Type | Required | Notes |
|----|---------------|-----------|------|----------|-------|
| V1 | transaction identifier | tx_id | string | yes | |
| V2 | delivery method label | delivery_method_alias | string | no | |
| V3 | transaction status | status | string | yes | |
```

V-numbers are local to a single PRD. Vocabulary files (`semantic-vocabulary/`) provide the cross-initiative source of truth for semantic names. The writer copies entries from vocabulary files into the PRD's tables, assigning V-numbers. The PRD is self-contained.

## Detection

The prd-reviewer detects violations using the "Behavioral/Technical Separation Smells" in `agents/prd-smell-patterns.md`. Seven smell patterns cover: API field leaks, enum leaks, URL pattern leaks, UI copy in requirements, analytics event names inline, framework terminology, and design decisions in requirements.

## This Rule Applies To

- **prd-writer**: MUST produce separated Behavioral/Technical Contracts with `[V#]` vocabulary references
- **prd-reviewer**: MUST check for separation violations in FRs, ACs, and Edge Cases (FAIL for FRs/ACs, WARN for Edge Cases)
- **All agents**: MUST NOT embed technical details in the behavioral layer when writing or revising PRDs

This rule applies to all agents, skills, and conversations in this project.
