# Behavioral/Technical Separation

PRDs MUST separate behavioral requirements from technical implementation details into two distinct sections: the **Behavioral Contract** and the **Technical Contract**.

## Core Principle

A requirement passes the behavioral test if a QA engineer can verify it without reading source code. QA verification includes dev tools (network, storage, console inspection) — a requirement verifiable that way is still behavioral, even if it sounds technical. CS jargon that describes testable behavior should be rephrased to how QA would actually verify it, but it stays in the Behavioral Contract.

Decide whether a phrase belongs in the behavioral layer with three generic tests. These are platform-agnostic — they catch web, mobile, and backend leaks without enumerating examples, so do NOT rely on matching a phrase against a list of known-bad samples; apply the test:

1. **Rename test** — would the requirement break if a developer renamed an API field, endpoint, status code, header, config key, or localization key, even though the observable behavior is unchanged? If yes, it is technical → move it to the Technical Contract and reference it by semantic name.
2. **Designer-choice test** — could a designer present the same behavior with a different component, layout, or visual treatment? If yes, the phrase is a design decision → remove it; describe what the user sees, learns, or does instead. (Applies to emphasis/variant qualifiers such as "filled" vs "tonal" button, plus color, spacing, and layout — regardless of platform.)
3. **QA-observability test** — can a tester confirm it purely by using the running app, with no knowledge of how it is built or stored? If no, it is an implementation detail → move it to the Technical Contract; do not reword it into the behavioral layer. (E.g. which secure-storage mechanism holds a value, which transport carries it.)

**Product-requirement carve-out:** when the mechanic *is* the product requirement, it stays in the behavioral layer even if it names UI or input mechanics — e.g. "accepts only a 6-digit numeric code", "drag to reorder", "swipe to dismiss". The test: is this a PM decision about *what the product does*, or a designer/engineer decision about *how it is rendered or built*? Only the former belongs here.

## Copy and Localization Are Design-Owned

Final user-facing copy, localization keys, and translations are **design deliverables**, produced with or after design — they are NOT part of the PRD. The PRD specifies copy *intent per state*: which states need a message and what each message must convey (e.g. "show an error explaining the entered codes did not match and prompting a retry"), never the literal string, the localization key, or the translation.

**Completeness, not wording:** the PRD must still enumerate every state that needs a message (error, empty, success, loading) so design knows what copy to produce. Drop the words, keep the coverage.

**Exception — mandated copy:** when exact wording is dictated by law, compliance, or contract (regulatory disclosures, legal terms), it stays in the PRD as a constraint, with its source cited, and design must use it verbatim. This is the only case where literal copy appears in requirements. (Analytics event names and property values are a data contract, not UI copy — they remain in the PRD regardless.)

## Behavioral Contract

Contains: FRs, ACs, Edge Cases, Key Entities, Feature Flags, Success Criteria, Security, Accessibility, Compliance, Support/Observability.

Rules for this layer:
- Use **semantic concept names** for data attributes (e.g., "order identifier" not `order_id`)
- Add **`[V#]` markers** on first use of each semantic name, linking it to the vocabulary table in the Technical Contract
- Each semantic name maps to exactly one API field — if ambiguous, make it more specific
- **Use vocabulary files when they exist** — if `semantic-vocabulary/` contains a file for an endpoint, use the semantic names defined there. Do not invent alternatives for fields that already have vocabulary entries. See `rules/semantic-vocabulary.md`
- **Never include API vocabulary**: API field names, endpoint paths, query keys, enum values, URL patterns, HTTP status codes, header names, analytics event names, constructor signatures, framework-specific terminology (library names, config keys). CS jargon describing testable behavior ("atomically replace", "first-expiry-wins") is not API vocabulary — it stays in FRs but should be rephrased to QA-verifiable language. Product decisions and platform concepts that sound technical ("replacing the current history entry", "proactive refresh", "browser's reported language") are acceptable as-is
- **Never make design decisions**: Do not specify layout arrangements that prescribe CSS structure (sticky, full-surface, grid-3-column) or visual treatments (pixel values, color variants, spacing). Describe what the user sees, learns, or does — let design decide how to render it. Exceptions — these are product language, not design decisions: (a) interaction patterns that *are* the product requirement (drag-to-reorder, swipe-to-dismiss); (b) shipped DS component names when explicitly chosen by PM; (c) behavioral placement ("inline beneath the input") when it distinguishes feedback strategies (field-level vs page-level); (d) PM-decided display formats ("MM:SS", "zero-padded"); (e) "new browser tab" (user-visible navigation); (f) platform concepts ("browser's one-time-code autofill"); (g) generic UI vocabulary ("indicator", "grid", "notification"); (h) enum values in analytics ACs when they make the AC testable

## Technical Contract

Contains: Data Sources, Query Configuration, Error Classification, Route Mapping, per-endpoint Vocabulary tables + Error Handling, Component Mapping, Visual References, Screen Flow, MSW Mock Data, Configuration Attributes, Dependencies. (Copy, localization keys, and translations are NOT here — they are design deliverables; see "Copy and Localization Are Design-Owned" above.)

Rules for this layer:
- **Cross-cutting concerns defined once**: Error classification, query config, route mapping each live in one table as implementation reference
- **Per-endpoint blocks** include: Vocabulary table (V-numbered rows mapping semantic names to API fields) and Error Handling (HTTP status → behavior)

## `[V#]` Vocabulary References

FRs and ACs use `[V#]` markers to link semantic names to their definitions in per-endpoint vocabulary tables inside the Technical Contract.

**Scope**: V-numbers are exclusively for API field mappings — concepts that resolve to a field in an endpoint's request or response. Non-API concepts (routing destinations, configuration URLs, client-side state) do not get V-numbers. Use a consistent semantic name and reference the relevant TC section on first use (e.g., "post-sign-in destination (see Route Mapping)", "configured terms URL (see Configuration Attributes)").

**Format**: `[V1]`, `[V2]`, `[V3]`, etc. — sequential across all endpoints in the PRD.

**First-use rule**: The first time a semantic name appears in an FR or AC, it gets a `[V#]` marker. Subsequent uses of the same term do not repeat the marker.

**Example**:
```
- FR-001: System MUST display the order identifier [V1] and shipping method label [V2].
- FR-002: System MUST display the order identifier and the order status [V3].
```

Each `[V#]` resolves to exactly one row in a per-endpoint vocabulary table:

```
### GET /v1/orders/{id}

#### Vocabulary

| V# | Semantic Name | API Field | Type | Required | Notes |
|----|---------------|-----------|------|----------|-------|
| V1 | order identifier | order_id | string | yes | |
| V2 | shipping method label | shipping_method_code | string | no | |
| V3 | order status | status | string | yes | |
```

V-numbers are local to a single PRD. Vocabulary files (`semantic-vocabulary/`) provide the cross-initiative source of truth for semantic names. The writer copies entries from vocabulary files into the PRD's tables, assigning V-numbers. The PRD is self-contained.

## Detection

The prd-reviewer detects violations using the "Behavioral/Technical Separation Smells" in `agents/prd-smell-patterns.md`. Seven smell patterns cover: API field leaks, enum leaks, wire-detail leaks (paths, status codes, headers), UI copy / localization keys in requirements, analytics event names inline, framework terminology / implementation mechanism, and design decisions in requirements (including emphasis variants and over-specified ACs).

## This Rule Applies To

- **prd-writer**: MUST produce separated Behavioral/Technical Contracts with `[V#]` vocabulary references
- **prd-reviewer**: MUST check for separation violations in FRs, ACs, and Edge Cases (FAIL for FRs/ACs, WARN for Edge Cases)
- **All agents**: MUST NOT embed technical details in the behavioral layer when writing or revising PRDs

This rule applies to all agents, skills, and conversations in this project.
