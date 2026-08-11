# PRD Agents Framework

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A multi-agent framework for creating, reviewing, and managing Product Requirements Documents using [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Works across tech stacks — Flutter, Spring Boot, React, Node, and more. Supports both existing codebases and greenfield projects.

The framework chains specialized AI agents (researcher, writer, reviewer, senior PM) through a human-gated pipeline, applying structured review techniques from BABOK, perspective-based reading (Basili, 1998), and requirements smell detection (Femmer et al., 2017) to produce implementation-ready specs.

## What's Included

```
prd-agents-framework/
├── agents/
│   ├── project-setup.md       # One-time setup: detects project, drafts config
│   ├── researcher.md          # Codebase research agent
│   ├── prd-writer.md          # PRD drafting agent
│   ├── prd-reviewer.md        # PRD review agent (orchestrates parallel sub-reviewers)
│   ├── prd-senior-pm.md       # Judges the review, decides, writes tickets for the writer
│   └── prd-smell-patterns.md  # Requirements smell patterns (Femmer et al.)
├── skills/
│   └── create-prd/SKILL.md    # Orchestration skill (chains all 4)
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
│   ├── validate-handoff.py     # Schema validator for inter-agent handoff JSON
│   ├── run-log.py              # Safe JSONL run-log writer + timing reader
│   ├── check-docs.py           # Framework self-check: doc-consistency / drift guard
│   ├── banned-terms.txt        # Domain-leakage term list used by check-docs.py
│   └── tests/                  # Fixtures + run-tests.sh for the three PRD scripts
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

### 1. Install the framework — ask Claude

You don't copy files by hand. Open Claude Code in your project (run `git init` first if it's a brand-new directory) and ask:

```
Install the PRD agents framework from
https://github.com/vshidlovsky/prd-agents-framework.git
into this project, following the install map in its README.
Then run the project-setup agent.
```

Claude clones the framework to a temporary location, copies each file per the install map below, and hands off to the setup agent.

#### Install map

This table is the install contract — an installing agent MUST follow it exactly. Two entries **rename the file on copy**; do not miss them.

| Framework source | Project destination | Note |
|---|---|---|
| `agents/*.md` | `.claude/agents/` | |
| `skills/create-prd/SKILL.md` | `.claude/skills/create-prd/SKILL.md` | |
| `rules/*.md` | `.claude/rules/` | Enforced across all agents and conversations |
| `templates/prd-base.md` | `docs/prd-base-template.md` | **Renamed on copy** |
| `templates/sections/*.md` | `docs/prd-sections/` | |
| `project-context.md` | `.claude/project-context.md` | **Moves under `.claude/` on copy** |
| `scripts/*.py` | `scripts/` | Stdlib-only Python 3.9+; agents call these exact paths |

Do NOT copy: `README.md`, `LICENSE`, `scripts/tests/`, `scripts/check-docs.py`, `scripts/banned-terms.txt`, `.github/` — those belong to the framework repo itself, not to consuming projects.

The script destinations matter: `scripts/prd-lint.py`, `scripts/validate-handoff.py`, and `scripts/run-log.py` are the paths the writer, reviewer, and `/create-prd` skill invoke. Every caller checks for the file first and falls back to its manual behavior when it's missing, so the scripts are opt-in. See [PRD lint](#prd-lint) and [Handoff validation and run logging](#handoff-validation-and-run-logging).

### 2. Answer the setup agent

The install prompt above ends by running the project-setup agent (or ask separately: "Run the project-setup agent"). The setup agent will:

1. **Scan your repo** — reads package.json, CLAUDE.md, README, directory structure (skips git history)
2. **Ask about your API docs** — "Where are your API docs?" You provide file paths, URLs, or say "none yet". It verifies each source and creates `docs/api-sources.md`.
3. **Recommend section packs** — enables the right packs based on your project type (frontend, backend, mobile, fintech)
4. **Seed the domain glossary** — scans the codebase for domain-specific terms (model classes, feature flags, API entities), presents candidates with best-guess definitions, and asks you to confirm, edit, or add terms. You can skip this and grow the glossary through PRD runs instead.
5. **Ask about custom needs** — custom PRD sections your team always includes, custom research steps for cross-repo checks or external sources
6. **Choose a model profile** — reliable (all Opus) or cost-optimized (Sonnet for mechanical agents, Opus for judgment-heavy ones). See [Model profiles](#model-profiles) below.
7. **Draft `project-context.md`** — you review, resolve any TODOs, confirm

For **greenfield projects** with no code yet: tell the setup agent your planned tech stack, conventions, and any existing specs or design docs. It will configure the framework based on your plans. The researcher will scan whatever docs exist; if there's no code, it produces a minimal research doc and the PRD writer works from your requirements directly.

### 3. Start writing PRDs

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
    ├── Phase 3: PRD Reviewer
    │   ├── Runs universal + project-specific checks
    │   └── Produces {initiative}-prd-review.md
    │
    └── Phase 3.5: Senior PM
        ├── Judges every FAIL on evidence + impact, collapses duplicates
        ├── Decides the product questions, rejects the noise
        ├── Produces {initiative}-senior-pm-review.md (tickets for the writer)
        ├── 🔵 Gate 3: You review decisions + escalations + approve lessons & glossary terms
        └── Up to 3 revision cycles (writer applies tickets), then escalates
```

Human gates between every phase. Nothing runs without your approval.

The senior PM sits between the reviewer and the writer on purpose: **reviewer → senior PM → Gate 3 → writer**. See [Senior PM judgment](#senior-pm-judgment).

### Output

```
docs/initiatives/search-filters/
├── search-filters-prd.md              # The PRD (only deliverable at root)
└── _artifacts/
    ├── search-filters-research.md     # Codebase research
    ├── search-filters-prd-review.md   # Review with PASS/FAIL verdicts
    ├── search-filters-senior-pm-review.md  # Dispositions, decisions, tickets
    ├── search-filters-prd-handoff.json
    ├── search-filters-prd-review-handoff.json
    └── search-filters-senior-pm-handoff.json
```

All agents commit their output. Nothing is pushed automatically.

### Individual agents (manual control)

```
Run the researcher agent on "search-filters"
Run the prd-writer agent on "search-filters"
Run the prd-reviewer agent on "search-filters"
Run the prd-senior-pm agent on "search-filters"
```

Each agent reads `.claude/project-context.md` on every run.

### Senior PM judgment

The reviewer is a mechanical checker. On a large PRD it fills hundreds of matrix cells and can emit 90+ FAILs, and those FAILs used to go straight to the writer, which caused two problems: reviewer noise became work (many FAILs are variance, overreach, or the same root cause seen from four matrices), and product decisions got invented (a FAIL like "no attempt cap defined" needs a PM call, so the writer made one up and speculation became spec).

`agents/prd-senior-pm.md` is the judgment layer between them. It runs on `fable` — the highest-judgment tier — and reads the PRD, the full review, the research doc, and the writer's Q&A log. It collapses FAIL cells that share one root cause into a single finding, judges each finding on **two axes** (is it real, given the evidence? and does it matter, to users or to API consumers, downstream services, data correctness, and operations?), and judges the reviewer's *suggested fix* the same way — a technically-valid FAIL whose fix would make things worse gets a different fix, or gets rejected with the reasoning recorded. It then challenges the PRD as a product in its own right, decides the product questions from evidence, and writes tickets.

Every finding gets exactly one disposition:

| Disposition | Meaning | What the writer gets |
|---|---|---|
| `fix-technical` | Real, mechanical | A precise instruction: what to change, where |
| `fix-product` | Real, needs a decision — the decision is made here | The decided behavior + a one-line rationale + evidence |
| `reject` | Not real, overreach, variance, or the fix would make it worse | Nothing. The review row is overridden, with the reason recorded |
| `escalate` | Cannot be grounded in any evidence; the owner must decide | A question with the agent's recommendation — rare by design (a sanity bound flags >5 as under-deciding) |

**Full vs delta mode.** Full mode runs once, after the first review pass: judge everything, challenge the product, decide, ticket. Every later pass — including a final `READY` pass — runs in delta mode: verify each earlier ticket actually landed, judge only the FAILs that are new, and leave earlier dispositions alone. Decide once, then enforce; a fresh full judgment every cycle produces fresh opinions every cycle and the PRD never stabilizes.

Everything it produces is a proposal you see at Gate 3 — disposition counts, the decisions with their rationale, the rejected FAILs with reasons, and the escalations as the only questions. You can answer the escalations, veto or override any disposition, or say "go". The agent never edits the PRD, the review, the lessons, the glossary, or the catalogs, and its "tickets" are internal artifacts only — it never touches GitHub issues, Jira, or any external tracker.

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

Regression tests live in `scripts/tests/`: `bash scripts/tests/run-tests.sh` lints the fixtures and asserts that a clean PRD reports zero violations and that each annotated violation fires with the expected check ID on the expected line. The same run covers the handoff validator and the run-log writer.

### Handoff validation and run logging

Agents hand state to each other through JSON files in `_artifacts/`, and the pipeline records each phase as a line of JSONL. Both were plumbing held together by convention: nothing checked a handoff's shape, and the run log was assembled by `echo`-ing JSON inside bash, which an initiative name containing a quote or `$(…)` could corrupt or execute. Two scripts close that gap.

**`scripts/validate-handoff.py`** validates a handoff against the shape documented in the agent that writes it:

```bash
python3 scripts/validate-handoff.py --type writer    docs/.../_artifacts/search-filters-prd-handoff.json
python3 scripts/validate-handoff.py --type reviewer  docs/.../_artifacts/search-filters-prd-review-handoff.json
python3 scripts/validate-handoff.py --type dispatch  docs/.../_artifacts/search-filters-review-dispatch.json
python3 scripts/validate-handoff.py --type senior-pm docs/.../_artifacts/search-filters-senior-pm-handoff.json
```

Exit `0` valid, `1` invalid, `2` usage error. Output is one line per problem: `<field-path>: <problem>`. Beyond per-field types it enforces the invariants the agent docs state in prose — `totalCells == subAgentCells + orchestratorCells`, no midnight timestamp, all twelve `failsByMatrix` keys, `nextAgent` agreeing with `status`, exactly the five sub-reviewer keys in the dispatch file's `models`/`promptFiles`/`outputFiles` (a dropped key there silently loses a whole sub-reviewer), and — for `senior-pm` — `dispositionCounts` agreeing with the `tickets`/`rejectedFails`/`escalations` arrays, every ticket typed `technical` or `product`, `fix-product` tickets carrying a decision, `ticketsVerified` present exactly in `delta` mode, and `nextAgent` agreeing with the ticket count. It is called at five points: the writer after Step 6, the reviewer after Step 9, the reviewer at Step 3 before consuming the writer's handoff, the senior PM after Step 7, and `/create-prd` at steps 3.2 and 3.5.3.

**`scripts/run-log.py`** builds run-log lines with `json.dumps` instead of shell string concatenation, and reads the pipeline timing file so the skill doesn't parse it with shell loops:

```bash
python3 scripts/run-log.py append --log-file .claude/prd-run-log.jsonl --entry-type writer \
  --field "runId=$RUN_ID" --field 'initiative=filters ("v2")' --field 'metrics={"frCount":18}'

python3 scripts/run-log.py timing --file "$TIMING_FILE" --get pipeline_start --iso
python3 scripts/run-log.py timing --file "$TIMING_FILE" --delta writing_start writing_end
```

`--field` values that parse as JSON stay JSON (so nested `metrics` objects survive); everything else is a literal string, escaped on the way out. Missing required fields for the entry type are warnings on stderr and the line is still written — `--strict` turns them into an exit-1 refusal. The **JSONL Schema Reference** section in `skills/create-prd/SKILL.md` remains the contract for entry shapes, and every call site documents the `echo`-based fallback for projects that didn't copy the script in.

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

The framework runs the agents in the Model Profile table, one pass per PRD. Each can use a different model independently — valid values are `opus`, `sonnet`, `haiku`, and `fable`. Three presets are available:

| Profile | Sonnet agents | Opus agents | Fable agents | Cost savings |
|---------|--------------|-------------|--------------|--------------|
| **reliable** | none | every agent except prd-senior-pm | prd-senior-pm | — |
| **cost-optimized** | researcher, review-api, review-structure | prd-writer, prd-reviewer, review-flow, review-requirements, review-smells | prd-senior-pm | ~40-50% |
| **custom** | you pick | you pick | you pick | varies |

The Model Profile table lists one row per agent, including `prd-senior-pm | fable`. The cost-optimized preset keeps Opus where judgment matters most — PRD synthesis, requirements quality (atomicity, feasibility, contradictions), smell detection, flow analysis, and cross-matrix verdicts — while switching mechanical agents (file reading, endpoint comparison, checklist verification) to Sonnet. `prd-senior-pm` stays on `fable` in both presets: judging which FAILs are real and making the product calls *is* the agent, so a cheaper tier there puts invented behavior back into the spec.

The profile is stored in the **Model Profile** table in `project-context.md`. Change it anytime by editing the table directly — no re-setup needed. Model values are tier names resolved by Claude Code (`opus`, `sonnet`, `haiku`, `fable`), not pinned model IDs — they track the current generation automatically.

`fable` — highest-judgment tier; default for `prd-senior-pm`; overkill for mechanical agents.

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
- Access to the Claude model tiers you assign — `opus`, `sonnet`, `haiku`, or `fable` (configurable per agent via [model profiles](#model-profiles))

## Contributing

Issues and PRs welcome. If you adapt the framework to a new tech stack or add section packs, consider contributing them back.

**CI**: PRs run doc-consistency checks — run `python3 scripts/check-docs.py` locally before pushing.

The framework is documentation, and every enumeration in it is maintained by hand — smell counts, Matrix F rows, the file tree above, the section-pack registry. `scripts/check-docs.py` is the regression guard for that drift. Stdlib-only Python 3.9+, no arguments needed. Exit `0` clean, `1` findings, `2` usage error; one line per finding: `<CHECK-ID> <file>:<line> <message>`.

| ID | Check |
|----|-------|
| DOC-001 | Every backticked repo-relative path in a markdown file exists; every file named in the README file tree exists; every markdown file under `agents/ rules/ templates/ skills/` appears in that tree |
| DOC-002 | Smell counts restated in `agents/prd-reviewer.md` and this README match the bullet counts in `agents/prd-smell-patterns.md` |
| DOC-003 | Every `F-<n>` the reviewer references has a Matrix F scaffold row; every `Matrix <X>` referenced has a definition |
| DOC-004 | Every in-page `](#anchor)` link in this README resolves to a heading |
| DOC-005 | Every section pack has an `Insert into` tag with a position; every pack listed in `project-context.md` exists on disk; every pack on disk has a Matrix G check definition |
| DOC-006 | No consuming-project vocabulary in framework docs — a term list guards against domain leakage into "generic" examples |
| DOC-007 | No orphan rule files (each is referenced by an agent, template, or skill), and every `rules/…` reference resolves |

`scripts/banned-terms.txt` holds the DOC-006 term list: one term per line, `#` comments, and `term :: path` to exempt a file where a term is legitimate. It scans the authored doc surface (`agents/`, `rules/`, `templates/`, `skills/`, `project-context.md`, `README.md`) and deliberately skips `scripts/tests/fixtures/`, whose fixtures contain bad examples on purpose. Add a term whenever you notice a consuming project's product name, endpoint path, enum value, or repo name in a framework example.

Run `bash scripts/tests/run-tests.sh` too — it covers `prd-lint.py`, `validate-handoff.py`, and `run-log.py`. CI runs both, plus `python3 -m py_compile scripts/*.py`.

## License

[MIT](LICENSE)
