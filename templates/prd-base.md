# PRD Template — Base

> This is the base template for all Product Requirements Documents.
> Both `prd-writer` and `prd-reviewer` agents reference this file.
>
> **How to use**: Copy this template, fill in every Tier 1 section, include section packs listed in project-context.md.
> Delete the `> **GUIDE**` blocks after filling each section.
>
> **Section order**: Context (what, who) → Contract (requirements, verification, edge cases) → Technical (APIs) → Boundaries (dependencies, scope, questions).
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

## Contract

### Functional Requirements

> **GUIDE**
> **What**: Numbered "System MUST" statements. Each gets a stable ID (FR-001, FR-002, ...).
> **Why**: Scannable contract at a higher level than ACs. FRs answer "what must the system do?" while ACs answer "how do I verify it?"
> **How**:
> - Each starts with "System MUST" and describes a single capability.
> - One sentence each. No implementation details.
> - Number sequentially: FR-001, FR-002, etc.
> - Every FR should map to one or more ACs below.
> - Aim for 10-20 FRs. More suggests the scope is too broad.

- **FR-001**: System MUST [capability].
- **FR-002**: System MUST [capability].

#### Key Entities

> **GUIDE**
> **What**: Core domain objects this initiative introduces or depends on.
> **Why**: Names domain concepts explicitly. Helps devs name types consistently.
> **How**: One bullet per entity. Include: what it is, format/constraints, how it's used.
> **Business-level only**: NO language-specific types, NO file paths, NO enum names.

- **[Entity Name]**: [What it is, format, how it's used in this initiative]

---

### Acceptance Criteria

> **GUIDE**
> **What**: Checkboxes that a reviewer can verify by using the running application.
> **Why**: The detailed verification spec. If it's not here, it doesn't get built.
> **How**:
> - Every criterion gets a stable ID: AC-001, AC-002, ...
> - Every criterion starts with a user-visible action or state.
> - Must include sub-sections for: Loading States, Error States, Empty States (when applicable).

#### [Screen / Flow Area / Endpoint Name]

- [ ] **AC-001**: [Specific, testable criterion]
- [ ] **AC-002**: [Another criterion]

#### Loading States

> **GUIDE**: What the user/caller sees while processing. Cover: initial load, subsequent loads, mutation in-flight.
> For backend services: cover async processing indicators, queue states, or in-flight request states if applicable. Mark `N/A` if the service is purely synchronous with no user-visible wait states.

- [ ] **AC-NNN**: [Loading behavior]

#### Error States

> **GUIDE**: What happens when something fails. Cover: API errors, auth errors, network failures, validation errors.
> Applies to all project types — every system has failure modes.

- [ ] **AC-NNN**: [Error behavior + user-facing message/response]

#### Empty States

> **GUIDE**: What happens when there's no data. Only include if the feature has data lists or query results that can be empty.
> For backend services without user-facing data displays: mark `N/A` and remove this sub-section.

- [ ] **AC-NNN**: [Empty state behavior]

---

<!-- Section packs with "Insert into: Contract (after Acceptance Criteria)" go here (e.g., screen-flow, navigation, analytics-events, responsive-layout) -->

### Edge Cases

> **GUIDE**
> **What**: Boundary conditions, nullable fields, concurrent actions, failure modes.
> **Why**: Edge cases are where bugs live. The #1 complaint about AI-generated PRDs is missing edge cases.
> **How**: Generate systematically, not from intuition. For each Key Entity, run through: null/missing, empty, min boundary, max boundary, just-outside-boundary, invalid format, stale data. For each API endpoint: network failure, timeout, auth expiry, rate limit, partial response, concurrent mutation. For each conditional FR: indeterminate condition, rapid toggle mid-flow. Then deduplicate and remove impossible scenarios.

| # | Condition | Expected Behavior |
|---|-----------|-------------------|
| 1 | [condition] | [behavior] |

---

<!-- Section packs with "Insert into: Contract (after Edge Cases)" go here (e.g., accessibility, compliance, success-criteria, security-constraints) -->

## Technical

### API Endpoints

> **GUIDE**
> **What**: Full contract for every API endpoint this initiative uses or exposes.
> **Why**: Incomplete or wrong API specs cause wrong implementations.
> **How**: For each endpoint:
> - Source reference (spec file or code path)
> - Request AND response shapes using the project's native type syntax (TypeScript interfaces for TS projects, Java types for Spring Boot, Dart classes for Flutter, etc.)
> - Error responses with HTTP status, error code, user-facing message, behavior
> - Mark endpoints not in API docs as "from code — verify with owner"

#### `METHOD /path` — [description]

- **Source**: [spec file path or code path]
- **Request**:
  ```
  [fields with types]
  ```
- **Response**:
  ```
  [fields with types]
  ```
- **Errors**:

  | HTTP Status | Error Code | User-Facing Message | Behavior |
  |-------------|-----------|---------------------|----------|
  | 4xx | `"code"` | "Message" | [what happens] |

---

<!-- Section packs with "Insert into: Technical" go here (e.g., feature-flags, localization, component-mapping, database-changes, service-integration, monitoring) -->

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

> **Insert into**: Contract (after Edge Cases)

> **GUIDE**
> **When**: Features with user-facing flows where quality bar matters.
> **What**: Measurable outcomes that define how *well* the feature should work.

- **SC-001**: [Measurable outcome]

---

### Security Constraints

> **Insert into**: Contract (after Edge Cases)

> **GUIDE**
> **When**: Any feature touching auth, tokens, PII, payments, or sensitive data.
> **What**: Security requirements specific to this initiative.

---

### Cross-Initiative Alignment Notes

> **Insert into**: Boundaries (after Out of Scope)

> **GUIDE**
> **When**: Feature overlaps with or depends on other initiatives.
> **What**: What's shared, what to be careful about, sequencing notes.
