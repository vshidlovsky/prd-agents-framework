# {Initiative Name} — PRD

> This is the base template for all Product Requirements Documents.
> Both `prd-writer` and `prd-reviewer` agents reference this file.
>
> **Title**: Replace `{Initiative Name}` with the initiative name. Always use the format `# {Initiative Name} — PRD`.
>
> **How to use**: Copy this template, fill in every Tier 1 section, include section packs listed in project-context.md.
> Delete the `> **GUIDE**` blocks after filling each section.
>
> **Section order**: Context (what, who) → Behavioral Contract (requirements, constants, vocabulary, display rules, verification, edge cases) → Technical Contract (section packs, dependencies, and — in `full` mode only — APIs, mappings, config) → Boundaries (scope, questions) → evidence appendices (project-specific evidence packs, e.g. a custom mobile-baseline pack and the discrepancy section it feeds). Within each area, follow the numbered insertion-point markers for section pack placement. Evidence is not context: an appendix never sits between Context and the Behavioral Contract — every reader would have to scroll past it to reach the contract.
>
> **Separation principle**: The Behavioral Contract describes *what* the system does (observable by users and testers). The Technical Contract describes *how* it's built (readable by engineers). A requirement passes the behavioral test if a QA engineer can verify it without reading source code. See `.claude/rules/behavioral-separation.md` for the full rules.
>
> **Placement rule (governs both contracts)**: *Every number, rule, and policy a user can perceive lives in the behavioral layer. A constant, format, ordering, or policy may never live only in a technical table, a discrepancy row, or a section the reader has to reconstruct it from.* The Technical Contract may repeat a user-perceivable value; it must never be its only home.
>
> **Technical Contract mode**: `project-context.md` → PRD Configuration → **Technical Contract → Mode** selects `slim` (default) or `full`; a `/create-prd <initiative> --tc full|slim` run override wins over the project setting. In `slim` mode the PRD-owned technical tables below are omitted and the team's technical design owns that content — the PRD still carries Product Constants, Semantic Vocabulary and Display Rules in the behavioral layer. In `full` mode the PRD also carries the Technical Contract tables (legacy behavior).
>
> **Section packs**: The prd-writer inserts additional sections from `templates/sections/` based on what's listed in `project-context.md`. Each section pack has an `Insert into` tag with a numbered position (e.g., `Insert into: Technical Contract [position: 1]`). Insert packs in ascending position order. Packs sharing the same position number should be inserted in alphabetical order by section name.

---

## Context

### What

> **GUIDE**
> **What**: One sentence describing what the user/system can do after this is built, followed by brief business context.
> **Why**: Forces clarity of scope.
> **How**: Start with "Users can..." or "System can..." and describe the end capability. Then add 1-3 sentences of business context (user pain point, compliance need, etc.).
> **Versioning**: If this PRD supersedes a previous version, add a blockquote:
> `> This PRD supersedes [name] v1. The v1 PRD and all related artifacts are obsolete.`

[One sentence: what the user/system can do after this is built]

---

### User Story

> **GUIDE**
> **What**: "As a [role], I want [goal] so that [benefit]."
> **Why**: Centers the PRD on user/system value. Keeps scope focused.
> **How**: One or two user stories max. If you need more, the feature may be too broad.

As a [role], I want [goal] so that [benefit].

---

<!-- Section packs: Context [position: 1] (e.g., user-journey) -->

## Behavioral Contract

> **Notation**: This section uses semantic concept names for data attributes. Each semantic name that maps to an API field is linked via a `[V#]` marker on first use, pointing to a row in the [Semantic Vocabulary](#semantic-vocabulary) table below. Non-API concepts (routing destinations, configuration URLs, client-side state) use consistent semantic names without V-markers; name the destination or setting semantically on first use (e.g., "post-sign-in destination"), and in `full` mode reference the Technical Contract section that maps it.
>
> **Vocabulary files**: If `semantic-vocabulary/` files exist for the endpoints in this initiative, semantic names MUST match the vocabulary entries. For new fields not yet in vocabulary, the writer proposes entries in the handoff file.
>
> **Separation rule**: FRs, ACs, Edge Cases, and Key Entities must describe observable behavior only — decide every phrase with the three generic tests (rename / designer-choice / QA-observability). The canonical allowed and forbidden item lists are the two Quick Reference sections in `.claude/rules/behavioral-separation.md`; read them before drafting.

### Shared Requirements

> **GUIDE**
> **What**: Reference to the project's shared requirements document listing which SRs this feature inherits and any feature-specific overrides.
> **Why**: Cross-cutting requirements are centralized. Restating them causes duplication and drift.
> **How**: List all applicable SR IDs. For overrides or exclusions, explain what's different and why. If the project has no shared requirements document, delete this section.
> **Ownership**: PM-owned. Agents consume but never add new SRs without explicit user approval.

This feature inherits all shared requirements from `docs/shared-requirements.md`:
- [list applicable SR-NN IDs with short labels]

**Feature-specific overrides:**
- [SR-NN]: [describe override and justification, or "N/A — reason"]

---

### Functional Requirements

> **GUIDE**
> **What**: Numbered "System MUST" statements. Each gets a stable ID (FR-001, FR-002, ...).
> **Why**: Scannable contract at a higher level than ACs. FRs answer "what must the system do?" while ACs answer "how do I verify it?"
> **How**:
> - Each starts with "System MUST" and describes a single capability.
> - One sentence each. Use semantic concept names with `[V#]` markers on first use.
> - Number sequentially: FR-001, FR-002, etc.
> - Every FR should map to one or more ACs below.
> - Aim for 10-20 FRs. More suggests the scope is too broad.
> **Separation check**: Describe observable behavior only, using semantic names with `[V#]` markers on first use — apply the Quick Reference lists in `.claude/rules/behavioral-separation.md`.

- **FR-001**: System MUST [capability using semantic names with [V#] markers].
- **FR-002**: System MUST [capability].

#### Key Entities

> **GUIDE**
> **What**: Core domain objects this initiative introduces or depends on.
> **Why**: Names domain concepts explicitly. Helps devs name types consistently.
> **How**: One bullet per entity. Include: what it is, format/constraints, how it's used. Reference the vocabulary table for field-level details.
> **Business-level only**: NO language-specific types, NO file paths, NO enum names, NO API field names. Use semantic concept names.

- **[Entity Name]**: [What it is, format, how it's used in this initiative. See the Semantic Vocabulary table for the concept's definition.]

---

### Product Constants

> **GUIDE**
> **What**: Every user-perceivable number the requirements depend on — deadlines, freshness windows, timeouts the user waits through, retry limits, cooldowns, list ceilings, behavior thresholds. One row each.
> **Why**: This is the placement rule made structural. A constant that lives only in a technical table disappears when the technical contract does, and the requirement that depends on it becomes unbuildable. The value lives here, in the behavioral layer, once.
> **How**:
> - Give every constant a stable ID (PC-001, PC-002, ...) and a semantic name.
> - **Every FR/AC that depends on a bound cites the constant by ID** — `PC-001` — instead of restating the bare number inline. The value appears in this table and nowhere else.
> - Every row must be referenced by at least one FR, AC, or Edge Case. An unreferenced constant is dead spec — delete it (Quality Standard #9).
> - Values that are *not* user-perceivable (connection pool sizes, buffer lengths, internal batch sizes) do NOT belong here — they are dev-owned.
> **Both modes**: this section is Tier 1 in `slim` and `full` alike. In `full` mode the Technical Contract may repeat a value; it must never be its only home.

| ID | Constant | Value | What it bounds | Referenced by |
|----|----------|-------|----------------|---------------|
| PC-001 | [semantic name of the bound] | [value with unit] | [which behavior this bounds, and what happens at the limit] | [FR/AC IDs] |

---

### Semantic Vocabulary

> **GUIDE**
> **What**: The concept dictionary for this PRD. One row per semantic concept name used in the behavioral layer with a `[V#]` marker.
> **Why**: This is the vocabulary bridge — the PRD names the concepts, the team binds them to fields using the canonical API reference. Naming the concept is the PM's job; binding it to a wire field is the team's.
> **How**:
> - V-numbers are sequential across the whole PRD and are assigned to API-backed concepts only. Never assign a V-number to a routing destination, a configuration URL, or client-side state.
> - Copy semantic names from `semantic-vocabulary/` files when they exist; propose new entries in the handoff rather than inventing a competing name.
> - Every `[V#]` marker in the behavioral layer resolves to a row here; every row is used by at least one FR/AC/Edge Case.
> - **Type column (`slim` mode): semantic types only** — `money amount`, `instant`, `string`, `boolean`, `enumeration`, `list of <entity>`, `error signal`. No units, no epoch bases, no encodings: "number (minor units)", "number (epoch milliseconds)", "ISO-8601 string" are facts about the wire format — exactly the binding the `[V#]` indirection exists to keep dev-owned. (`full` mode may keep encoded types in the per-endpoint tables.)
> - **Notes carry product semantics** — what an absent value means, which affordance consumes it — and point to the Display Rule that owns the rendering. Encoding facts the team must not miss (a unit mismatch, an epoch-base trap that differs from the rest of the product) are recorded in the canonical API reference entry for the endpoint, which the row may cite — they are developer warnings, not product vocabulary.
> - **`API Field` is an optional, dev-owned column.** Omit it in `slim` mode. Add it only when the project keeps a PRD-owned technical contract (`Mode: full`) and wants the binding in one place — in that case do not also duplicate the V-numbers in a per-endpoint table.

| V# | Semantic Name | Type | Required | Notes |
|----|---------------|------|----------|-------|
| V1 | [concept name] | [type] | [yes/no] | [what the value means; which distinction the behavior branches on] |

---

### Display Rules

> **GUIDE**
> **What**: One row per rendered value, stating what determines its presentation and showing a worked example.
> **Why**: A format the user reads is a product decision, not a rendering detail. Timezone, currency and minor-unit handling, symbol-vs-code, ordering, and truncation change what the user believes — they must not live only in a technical table or be left to the implementer.
> **How**: For every value the user sees, state the determinant — which clock/timezone a time is rendered in, which currency and how minor units are handled, whether the symbol or the ISO code is shown, what the sort key and direction are, where and how text truncates — then give one concrete worked example (input → rendered output).
> **Worked examples carry the encoding**: use raw wire values as the example input. An example demonstrates the mapping ("`2550` + `usd` → `$25.50`") without owning the contract — it survives even if the backend later documents the field differently, where a normative "minor units, divide by 100" claim does not. This is the sanctioned home for encoding knowledge in `slim` mode; the Semantic Vocabulary Type column stays semantic.
> **Coverage**: every value named in an FR or AC that is displayed to a user needs a row. Mark `N/A — no rendered values` for services with no user-facing output.

| ID | Rendered Value | Presentation Determinant | Worked Example |
|----|----------------|--------------------------|----------------|
| DR-001 | [value as the user sees it] | [timezone / currency + minor units / symbol vs code / sort key + direction / truncation rule] | [input → rendered output] |

---

### Acceptance Criteria

> **GUIDE**
> **What**: Checkboxes that a reviewer can verify by using the running application.
> **Why**: The detailed verification spec. If it's not here, it doesn't get built.
> **How**:
> - Every criterion gets a stable ID: AC-001, AC-002, ...
> - Every criterion starts with a user-visible action or state.
> - Must include sub-sections for: Loading States, Error States, Empty States (when applicable).
> **Separation check**: Describe what the user sees and does, using semantic concept names with `[V#]` markers on first use — apply the Quick Reference lists in `.claude/rules/behavioral-separation.md`.

#### [Screen / Flow Area]

- [ ] **AC-001**: [Specific, testable criterion using semantic names with [V#] markers on first use]
- [ ] **AC-002**: [Another criterion]

#### Loading States

> **GUIDE**: What the user/caller sees while processing. Cover three distinct cases:
> - **Initial load**: no cached data exists — state that a loading presentation shows until the gating reads resolve, referencing the shared loading requirement where one exists. The placeholder's composition and shape are design-owned — no "shaped like the code block and list" prescriptions.
> - **Background refetch with cached data**: stale time elapsed, refetch in flight, but previous data is on screen — does the UI show cached data unchanged (no skeleton, no spinner), or does it overlay a loading indicator?
> - **Background refetch failure**: For every read-only endpoint with a refetch policy, include a dedicated AC for background-refetch failure. Default: preserve cached data on-screen, fire a `<feature>_refetch_failed` analytics event, do NOT swap to error state. Make the choice explicit in an AC — do not assume.
> - **Mutation in-flight**: a write operation is pending — what disables, what spins?
> For backend services: cover async processing indicators, queue states, or in-flight request states if applicable. Mark `N/A` if the service is purely synchronous with no user-visible wait states.

- [ ] **AC-NNN**: [Loading behavior].

#### Error States

> **GUIDE**: What happens when something fails. Cover: API errors, auth errors, network failures, validation errors.
> Applies to all project types — every system has failure modes. Describe error behavior semantically. Don't hardcode error copy.
> - **Transient vs persistent**: When an error state can result from both transient (the service unreachable, rate-limited, or failing) and persistent (an unusable response, a content bug) failures, either (a) specify differentiated copy per class, OR (b) explicitly document in the PRD body that generic copy is intentional with a stated rationale. Silent reliance on generic copy is a defect.

- [ ] **AC-NNN**: [Error behavior].

#### Empty States

> **GUIDE**: What happens when there's no data. Only include if the feature has data lists or query results that can be empty.
> For backend services without user-facing data displays: mark `N/A` and remove this sub-section. Don't hardcode empty-state copy.

- [ ] **AC-NNN**: [Empty state behavior].

---

<!-- Section packs: Behavioral Contract — after Acceptance Criteria [position: 1] (e.g., analytics-events) -->

### Edge Cases

> **GUIDE**
> **What**: Boundary conditions, nullable fields, concurrent actions, failure modes.
> **Why**: Edge cases are where bugs live. The #1 complaint about AI-generated PRDs is missing edge cases.
> **How**: Generate systematically, not from intuition. For each Key Entity, run through: null/missing, empty, min boundary, max boundary, just-outside-boundary, invalid format, stale data, render determinant (timezone, currency, ordering, truncation). For each API endpoint: network failure, timeout, auth expiry, rate limit, partial response, concurrent mutation. For each conditional FR: indeterminate condition, rapid toggle mid-flow. Then deduplicate and remove impossible scenarios.
> **Separation check**: Use semantic names with `[V#]` markers where applicable. Edge cases can be slightly more specific than FRs/ACs (they describe concrete data scenarios), but the same separation rule applies — see the Quick Reference lists in `.claude/rules/behavioral-separation.md`.

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| 1 | [condition] | [behavior] |

---

### Feature Flags / Remote Config

> **GUIDE**: Feature flags, remote config, rollout settings. If the feature ships with no flag and no remote config, OMIT this section and add a clause to the Considered, N/A ledger in Boundaries instead — a table of "None" is dead prose.

| Field | Value |
|-------|-------|
| **Flag name** | [name or "None"] |
| **Fallback** | [behavior when flag is off] |

---

<!-- Section packs: Behavioral Contract — after Edge Cases [position: 1] (e.g., accessibility, compliance, platform-considerations); in `slim` mode also [position: 2] responsive-layout, [position: 3] design-prototype, [position: 4] screen-flow + navigation -->

## Technical Contract

> **Tier 2 — condition**: the project keeps a PRD-owned technical contract (`Technical Contract → Mode: full` in `project-context.md`, or a `--tc full` run override). This ENTIRE section — heading included — exists **only** in `full` mode; in `slim` mode DELETE it completely.
>
> In `slim` mode nothing is homeless: Dependencies lives in Boundaries (both modes), the user-facing section packs (screen-flow, navigation, design-prototype, responsive-layout) insert into the Behavioral Contract per their `slim` insertion tags, and the implementation packs (component-mapping, database-changes, service-integration, monitoring) are `full`-mode only. The content that is *purely* implementation reference is **dev-owned by default**: component paths, configuration attributes, mock data, error-code-to-class mappings, query/cache configuration, route constants, and API request/response shapes live in the team's technical design, not in the PRD. A PRD is not incomplete for omitting them.
>
> The behavioral anchors stay in the Behavioral Contract in both modes: **Product Constants**, **Semantic Vocabulary**, **Display Rules**. Never move a user-perceivable number, format, ordering, or policy down here — this section may repeat one, but it may never be its only home.
>
> **Organization (`full` mode)**:
> 1. Cross-cutting tables — Data Sources, Query Configuration, Error Classification, Route Mapping
> 2. Per-endpoint blocks — Vocabulary table (V-numbered rows binding semantic names to API fields) + Error Handling
> 3. UI/config sections — Component Mapping, Visual References, etc. (copy, localization keys, and translations are design-owned — not a PRD section)
>
> In `full` mode the per-endpoint Vocabulary tables carry the API-field binding for the same V-numbers defined in the Semantic Vocabulary table. Repeating a V-number across the two layers is expected; splitting the set across them is not — every marker must resolve in both places or in the Semantic Vocabulary table alone.

<!-- PRD-owned technical content — `full` mode only. In `slim` mode delete every sub-section from here through Configuration Attributes, keeping the section packs and Dependencies. -->

### Data Sources

> **GUIDE**
> **What**: Every API endpoint this initiative consumes or exposes, with full URL patterns, methods, auth, and canonical reference links.

| ID | Semantic Name | Endpoint | Method | Full URL Pattern | Canonical Ref | Auth |
|---|---|---|---|---|---|---|
| DS-001 | [name] | `METHOD /path` | [METHOD] | `<BASE_URL>/path` | [link] | [auth method] |

---

### Query Configuration

> **GUIDE**
> **What**: Cache/query settings for each data source. One row per data source.

| Data Source | Query Key | staleTime | retry | Invalidation Trigger | Owner |
|---|---|---|---|---|---|
| DS-001 | `['key']` | [value] | [value] | [trigger] | [owner] |

---

### Error Classification

> **GUIDE**
> **What**: How errors are categorized for analytics and UI behavior. Defined once, referenced by all error-handling ACs.

| Error Class | Condition | error_status_code | failure_reason | UI Behavior |
|---|---|---|---|---|
| Transport error | [when] | 0 | `transport_failure` | [behavior] |
| HTTP error | [when] | [real HTTP code] | [specific reason] | [behavior] |
| Schema validation failure | [when] | 200 | `malformed_json` | [behavior] |
| Content-incomplete | [when] | 200 | `required_field_missing` | [behavior] |

> **Distinctness rule**: Every `(error_status_code, failure_reason)` tuple in this table MUST be unique. If two error classes share the same HTTP status, they MUST have distinct `failure_reason` values. Specifically:
> - Guard-triggered failures (duplicate cursor, loop detection, client-side validation) must NOT reuse a `failure_reason` already assigned to a server-returned error class.
> - "Structurally valid but content-incomplete" (HTTP 200, required field empty/null) is distinct from "schema validation failure" (malformed JSON). Never collapse both into a single `parse_error`.
> - For numeric `error_status_code`: `0` for transport failures, real HTTP codes for HTTP responses. Use `failure_reason` to disambiguate within a status code.

---

### Route Mapping

> **GUIDE**
> **What**: Maps semantic destination names (used in behavioral layer) to actual URLs and code constants.

| Behavioral Description | URL | Code Constant |
|---|---|---|
| [semantic name used in FRs/ACs] | `/path` | `code.constant()` |

---

### [Endpoint Name]

> **GUIDE**
> **What**: Per-endpoint detail block. Create one of these for each data source.

#### Vocabulary

> **GUIDE**: `full` mode only. Binds the semantic concept names defined in the [Semantic Vocabulary](#semantic-vocabulary) table to actual API fields, per endpoint. Reuse the same V-numbers — this table repeats them with their field binding, it does not define a second set. Copy entries from vocabulary files (`semantic-vocabulary/`) when they exist; add new rows for fields not yet mapped.

| V# | Semantic Name | API Field | Type | Required | Notes |
|----|---------------|-----------|------|----------|-------|
| V1 | [concept name] | `field_name` | [type] | [yes/no] | [optional clarification] |

#### Error Handling

| HTTP Status | Behavior |
|-------------|----------|
| 401 | [behavior] |
| 4xx / 5xx / network | [behavior] |
| 200 with malformed body | [behavior] |

---

### Configuration Attributes

> **GUIDE**: Environment-specific config (base URLs, API prefixes, application IDs, timeout values, etc.).
> PRDs MUST NOT hardcode base URLs or environment-specific hostnames in endpoint specifications. Endpoint paths in the Technical section MUST be specified relative to a named configuration attribute (e.g., "`<ORDERS_API_BASE_URL>/v1/orders`" rather than "`/v1/orders`" or "`api-dev.example.com/orders-service/v1/orders`"). This makes it explicit which client/prefix each endpoint belongs to and eliminates environment-switching guesswork.

| Attribute | Description | Example value (dev) |
|-----------|-------------|---------------------|
| `<BASE_URL>` | [description] | [example] |

---

<!-- Section packs (`full` mode): Technical Contract [position: 1] — UI structure (component-mapping, responsive-layout) -->
<!-- Section packs (`full` mode): Technical Contract [position: 2] — content & visuals (design-prototype) -->
<!-- Section packs (`full` mode): Technical Contract [position: 3] — navigation & flow (screen-flow, navigation) -->
<!-- Section packs (`full` mode): Technical Contract [position: 4] — infrastructure (database-changes, service-integration, monitoring) -->

## Boundaries

> **Sub-section order**: Always use this order: Considered, N/A → Dependencies → Out of Scope → Assumptions → [section packs: position 1] → Open Questions.
> Section packs inserted into Boundaries go between Assumptions and Open Questions, in position order.

### Considered, N/A

> **GUIDE**
> **What**: One line naming every conditional section that was considered and omitted because its trigger is absent — with the reason in a few words per clause.
> **Why**: Conditional sections (Compliance, Feature Flags, capacity where trivial, form/input material, ...) are OMITTED when their trigger is absent — no defensive N/A prose blocks. But silent omission is worse than N/A prose: the reviewer must be able to distinguish "considered and not applicable" from "forgotten." This ledger is that distinction, and the reviewer FAILs a conditional section that is both missing and unledgered.
> **How**: One clause per omitted section, ` · ` separated, reason in a few words (one sentence maximum). Each reason must hold against the PRD's own facts. If nothing was omitted, state "None — every conditional section applies."
> **Both modes**: applies in `slim` and `full` mode alike.

**Considered, N/A**: [Section] ([reason in a few words]) · [Section] ([reason])

---

### Dependencies

> **GUIDE**
> **What**: Other initiatives, components, or infrastructure that must exist before this can be built.
> **Both modes**: Dependencies is a product fact (a blocked initiative), not implementation reference — it lives here in `slim` and `full` mode alike.

| Dependency | Source | Status |
|-----------|--------|--------|
| [what] | [where it comes from] | [Merged / In Progress / Blocked] |

---

### Out of Scope

> **GUIDE**
> **What**: Things explicitly NOT part of this initiative. AI agents cannot infer boundaries from omission.

- **OS-001**: **[Feature/behavior]** — [reason]

---

### Assumptions

> **GUIDE**
> **What**: Conditions that must be true for this PRD to be valid but are not verified by the system. If an assumption breaks, the PRD is silently wrong.
> **Why**: Open Questions capture "what we don't know." Assumptions capture "what we think we know that could be wrong." A broken assumption doesn't cause a build error — it causes wrong behavior that passes all tests.
> **How**: For each assumption, state: (1) what you're assuming, (2) where the assumption came from (code observation, API docs, verbal confirmation, convention), (3) what breaks if the assumption is wrong. If you can verify an assumption during research, do so and remove it. Only assumptions that cannot be verified at spec-writing time belong here.
>
> **Examples across stacks**:
> - Frontend: "API always returns ISO 4217 currency codes — if it returns free-text, the currency formatter throws"
> - Backend stateless: "Upstream service responds within 2s — if slower, our 5s timeout fires and the client retries"
> - Backend stateful: "Table row count stays under 10M for year 1 — if exceeded, the unindexed query in the reporting endpoint degrades"

| ID | Assumption | Source | Impact if Wrong |
|----|-----------|--------|-----------------|
| ASM-001 | [what we're assuming] | [code / API docs / verbal / convention] | [what breaks] |

---

<!-- Section packs: Boundaries [position: 1] (e.g., cross-initiative-alignment) -->

### Open Questions

> **GUIDE**
> **What**: Must be EMPTY before approval. During drafting, list questions here with a resolution method tag so reviewers know HOW to get the answer. Resolve each by researching or asking the user, then move the decision into the relevant section.
>
> **Resolution method tags:**
> - `ASK:role` — needs a human answer (PM, design, backend, legal, etc.)
> - `CHECK:source` — answer exists somewhere, go look (analytics, docs, code, competitor)
> - `TEST:env` — requires running/testing something (staging, prod)
>
> **Format**: `- OQ-N [METHOD:target]: question`

None — all questions resolved.

<!-- Section packs: Evidence appendices — end of document, after Boundaries [position: 1] (e.g., a custom mobile-baseline pack). An evidence appendix carries at most: a pinned source-repo SHA line, a summary of at most 3 sentences, and a decision table with source-code citations only in its Source column — never in prose. Everything longer lives in the research document. Decision-row IDs (e.g., MA-###) are position-independent, so FR/AC references to them are unaffected by the appendix placement. -->

## Tier 2 — Include When Applicable

> Include these when conditions apply. Each has an **Insert into** tag.
> **How to use**: When the condition applies, MOVE the section to its insertion point (specified by the `Insert into` tag) — do not leave it here at the bottom. When the condition does not apply, DELETE the section entirely and record it as a clause in the Considered, N/A ledger in Boundaries — never leave an N/A prose block in its place.

---

### Test Coverage

> **Insert into**: Behavioral Contract — after Acceptance Criteria [position: 2]

> **GUIDE**
> **When**: Any PRD whose ACs will be handed to an implementer (i.e. effectively always; omit only for exploratory specs that will not be built from directly).
> **What**: How each acceptance criterion gets verified, and how states that cannot occur naturally in a test environment are produced.
> **Both modes**: behavioral-layer content — it describes how the product's observable behavior gets verified, not how the code is structured. Keep it in `slim` and `full` mode alike.
> **How**: Bind every AC (or AC group) to a verification approach — unit / integration / E2E where a UI exists; unit / integration / contract for backend services (E2E is not required where no UI exists) — or designate it `manual` with its trigger described. An AC that no test type claims and no manual designation covers will silently not be verified. Add an environment-override row for every state a test must be able to force but that cannot occur naturally (a denied permission, an absent platform capability, a dismissed native sheet).

| AC / AC group | Verification | Notes |
|---|---|---|
| AC-001..AC-004 | integration | |
| AC-012 | manual | native share sheet cannot be automated; tester dismisses it by hand |

**Environment overrides** — states a test must be able to force:

| State | How the test produces it |
|---|---|
| clipboard write denied | deny the permission in the test context |
| share unavailable | run in a context where the platform share entry point is absent |

---

### Success Criteria

> **Insert into**: Behavioral Contract — after Edge Cases [position: 1]

> **GUIDE**
> **When**: Features with user-facing flows where quality bar matters.
> **What**: Measurable outcomes that define how *well* the feature should work.

- **SC-001**: [Measurable outcome]

---

### Security Constraints

> **Insert into**: Behavioral Contract — after Edge Cases [position: 1]

> **GUIDE**
> **When**: Any feature that reads, displays, transmits, or stores auth tokens, PII (names, phone numbers, emails, avatars, account numbers), payment data, or sensitive state. "Touching" includes read-only display — a dashboard showing user names and passing customer data via router state triggers this section.
> **What**: Security requirements specific to this initiative — what must NOT be logged, exposed in URLs, persisted in browser storage, or sent in analytics.

---

### Support / Observability

> **Insert into**: Behavioral Contract — after Edge Cases [position: 1]

> **GUIDE**
> **When**: Features with degraded states that have no user-visible distinguisher (e.g., silent background failures, identical error copy for different failure classes), OR features where the on-screen signal collapses multiple underlying classes into one user-facing message.
> **What**: Symptom-to-query mappings for support engineers. This section is MANDATORY when any of these conditions hold.
>
> **Required sub-sections**:
>
> 1. **Silent-state workflows**: For every FR/AC with "fail silently" / "silently suppress" / "no visible change" behavior, include: (a) the analytics event that is the SOLE signal of this state, (b) the user-reported symptom that should trigger a proactive support query, (c) explicit note: "this state has no UI signal — query [event] using user_id + timestamp window."
>
> 2. **Collapsed-error workflows**: For every page state where N underlying classes produce one user-facing message, include: (a) the user-reported symptom phrase, (b) the analytics query to identify the user + window, (c) property-to-action mapping from each underlying class to a support runbook action, (d) either a visible distinguisher in the UI (error code, correlation ID) OR explicit documentation of the analytics-based support workflow.
>
> 3. **Multi-gated suppression**: When a UI element has multiple gates that can suppress it, include a single internal analytics event with a discriminator (`reason` enum) covering every suppression path.
>
> 4. **Cross-initiative hand-offs**: When a silent state's analytics is delegated to another initiative, name (a) the specific event name, (b) the specific property/sentinel, (c) the symptom-to-query mapping. Soft hand-offs without a named event are insufficient — log as an Open Question if the owning initiative hasn't defined the event yet.
>
> **Semantic classes, not wire taxonomy (`slim` mode)**: support workflows reference the semantic failure classes carried on the analytics events (`unreachable | rejected | unusable_response | incomplete_record`, or the initiative's equivalents) and state what support DOES per class. Never build a workflow on reading HTTP encodings ("`error_status_code: 200` + `parse_error` → escalate") — the mapping from wire observation to class is dev-owned, and deeper discrimination lives in the dev-owned diagnostic properties documented in the analytics catalog.

---

### Cross-Initiative Alignment Notes

> **Insert into**: Boundaries [position: 1]

> **GUIDE**
> **When**: Feature overlaps with or depends on other initiatives.
> **What**: What's shared, what to be careful about, sequencing notes.
