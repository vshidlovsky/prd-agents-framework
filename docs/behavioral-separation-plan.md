# Plan: Behavioral/Technical Separation in PRD Framework

**Status**: Complete (Phase 6 added 2026-05-18)
**Created**: 2026-05-17
**Source**: v5 refactoring of `home-dashboard` PRD — 15 rules discovered through iterative review

---

## Context

During the home-dashboard PRD refactoring (v2 → v5), we discovered that mixing behavioral requirements with technical/API details makes PRDs fragile — an API field rename forces changes to FRs, ACs, and Edge Cases. We developed 15 rules for separating behavioral from technical content and validated them through multiple review passes.

The rules are documented in:
- `/Users/vshidlovskiy/bm-web-recipient-list/docs/initiatives/home-dashboard/v5-refactoring-rules.md` (15 rules)
- `/Users/vshidlovskiy/bm-web-recipient-list/docs/initiatives/home-dashboard/home-dashboard-prd-v5.md` (reference implementation)

---

## The 15 Rules (Summary)

1. **No API artifacts** in behavioral layer (field names, endpoints, query keys)
2. **No code constructs** (constructors, class names, function calls, format strings)
3. **No unnecessary design decisions** (layout, spacing, component type)
4. **Use `[TC-*]` cross-reference anchors** linking behavioral concepts to TC sections
5. **Semantic concept names must be unambiguous** (one name = one API field)
6. **Cross-cutting concerns defined once** (error classification, query config, route mapping)
7. **Per-endpoint Behavioral Mapping** in TC (traces which FRs/ACs each field drives)
8. **Analytics events use semantic trigger names** (not query keys or handler names)
9. **Visual references point to TC sections** (not inline Figma/image URLs)
10. **No API enum values** in behavioral layer (status codes, type discriminators)
11. **No URL patterns** in behavioral layer (route paths, path parameters)
12. **No UI copy or analytics payloads** in behavioral layer (headings, button labels, event names)
13. **Semantic viewport names** (not pixel breakpoints — "mobile", "desktop", "wide desktop")
14. **Visual References and Screen Flow belong in TC** (`[TC-VR]`, `[TC-SF]`)
15. **No framework/library terminology** (query invalidation, cache expiry, React Router state)

---

## Implementation Plan

### Phase 1: Smell Patterns + Rules File
**Files**: `agents/prd-smell-patterns.md`, new `rules/behavioral-separation.md`
**Effort**: Small

**1a. Update `prd-smell-patterns.md`**
Add 7 new smell patterns to the existing 9:
- **API field leak**: Raw API field names (`tx_id`, `delivery_method_alias`, `deleted_at`) in FRs/ACs/Edge Cases
- **Enum leak**: API enum values (`cancelled`, `cancelling`, `"BANK DEPOSIT"`) in behavioral layer
- **URL pattern leak**: Route paths (`/transaction/<id>`, `/send/amount`) in behavioral requirements
- **UI copy in requirement**: Hardcoded strings (`"No activity yet"`, `"Coming soon"`) that should reference `[TC-LK]`
- **Analytics event name inline**: Event names (`home_dashboard_viewed`) in FRs/ACs instead of semantic references
- **Framework terminology**: Library-specific concepts (`query invalidation`, `cache expiry`, `staleTime`) in behavioral layer
- **Design decision in requirement**: Layout prescriptions (`horizontally scrollable carousel`, `16px gap`, `1024px breakpoint`) that belong in design specs or `[TC-CM]`

**1b. Create `rules/behavioral-separation.md`**
New gating rule (same pattern as existing rules/):
- Define the Behavioral Contract / Technical Contract boundary
- List the `[TC-*]` anchor vocabulary
- State the core principle: "A requirement passes the behavioral test if a QA engineer can verify it without reading source code"
- Reference `prd-smell-patterns.md` for the detection patterns

---

### Phase 2: Base Template
**File**: `templates/prd-base.md`
**Effort**: Medium

Restructure the existing template:
- Rename "Contract" → **"Behavioral Contract"**
- Add the `[TC-*]` notation preamble as a built-in block
- Rename "Technical" → **"Technical Contract"**
- Add standard TC subsection markers:
  - `[TC-DS]` Data Sources
  - `[TC-QC]` Query Configuration
  - `[TC-EC]` Error Classification
  - `[TC-RT]` Route Mapping
  - `[TC-CA]` Configuration Attributes
  - `[TC-FF]` Feature Flags
  - Per-endpoint blocks: `[TC-AM]`, `[TC-RM]`, `[TC-UM]` (Field Mapping + Behavioral Mapping + Error Handling)
- Add `<!-- TC-CM -->`, `<!-- TC-LK -->`, `<!-- TC-VR -->`, `<!-- TC-SF -->` insertion markers for section packs
- Add GUIDE blocks explaining what goes where

---

### Phase 3: PRD Writer Agent
**File**: `agents/prd-writer.md`
**Effort**: Medium

Add a "Behavioral/Technical Separation" mandate section:
- **When writing FRs/ACs/Edge Cases**: Use semantic concept names, add `[TC-*]` cross-references, never embed API fields/enums/URLs/copy/event names/breakpoints/framework terms
- **When writing Technical Contract**: Organize per-endpoint with Field Mapping + Behavioral Mapping + Error Handling; define cross-cutting tables once
- **Semantic naming convention**: Each concept name maps to exactly one API field; if ambiguous, make it more specific
- **Cross-reference discipline**: Every semantic concept in behavioral layer MUST have a `[TC-*]` anchor linking to its definition
- **Edge case generation**: Generate test scenarios using semantic names, not raw API values — reference ACs and TC sections for the specific data

---

### Phase 4: PRD Reviewer Agent
**File**: `agents/prd-reviewer.md`
**Effort**: Medium-Large

Add a new review sub-agent or extend `review-requirements`:
- **New matrix: Behavioral/Technical Separation (matrix S or BT)**
  - For each FR: check for API fields, enums, URLs, copy, event names, breakpoints, framework terms
  - For each AC: same checks
  - For each Edge Case: same checks (lighter — edge cases can be more specific but should still use semantic names)
  - For Key Entities: check that descriptions use semantic names with `[TC-*]` references
  - Cross-check: every `[TC-*]` reference in behavioral layer has a corresponding section in TC
  - Cross-check: every API field in TC has a Behavioral Mapping entry tracing back to FRs/ACs
- **Detection**: Use the 7 new smell patterns from Phase 1
- **Verdict**: FAIL if any FR or AC contains a raw API artifact; WARN for Edge Cases

---

### Phase 5: Section Packs
**Files**: `templates/sections/*.md`
**Effort**: Small-Medium

Tag and reorganize each section pack:

**Move to Technical Contract insertion**:
- `screen-flow.md` → `[TC-SF]` — Contains URLs and route mechanics
- `navigation.md` → `[TC-SF]` — Entry points with URLs, deep link paths
- `design-prototype.md` → `[TC-VR]` — Screen-to-component mapping with source files
- `responsive-layout.md` → `[TC-CM]` — Breakpoint values, CSS class names
- `component-mapping.md` → `[TC-CM]` — Component names and source file paths

**Keep in Behavioral Contract but clean up**:
- `analytics-events.md` — Stays in Behavioral as the source-of-truth table (FRs/ACs reference it semantically, table holds the actual event names)
- `accessibility.md` — Stays in Behavioral (WCAG requirements are behavioral, but remove pixel values and implementation specifics)
- `localization.md` → `[TC-LK]` — Actually moves to TC (i18n keys and translations are implementation)
- `feature-flags.md` → `[TC-FF]` — Moves to TC (flag names and config are implementation)

**No change needed**:
- `user-journey.md` — Behavioral (describes user flow, no tech details)
- `compliance.md` — Behavioral (regulatory requirements)
- `database-changes.md` — Already in Technical
- `service-integration.md` — Already in Technical
- `monitoring.md` — Already in Technical
- `platform-considerations.md` — Behavioral (platform-specific behavior)

Update each pack's `Insert into` tag to specify Behavioral Contract or Technical Contract.

---

## Execution Order

```
Phase 1 (smell patterns + rules)
    ↓ defines "what correct looks like"
Phase 2 (base template)
    ↓ structures the output format
Phase 3 (writer agent)
    ↓ produces correctly separated PRDs
Phase 4 (reviewer agent)
    ↓ catches violations
Phase 5 (section packs)
    ↓ final cleanup
```

Each phase is independently shippable. Phase 1 alone improves review quality. Phase 1+2 enables manual separation. Phase 1+2+3 produces separated PRDs automatically. Phase 4 closes the loop. Phase 5 is polish. Phase 6 fixes reviewer non-determinism.

---

## Validation

After each phase, re-run the framework against the home-dashboard PRD (v2 as input) and compare output to v5. The v5 file is the reference implementation:
- `home-dashboard-prd-v5.md` — what the output should look like
- `v5-refactoring-rules.md` — the 15 rules that produced it

---

### Phase 6: Dedicated Smell Pass (Reviewer Non-Determinism Fix)
**File**: `agents/prd-reviewer.md`
**Effort**: Medium
**Added**: 2026-05-18

**Problem**: Validation runs (v6, v7) revealed non-deterministic smell detection. The reviewer fills ~6 columns per row simultaneously across Matrix B and C (~1,200 micro-judgments). Different runs miss different violations — v6 caught "carousel" but missed "See all"; v7 caught "See all" but missed "carousel". Root cause: smell checking competes with atomicity, feasibility, FR link, state coverage, and implementation detail leak in the same cognitive pass.

**Solution**: Separate smell detection into its own dedicated pass.

1. **New Matrix S (Smell Detection)**: One row per FR + one row per AC. Two columns: Linguistic Smells (9 patterns), Separation Smells (7 patterns). No other quality judgments in this matrix.
2. **New Agent 5 (Smell Reviewer)**: Handles Matrix S exclusively. Reads each FR/AC against all 16 patterns with nothing else in working memory. One item at a time, full attention.
3. **Remove Smell Flags from Matrix B and C**: Agent 4 focuses on requirement quality only (atomicity, feasibility, FR link, contradictions, implementation detail leak). No smell checking.
4. **Updated dispatch**: 5 parallel agents instead of 4. Updated scaffold, assembly, cleanup, handoff JSON.

**Rationale**: Attention is probabilistic. When 6+ judgment types compete per row, accuracy degrades. A dedicated pass with 2 judgments per row (linguistic + separation) produces deterministic results.

---

## Open Questions

- Should the `[TC-*]` anchor vocabulary be fixed (same anchors for every PRD) or flexible (writer generates anchors per initiative)?
  - **Recommendation**: Fixed vocabulary for cross-cutting sections (TC-DS, TC-QC, TC-EC, TC-RT, TC-CA, TC-FF, TC-CM, TC-LK, TC-VR, TC-SF, TC-MSW), flexible for per-endpoint blocks (TC-AM, TC-RM, TC-UM are initiative-specific).
- Should the reviewer auto-suggest TC anchors when it detects a technical leak, or just flag it?
  - **Recommendation**: Flag with suggested fix — e.g., "FR-009 contains API enum values {cancelled, cancelling}. Move to [TC-AM] and reference as 'cancelled status [TC-AM]'."
