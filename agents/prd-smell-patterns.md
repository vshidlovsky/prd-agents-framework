# Requirements Smell Patterns

Canonical list of anti-patterns in requirements. Used by the PRD reviewer
and its sub-agents when evaluating FR and AC quality.

## Linguistic Smells

Source: Femmer et al., TU Munich, 2017 — adapted for PRD review.

- **Vague verb**: "handle", "manage", "process", "support", "deal with" — require a concrete verb (display, send, reject, store, calculate)
- **Loophole**: "if possible", "as appropriate", "when feasible", "as needed", "where applicable" — gives dev permission to skip
- **Ambiguous pronoun**: "it", "they", "this" without clear antecedent in same sentence
- **Passive voice hiding actor**: "is validated", "is shown" — WHO does it? The system, the API, the user?
- **Open-ended list**: "etc.", "and so on", "such as" used as substitute for a complete list
- **Superlative/comparative**: "fastest", "better", "optimal" — unmeasurable without baseline
- **Incomplete conditional**: "if X then Y" without specifying what happens when X is false
- **Subjective language**: "user-friendly", "intuitive", "clean", "simple", "seamless" — not testable
- **Implementation delegation**: "via someFunction()", "using utilityName", "formatted by formatTime", "whatever X returns", "as returned by" — delegates the requirement to current code instead of defining expected behavior. Replace with the observable output (format, thresholds, concrete examples).

## Behavioral/Technical Separation Smells

Source: PRD behavioral/technical separation rules — see `rules/behavioral-separation.md`.

These smells detect technical implementation details that have leaked into the behavioral layer (FRs, ACs, Edge Cases, Key Entities). The behavioral layer should be verifiable by a QA engineer without reading source code. Technical details belong in the Technical Contract, referenced via `[V#]` vocabulary markers.

- **API field leak**: Raw API field names in behavioral requirements — `tx_id`, `delivery_method_alias`, `deleted_at`, `avatar_url`, `currency_code`. Replace with semantic concept names: "transaction identifier", "delivery method label", "soft-delete marker". Each semantic name maps to exactly one API field, defined in the per-endpoint vocabulary table.
- **Enum leak**: API enum values listed in FRs/ACs — `cancelled`, `cancelling`, `customerRequestedToCancel`, `"BANK DEPOSIT"`, `"onHold"`, `"digital-wallet"`. Replace with semantic group names: "cancelled status", "on-hold stage". The full enum-to-label mapping belongs in the Technical Contract.
- **URL pattern leak**: Route paths or URL templates in behavioral requirements — `/transaction/<id>`, `/send/amount`, `/settings`, `/recipients`. Replace with semantic destination names: "the transaction details page", "the new transaction flow". URL-to-route-constant mapping belongs in the Route Mapping section.
- **UI copy in requirement**: Hardcoded heading text, body copy, button labels, or toast messages in FRs/ACs — `"No activity yet"`, `"Coming soon"`, `"Couldn't load activity"`, `"Try again"`. Replace with behavioral descriptions: "render an empty state", "display an error notification". Exact copy belongs in the Localization Keys section.
- **Analytics event name inline**: Event names or payload schemas in FRs/ACs — `home_dashboard_viewed`, `home_dashboard_section_failed`, `tx_id: string`. Replace with semantic trigger names: "the page-viewed analytics event", "the section-failed analytics event (see Analytics Events table)". The Analytics Events table is the source of truth for event names and properties.
- **Framework terminology**: Library-specific or framework-specific concepts in behavioral requirements — "query invalidation", "staleTime", "React Router state", "Zod schema validation", "Axios interceptor". Replace with observable behavior: "data refreshes after successful mutations", "data refreshes when the user navigates away and back". Framework details belong in the Technical Contract. **CS jargon sub-category**: Terms like "atomically replace", "first-expiry-wins", "single shared in-flight refresh", "invalidate the cached user profile" are CS jargon describing testable behavior (verifiable with browser dev tools). Flag for **rephrasing to QA-verifiable language**, not for relocation to TC — they stay as FRs. **Not framework terminology — do NOT flag**: Product decisions and platform concepts that sound technical: "replacing the current history entry", "proactive refresh", "browser's reported language", "device identifier header". These describe what the system does, not how it's built.
- **Design decision in requirement**: Any language that chooses how the UI renders something rather than describing what the user sees or does. This includes layout arrangements that prescribe CSS structure (sticky, full-surface, grid-3-column), visual treatments (pixel values, color variants, spacing tokens), and breakpoint values. The test: could a designer reasonably choose a different component or layout to present the same behavior? If yes, the PRD shouldn't prescribe it. Replace with behavioral intent — what the user sees, learns, or does. **Do NOT flag**: (a) interaction patterns that *are* the product requirement (drag-to-reorder, swipe-to-dismiss); (b) shipped DS component names when the PM explicitly chose them (carousel, skeleton, bottom sheet — the DS ships it, so it's a product decision); (c) behavioral placement ("inline beneath the input", "near the triggering element") — this describes where the user sees feedback, not CSS positioning; (d) "new browser tab" — user-visible navigation behavior; (e) PM-decided display formats ("MM:SS", "zero-padded") — product requirements, not visual treatments; (f) platform concepts ("browser's one-time-code autofill"); (g) generic UI vocabulary ("indicator", "6-slot", "grid", "notification"); (h) enum values in analytics ACs — property values that make ACs testable.

**Vocabulary-aware checking**: When semantic vocabulary files exist for the initiative's endpoints (`semantic-vocabulary/`), cross-reference them. If a vocabulary file maps `delivery_method_alias` to "delivery method label" and the FR uses "delivery method alias" or `delivery_method_alias`, both are FAIL — the vocabulary file's semantic name is the only acceptable term in the behavioral layer.
