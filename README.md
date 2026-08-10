# PRD Agents Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A multi-agent framework for creating, reviewing, and managing Product Requirements Documents using [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Works across tech stacks — Flutter, Spring Boot, React, Node, and more. Supports both existing codebases and greenfield projects.

The framework chains specialized AI agents (researcher, writer, reviewer) through a human-gated pipeline, applying structured review techniques from BABOK, perspective-based reading (Basili, 1998), and requirements smell detection (Femmer et al., 2017) to produce implementation-ready specs.

## What's Included

```
prd-agents-framework/
├── agents/
│   ├── project-setup.md       # One-time setup: detects project, drafts config
│   ├── researcher.md          # Codebase research agent
│   ├── prd-writer.md          # PRD drafting agent
│   ├── prd-reviewer.md        # PRD review agent (orchestrates parallel sub-reviewers)
│   └── prd-smell-patterns.md  # Requirements smell patterns (Femmer et al.)
├── skills/
│   └── create-prd/SKILL.md    # Orchestration skill (chains all 3)
├── templates/
│   ├── prd-base.md            # Universal PRD template (always used)
│   └── sections/              # Modular section packs (pick what applies)
│       ├── screen-flow.md
│       ├── navigation.md
│       ├── analytics-events.md
│       ├── component-mapping.md
│       ├── feature-flags.md
│       ├── accessibility.md
│       ├── design-prototype.md
│       ├── user-journey.md
│       ├── responsive-layout.md
│       ├── database-changes.md
│       ├── service-integration.md
│       ├── monitoring.md
│       ├── compliance.md
│       ├── platform-considerations.md
│       ├── performance.md
│       ├── capacity-constraints.md
│       ├── rollback-degradation.md
│       └── state-migration.md
├── scripts/
│   ├── prd-lint.py             # Deterministic linter for mechanical PRD/review rules
│   └── tests/                  # Fixtures + run-tests.sh for the linter
├── rules/
│   ├── behavioral-separation.md # Rule: behavioral/technical contract separation
│   ├── prd-lessons.md          # Rule: no lessons written without user approval
│   ├── lesson-lifecycle.md     # Lesson statuses + graduation workflow
│   ├── domain-glossary.md      # Rule: no glossary terms written without user approval
│   ├── semantic-vocabulary.md  # Rule: no vocabulary entries written without user approval
│   └── shared-requirements.md  # Rule: no SRs modified without user approval
├── project-context.md          # Template — copied to your project during setup
└── README.md
```

## Getting Started (~15 minutes)

### 1. Initialize your project repo

If you don't have a repo yet:

```bash
mkdir my-project && cd my-project
git init
```

If you have an existing project, just `cd` into it.

### 2. Copy framework files

```bash
# From your project root:
mkdir -p .claude/agents .claude/skills/create-prd .claude/rules docs/prd-sections scripts

# Agents
cp path/to/prd-agents-framework/agents/*.md .claude/agents/

# Orchestration skill
cp path/to/prd-agents-framework/skills/create-prd/SKILL.md .claude/skills/create-prd/

# Rules (enforced across all agents and conversations)
cp path/to/prd-agents-framework/rules/*.md .claude/rules/

# PRD template + section packs
cp path/to/prd-agents-framework/templates/prd-base.md docs/prd-base-template.md
cp path/to/prd-agents-framework/templates/sections/*.md docs/prd-sections/

# Project context template
cp path/to/prd-agents-framework/project-context.md .claude/project-context.md

# Deterministic PRD linter (stdlib-only Python 3.9+; the agents call it at scripts/prd-lint.py)
cp path/to/prd-agents-framework/scripts/*.py scripts/
```

The linter's target location in your project is `scripts/prd-lint.py` — that's the path the writer, reviewer, and `/create-prd` skill invoke. See [PRD lint](#prd-lint).

### 3. Run the project-setup agent

```
Run the project-setup agent
```

The setup agent will:

1. **Scan your repo** — reads package.json, CLAUDE.md, README, directory structure (skips git history)
2. **Ask about your API docs** — "Where are your API docs?" You provide file paths, URLs, or say "none yet". It verifies each source and creates `docs/api-sources.md`.
3. **Recommend section packs** — enables the right packs based on your project type (frontend, backend, mobile, fintech)
4. **Seed the domain glossary** — scans the codebase for domain-specific terms (model classes, feature flags, API entities), presents candidates with best-guess definitions, and asks you to confirm, edit, or add terms. You can skip this and grow the glossary through PRD runs instead.
5. **Ask about custom needs** — custom PRD sections your team always includes, custom research steps for cross-repo checks or external sources
6. **Choose a model profile** — reliable (all Opus) or cost-optimized (Sonnet for mechanical agents, Opus for judgment-heavy ones). See [Model profiles](#model-profiles) below.
7. **Draft `project-context.md`** — you review, resolve any TODOs, confirm

For **greenfield projects** with no code yet: tell the setup agent your planned tech stack, conventions, and any existing specs or design docs. It will configure the framework based on your plans. The researcher will scan whatever docs exist; if there's no code, it produces a minimal research doc and the PRD writer works from your requirements directly.

### 4. Start writing PRDs

```
/create-prd search-filters
```

## How It Works

### Pipeline

```
/create-prd {initiative}
    │
    ├── Phase 1: Researcher
    │   ├── Scans codebase (or docs for greenfield)
    │   ├── Runs custom research steps
    │   ├── Produces {initiative}-research.md
    │   └── 🔵 Gate 1: You review research
    │
    ├── Phase 2: PRD Writer
    │   ├── Reads research + template + section packs
    │   ├── Produces {initiative}-prd.md
    │   └── 🔵 Gate 2: You review draft
    │
    └── Phase 3: PRD Reviewer
        ├── Runs universal + project-specific checks
        ├── Produces {initiative}-prd-review.md
        ├── 🔵 Gate 3: You review findings + approve lessons & glossary terms
        └── Up to 3 revision cycles, then escalates
```

Human gates between every phase. Nothing runs without your approval.

### Output

```
docs/initiatives/search-filters/
├── search-filters-prd.md              # The PRD (only deliverable at root)
└── _artifacts/
    ├── search-filters-research.md     # Codebase research
    ├── search-filters-prd-review.md   # Review with PASS/FAIL verdicts
    ├── search-filters-prd-handoff.json
    └── search-filters-prd-review-handoff.json
```

All agents commit their output. Nothing is pushed automatically.

### Individual agents (manual control)

```
Run the researcher agent on "search-filters"
Run the prd-writer agent on "search-filters"
Run the prd-reviewer agent on "search-filters"
```

Each agent reads `.claude/project-context.md` on every run.

## Customization

### Section packs

Section packs are modular PRD sections. Enable them with checkboxes in `project-context.md`:

```markdown
### Included Section Packs
- [x] screen-flow — Mermaid screen flow diagrams
- [x] navigation — Entry points, back behavior, deep links
- [ ] database-changes — DB schema changes (not needed for this project)
```

Create **custom section packs** for project-specific needs (e.g., mobile-app discrepancy tracking, mock data strategy). The project-setup agent helps you create these.

### PRD lint

`scripts/prd-lint.py` is the framework's deterministic enforcement layer: the subset of PRD rules that are mechanically checkable, enforced by a script instead of a prompt. Prompt-level discipline ("the agent MUST grep…") is probabilistic — a script can't forget.

```bash
python3 scripts/prd-lint.py docs/initiatives/search-filters/search-filters-prd.md
python3 scripts/prd-lint.py docs/.../search-filters-prd-review.md --mode review
python3 scripts/prd-lint.py <file> --format json    # machine-readable
```

Stdlib-only Python 3.9+, single file, no dependencies. Exit `0` clean, `1` violations, `2` usage error. Output is one line per violation: `<CHECK-ID> <line> <message>`.

| Mode | Checks |
|------|--------|
| `prd` (default) | dangling/duplicate `[V#]` markers (LINT-001), unchecked writer-confirmation checkboxes (LINT-002), branch-name citation URLs that aren't commit-pinned (LINT-003), changelog version ordering (LINT-004), leftover `OQ-` items (LINT-005), leftover `> **GUIDE**` blocks (LINT-006), raw analytics event names in ACs and `AE-<n>` rows bound by zero ACs (LINT-007), wire-value leaks into FRs/ACs/Edge Cases (LINT-008), renamed top-level sections (LINT-009) |
| `review` | leftover `[PENDING]` cells (LINT-101), invalid verdict tokens such as `WARN`/`INFO` (LINT-102), `TOTAL_CELLS`/`SUB_AGENT_CELLS`/`ORCHESTRATOR_CELLS` present, integer, and summing correctly (LINT-103) |

The agents call it automatically when the file is present: the writer at Step 4.5 (before saving), the reviewer at step 8.1.2 (PRD violations become Matrix I FAIL rows; review-file violations are fixed in place), and `/create-prd` before Gate 2 (violations surface with the draft notice). If the file is absent, every caller falls back to its manual scans — copying it in is opt-in.

Regression tests live in `scripts/tests/`: `bash scripts/tests/run-tests.sh` lints the fixtures and asserts that a clean PRD reports zero violations and that each annotated violation fires with the expected check ID on the expected line.

### Lessons learned

`.claude/prd-lessons.md` is your project's memory of past review failures: each lesson carries a **Writer rule** the writer follows while drafting and a **Reviewer check** that becomes a row in the reviewer's Lesson Checks matrix (Matrix H). Lessons grow through the propose→approve flow — the reviewer proposes a lesson for each new failure pattern in the review document, the orchestrator presents the proposals at Gate 3, and only lessons you explicitly approve are appended; no agent ever writes to the file on its own (`rules/prd-lessons.md`). Every approved lesson also records two lifecycle fields: **Applies when** (a PRD-observable condition, or `always`) and **Status** (`active`, `superseded-by: L-NNN`, or `graduated: <ref>`). The reviewer skips superseded and graduated lessons entirely, and marks a row `N/A — condition not met` when an active lesson's condition doesn't hold — so review cost tracks the lessons that actually apply, not the size of the corpus. Lessons written before these fields existed are treated as `active` + `always`, so nothing needs backfilling.

Periodically the corpus should be pruned: project-agnostic lessons **graduate** into the framework itself and stop costing you a Matrix H row on every PRD. See **`rules/lesson-lifecycle.md`** for when to review the corpus, the genericity test, where graduated rules land, and how to retire the project lesson afterward.

### Domain glossary

The **Domain Glossary** in `project-context.md` defines business terms that agents must use correctly. It's read by the writer before every PRD (Step 0) and checked by the reviewer for consistency.

**Seeding**: The project-setup agent scans your codebase for domain-specific terms and asks you to confirm definitions. You can also skip this and start with an empty glossary.

**Growth**: The glossary grows through PRD runs. The writer proposes terms it needed but couldn't find during drafting. The reviewer proposes terms used inconsistently or incorrectly in the PRD. At Gate 3, the orchestrator presents both sets of proposals and you choose which to accept. No agent writes to the glossary without your explicit approval (`rules/domain-glossary.md`).

This is the same approval pattern used for [lessons learned](#lessons-learned) — propose, present, approve.

### Shared requirements

**Shared requirements** (`docs/shared-requirements.md`) are cross-cutting rules — authentication guards, error handling patterns, accessibility standards, security rules — that every PRD inherits by reference instead of restating inline. This prevents duplication, drift, and contradictions across PRDs.

**Seeding**: The project-setup agent scans CLAUDE.md and rules files for "every page MUST..." patterns, presents candidates, and creates the file with your approved SRs. Optional — skip if you don't have cross-cutting rules yet.

**In PRDs**: The writer adds a "Shared Requirements" section listing applicable SR IDs and any feature-specific overrides with justification. The reviewer verifies: SR section present (F-22), no SR content restated inline (F-23), overrides justified (F-24).

**Ownership**: PM-owned. Agents reference and verify SRs but never add, modify, or remove them without your approval (`rules/shared-requirements.md`).

### Custom research steps

Add project-specific research steps in `docs/research-steps/`. Each step tells the researcher to check an additional source (sibling repo, external API registry, compliance database) and append results as a section in the research doc.

### Project-specific review checks

Add domain-specific review rules under **Project-Specific Review Checks** in `project-context.md`. One table per check:

```markdown
#### Data Integrity
| # | Check Item |
|---|-----------|
| 1 | All numeric fields use appropriate precision (no floating-point for exact values) |
| 2 | Every mutation has an idempotency key |
| 3 | No optimistic updates on critical mutations |
```

### Model profiles

The framework runs the agents in the Model Profile table, one pass per PRD. Each can use a different model independently — valid values are `opus`, `sonnet`, and `haiku`. Three presets are available:

| Profile | Sonnet agents | Opus agents | Cost savings |
|---------|--------------|-------------|--------------|
| **reliable** | none | all agents | — |
| **cost-optimized** | researcher, review-api, review-structure | prd-writer, prd-reviewer, review-flow, review-requirements, review-smells | ~40-50% |
| **custom** | you pick | you pick | varies |

The cost-optimized preset keeps Opus where judgment matters most — PRD synthesis, requirements quality (atomicity, feasibility, contradictions), smell detection, flow analysis, and cross-matrix verdicts — while switching mechanical agents (file reading, endpoint comparison, checklist verification) to Sonnet.

The profile is stored in the **Model Profile** table in `project-context.md`. Change it anytime by editing the table directly — no re-setup needed. Model values are tier names resolved by Claude Code (`opus`, `sonnet`, `haiku`), not pinned model IDs — they track the current generation automatically.

`haiku` is accepted for custom profiles. It is only appropriate for strictly mechanical work (e.g., review-structure checklist verification on small PRDs). Judgment-heavy agents (prd-writer, prd-reviewer, review-flow, review-requirements, review-smells) should stay on opus. Quality degradation on review agents shows up as false PASSes, which are invisible — prefer over-provisioning reviewers.

### Run logs & model comparison

Each `/create-prd` run produces a JSON run log capturing:
- **Timing** — per-phase and per-sub-agent durations, with human gate wait time separated from agent work time. Review phase breaks down into scaffold, sub-agent dispatch (with individual agent times), and assembly.
- **Models used** — the full model map for that run
- **Quality metrics** — verdict, FAIL count broken down by matrix (A through P), defect taxonomy, smell detection stats (total checked vs found), spot-check overrides, revision cycles

Run logs accumulate in `docs/initiatives/{initiative}/runs/`. To compare model profiles:

1. Run `/create-prd my-feature` with the **reliable** profile
2. Edit `project-context.md` to switch to **cost-optimized**
3. Run `/create-prd my-feature` again
4. Compare the two run log JSONs — did the cheaper profile miss FAILs? How much faster was it?

Token usage is not captured programmatically — correlate with your Anthropic dashboard for the session time window. Run logging is enabled by default; set `Enabled: no` under **Run Logs** in `project-context.md` to skip it.

### API documentation

The framework uses `docs/api-sources.md` as the index of all API documentation sources. The project-setup agent creates this by asking you where your API docs are. The researcher reads it to find API contracts and refuses to proceed if it doesn't exist.

## Research Background

The reviewer agent incorporates techniques from requirements engineering research:

- **Perspective-Based Reading** (Basili et al., University of Maryland, 1998) — reviews each screen/flow from end-user, QA, and support perspectives to catch different defect classes
- **Requirements Smell Detection** (Femmer et al., TU Munich, 2017 — adapted and extended) — scans FR and AC text for 10 linguistic anti-patterns (vague verbs, loopholes, ambiguous pronouns, passive voice, open-ended lists, superlatives, incomplete conditionals, subjective language, temporal comparisons, implementation delegation)
- **Defect Taxonomy Cross-Check** (derived from NASA/IBM defect classification) — categorizes findings into 6 defect types and does a second pass on any category with zero findings to catch blind spots
- **BABOK Verification Techniques** — requirement quality characteristics (atomic, necessary, feasible, consistent) applied as matrix columns

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI or IDE extension
- Access to the Claude model tiers you assign — `opus`, `sonnet`, or `haiku` (configurable per agent via [model profiles](#model-profiles))

## Contributing

Issues and PRs welcome. If you adapt the framework to a new tech stack or add section packs, consider contributing them back.

## License

[MIT](LICENSE)
