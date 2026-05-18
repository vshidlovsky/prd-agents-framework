# PRD Template — Base

> This is the base template for all Product Requirements Documents.
> Both `prd-writer` and `prd-reviewer` agents reference this file.
>
> **How to use**: Copy this template, fill in every Tier 1 section, include section packs listed in project-context.md.
> Delete the `> **GUIDE**` blocks after filling each section.
>
> **Section order**: Context (what, who) → Behavioral Contract (requirements, verification, edge cases) → Technical Contract (APIs, mappings, config) → Boundaries (dependencies, scope, questions).
>
> **Separation principle**: The Behavioral Contract describes *what* the system does (observable by users and testers). The Technical Contract describes *how* it's built (readable by engineers). A requirement passes the behavioral test if a QA engineer can verify it without reading source code. See `rules/behavioral-separation.md` for the full rules.
>
> **Section packs**: The prd-writer inserts additional sections from `templates/sections/` based on what's listed in `project-context.md`. Each section pack has an `Insert into` tag that specifies where it goes.

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

<!-- Section packs with "Insert into: Context" go here (e.g., user-journey) -->

## Behavioral Contract

> **Notation**: This section uses semantic concept names for data attributes, data sources, and destinations. All concept-to-API-field and concept-to-endpoint mappings are defined in the [Technical Contract](#technical-contract) section. Cross-references use `[TC-*]` anchors — see the Technical Contract for the full anchor index.
>
> **Separation rule**: FRs, ACs, Edge Cases, and Key Entities must describe observable behavior only. Never include: API field names, endpoint paths, query keys, enum values, URL patterns, UI copy strings, analytics event names, pixel breakpoints, CSS class names, constructor signatures, or framework-specific terminology. These belong in the Technical Contract, referenced via `[TC-*]` anchors. See `rules/behavioral-separation.md`.

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
> - One sentence each. Use semantic concept names with `[TC-*]` anchors for data and destinations.
> - Number sequentially: FR-001, FR-002, etc.
> - Every FR should map to one or more ACs below.
> - Aim for 10-20 FRs. More suggests the scope is too broad.
> **Separation check**: No API field names, no URL paths, no enum values, no UI copy, no analytics event names, no pixel breakpoints, no framework terms. Replace with semantic names + `[TC-*]` references.

- **FR-001**: System MUST [capability] [TC-*].
- **FR-002**: System MUST [capability] [TC-*].

#### Key Entities

> **GUIDE**
> **What**: Core domain objects this initiative introduces or depends on.
> **Why**: Names domain concepts explicitly. Helps devs name types consistently.
> **How**: One bullet per entity. Include: what it is, format/constraints, how it's used. Reference `[TC-*]` for field-level details.
> **Business-level only**: NO language-specific types, NO file paths, NO enum names, NO API field names. Use semantic concept names.

- **[Entity Name]**: [What it is, format, how it's used in this initiative. See [TC-XX] for the full field mapping.]

---

### Acceptance Criteria

> **GUIDE**
> **What**: Checkboxes that a reviewer can verify by using the running application.
> **Why**: The detailed verification spec. If it's not here, it doesn't get built.
> **How**:
> - Every criterion gets a stable ID: AC-001, AC-002, ...
> - Every criterion starts with a user-visible action or state.
> - Must include sub-sections for: Loading States, Error States, Empty States (when applicable).
> **Separation check**: Use semantic concept names. Reference `[TC-*]` for technical details. Don't embed API enums, URL paths, UI copy, analytics event names, or breakpoints — point to the relevant TC section or table instead.

#### [Screen / Flow Area]

- [ ] **AC-001**: [Specific, testable criterion using semantic names and [TC-*] references]
- [ ] **AC-002**: [Another criterion]

#### Loading States

> **GUIDE**: What the user/caller sees while processing. Cover three distinct cases:
> - **Initial load**: no cached data exists — what placeholder/skeleton does the user see?
> - **Background refetch with cached data**: stale time elapsed, refetch in flight, but previous data is on screen — does the UI show cached data unchanged (no skeleton, no spinner), or does it overlay a loading indicator?
> - **Mutation in-flight**: a write operation is pending — what disables, what spins?
> For backend services: cover async processing indicators, queue states, or in-flight request states if applicable. Mark `N/A` if the service is purely synchronous with no user-visible wait states.

- [ ] **AC-NNN**: [Loading behavior] [TC-CM].

#### Error States

> **GUIDE**: What happens when something fails. Cover: API errors, auth errors, network failures, validation errors.
> Applies to all project types — every system has failure modes. Reference `[TC-EC]` for error classification details. Don't hardcode error copy — reference `[TC-LK]`.

- [ ] **AC-NNN**: [Error behavior] [TC-EC] [TC-LK].

#### Empty States

> **GUIDE**: What happens when there's no data. Only include if the feature has data lists or query results that can be empty.
> For backend services without user-facing data displays: mark `N/A` and remove this sub-section. Don't hardcode empty-state copy — reference `[TC-LK]`.

- [ ] **AC-NNN**: [Empty state behavior] [TC-LK].

---

<!-- Section packs with "Insert into: Behavioral Contract (after Acceptance Criteria)" go here (e.g., analytics-events) -->

### Edge Cases

> **GUIDE**
> **What**: Boundary conditions, nullable fields, concurrent actions, failure modes.
> **Why**: Edge cases are where bugs live. The #1 complaint about AI-generated PRDs is missing edge cases.
> **How**: Generate systematically, not from intuition. For each Key Entity, run through: null/missing, empty, min boundary, max boundary, just-outside-boundary, invalid format, stale data. For each API endpoint: network failure, timeout, auth expiry, rate limit, partial response, concurrent mutation. For each conditional FR: indeterminate condition, rapid toggle mid-flow. Then deduplicate and remove impossible scenarios.
> **Separation check**: Use semantic names and reference ACs/TC sections. Edge cases can be slightly more specific than FRs/ACs (they describe concrete data scenarios), but should still avoid raw API field names and enum values where possible.

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| 1 | [condition] | [behavior] |

---

<!-- Section packs with "Insert into: Behavioral Contract (after Edge Cases)" go here (e.g., accessibility, compliance, platform-considerations, success-criteria, security-constraints, support-observability) -->

## Technical Contract

> This section maps the behavioral concepts used in the [Behavioral Contract](#behavioral-contract) to their API implementations. If the API changes, update this section — the behavioral requirements above should not need modification unless the change alters observable behavior.
>
> **Organization**:
> 1. Cross-cutting tables — defined once, referenced everywhere via `[TC-*]` anchors
> 2. Per-endpoint blocks — Field Mapping + Behavioral Mapping + Error Handling
> 3. UI/config sections — Component Mapping, Localization Keys, Visual References, etc.

### Data Sources [TC-DS]

> **GUIDE**
> **What**: Every API endpoint this initiative consumes or exposes, with full URL patterns, methods, auth, and canonical reference links.

| ID | Semantic Name | Endpoint | Method | Full URL Pattern | Canonical Ref | Auth |
|---|---|---|---|---|---|---|
| TC-DS-001 | [name] | `METHOD /path` | [METHOD] | `<BASE_URL>/path` | [link] | [auth method] |

---

### Query Configuration [TC-QC]

> **GUIDE**
> **What**: Cache/query settings for each data source. One row per data source.

| Data Source | Query Key | staleTime | retry | Invalidation Trigger | Owner |
|---|---|---|---|---|---|
| TC-DS-001 | `['key']` | [value] | [value] | [trigger] | [owner] |

---

### Error Classification [TC-EC]

> **GUIDE**
> **What**: How errors are categorized for analytics and UI behavior. Defined once, referenced by all error-handling ACs.

| Error Class | Condition | Analytics Properties | UI Behavior |
|---|---|---|---|
| Transport error | [when] | [properties] | [behavior] |
| HTTP error | [when] | [properties] | [behavior] |
| Schema validation failure | [when] | [properties] | [behavior] |

---

### Route Mapping [TC-RT]

> **GUIDE**
> **What**: Maps semantic destination names (used in behavioral layer) to actual URLs and code constants.

| Behavioral Description | URL | Code Constant |
|---|---|---|
| [semantic name used in FRs/ACs] | `/path` | `code.constant()` |

---

### [Endpoint Name] [TC-DS-NNN]

> **GUIDE**
> **What**: Per-endpoint detail block. Create one of these for each data source. The `[TC-XX]` anchor (e.g., `[TC-AM]` for Activity Mapping) is a 2-letter mnemonic for the endpoint's semantic name.

#### Field Mapping [TC-XX]

> **GUIDE**: Maps semantic concept names (used in behavioral layer) to actual API fields.

| Semantic Name | API Field | Type | Required | Notes |
|---|---|---|---|---|
| [concept name] | `field_name` | [type] | [yes/no] | [which FRs/ACs use this] |

#### Behavioral Mapping

> **GUIDE**: Traces which FRs and ACs each API field drives. Includes transformation rules, normalization, and fallback chains. This answers: "why does this field exist in the contract?"

**[Behavior name]** (FR-NNN, AC-NNN):
- Field: `field_name`
- Rule: [transformation / normalization / fallback]

#### Error Handling

| HTTP Status | Behavior |
|-------------|----------|
| 401 | [behavior] |
| 4xx / 5xx / network | [behavior] |
| 200 with malformed body | [behavior] |

---

### Configuration Attributes [TC-CA]

> **GUIDE**: Environment-specific config (base URLs, feature endpoints, etc.)

| Attribute | Description | Example value (dev) |
|-----------|-------------|---------------------|
| `<BASE_URL>` | [description] | [example] |

---

### Feature Flags / Remote Config [TC-FF]

> **GUIDE**: Feature flags, remote config, rollout settings. If no flags, state "None" and explain why.

| Field | Value |
|-------|-------|
| **Flag name** | [name or "None"] |
| **Fallback** | [behavior when flag is off] |

---

<!-- Section packs with "Insert into: Technical Contract" go here (e.g., component-mapping, localization, design-prototype, screen-flow, navigation, responsive-layout, feature-flags, database-changes, service-integration, monitoring) -->

## Boundaries

### Dependencies

> **GUIDE**
> **What**: Other initiatives, components, or infrastructure that must exist before this can be built.

| Dependency | Source | Status |
|-----------|--------|--------|
| [what] | [where it comes from] | [Merged / In Progress / Blocked] |

---

### Out of Scope

> **GUIDE**
> **What**: Things explicitly NOT part of this initiative. AI agents cannot infer boundaries from omission.

- **OS-001**: **[Feature/behavior]** — [reason]

---

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

---

<!-- Section packs with "Insert into: Boundaries" go here (e.g., cross-initiative-alignment) -->

## Tier 2 — Include When Applicable

> Include these when conditions apply. Each has an **Insert into** tag.
> **How to use**: When the condition applies, MOVE the section to its insertion point (specified by the `Insert into` tag) — do not leave it here at the bottom. When the condition does not apply, DELETE the section entirely.

---

### Success Criteria

> **Insert into**: Behavioral Contract (after Edge Cases)

> **GUIDE**
> **When**: Features with user-facing flows where quality bar matters.
> **What**: Measurable outcomes that define how *well* the feature should work.

- **SC-001**: [Measurable outcome]

---

### Security Constraints

> **Insert into**: Behavioral Contract (after Edge Cases)

> **GUIDE**
> **When**: Any feature that reads, displays, transmits, or stores auth tokens, PII (names, phone numbers, emails, avatars, account numbers), payment data, or sensitive state. "Touching" includes read-only display — a dashboard showing user names and passing recipient data via router state triggers this section.
> **What**: Security requirements specific to this initiative — what must NOT be logged, exposed in URLs, persisted in browser storage, or sent in analytics.

---

### Support / Observability

> **Insert into**: Behavioral Contract (after Edge Cases)

> **GUIDE**
> **When**: Features with degraded states that have no user-visible distinguisher (e.g., silent background failures, identical error copy for different failure classes).
> **What**: Symptom-to-query mappings for support engineers. Documents which analytics events to query, how to distinguish failure classes, and proactive workflows for states the user won't report.

---

### Cross-Initiative Alignment Notes

> **Insert into**: Boundaries (after Out of Scope)

> **GUIDE**
> **When**: Feature overlaps with or depends on other initiatives.
> **What**: What's shared, what to be careful about, sequencing notes.
