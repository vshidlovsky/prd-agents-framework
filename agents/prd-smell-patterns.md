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

These smells detect technical implementation details that have leaked into the behavioral layer (FRs, ACs, Edge Cases, Key Entities). The behavioral layer should be verifiable by a QA engineer without reading source code. Technical details belong in the Technical Contract, referenced via `[TC-*]` anchors.

- **API field leak**: Raw API field names in behavioral requirements — `tx_id`, `delivery_method_alias`, `deleted_at`, `avatar_url`, `currency_code`. Replace with semantic concept names: "transaction identifier", "delivery method label", "soft-delete marker". Each semantic name maps to exactly one API field, defined in the Technical Contract field mapping.
- **Enum leak**: API enum values listed in FRs/ACs — `cancelled`, `cancelling`, `customerRequestedToCancel`, `"BANK DEPOSIT"`, `"onHold"`, `boss-money-wallet`. Replace with semantic group names: "cancelled status [TC-AM]", "on-hold stage [TC-AM]". The full enum-to-label mapping belongs in the Technical Contract.
- **URL pattern leak**: Route paths or URL templates in behavioral requirements — `/transaction/<id>`, `/send/amount`, `/settings`, `/recipients`. Replace with semantic destination names: "the transaction details page [TC-RT]", "the new transaction flow [TC-RT]". URL-to-route-constant mapping belongs in Route Mapping `[TC-RT]`.
- **UI copy in requirement**: Hardcoded heading text, body copy, button labels, or toast messages in FRs/ACs — `"No activity yet"`, `"Coming soon"`, `"Couldn't load activity"`, `"Try again"`. Replace with behavioral descriptions: "render an empty state [TC-LK]", "render a placeholder toast [TC-LK]". Exact copy belongs in Localization Keys `[TC-LK]`.
- **Analytics event name inline**: Event names or payload schemas in FRs/ACs — `home_dashboard_viewed`, `home_dashboard_section_failed`, `tx_id: string`. Replace with semantic trigger names: "the page-viewed analytics event", "the section-failed analytics event (see Analytics Events table)". The Analytics Events table is the source of truth for event names and properties.
- **Framework terminology**: Library-specific or framework-specific concepts in behavioral requirements — "query invalidation", "cache expiry", "staleTime", "React Router state", "Zod schema validation", "Axios interceptor". Replace with observable behavior: "data refreshes after successful mutations", "data refreshes when the user navigates away and back". Framework details belong in the Technical Contract.
- **Design decision in requirement**: Layout prescriptions, visual arrangements, pixel values, or component types in FRs/ACs — "horizontally scrollable carousel", "16px gap", "sticky mobile top bar", "≥ 1024px", "green variant". Replace with behavioral intent: "recipient cards", "mobile viewports (per SR-09)". Layout and visual treatment belong in design specs or Component Mapping `[TC-CM]`.
