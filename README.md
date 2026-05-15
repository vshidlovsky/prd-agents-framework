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
│       ├── localization.md
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
│       └── platform-considerations.md
├── rules/
│   ├── prd-lessons.md          # Rule: no lessons written without user approval
│   ├── domain-glossary.md      # Rule: no glossary terms written without user approval
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
mkdir -p .claude/agents .claude/skills/create-prd .claude/rules docs/prd-sections

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
```

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
/create-prd payment-processing
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
docs/initiatives/payment-processing/
├── payment-processing-research.md     # Codebase research (one file, includes custom step results)
├── payment-processing-prd.md          # The PRD
├── payment-processing-prd-review.md   # Review with PASS/FAIL verdicts
└── runs/
    └── run-20260513-103000.json       # Run log (timing, models, quality metrics)
```

All agents commit their output. Nothing is pushed automatically.

### Individual agents (manual control)

```
Run the researcher agent on "payment-processing"
Run the prd-writer agent on "payment-processing"
Run the prd-reviewer agent on "payment-processing"
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
#### Financial Safety
| # | Check Item |
|---|-----------|
| 1 | All money fields use integer cents, no floats |
| 2 | Every mutation has an idempotency key |
| 3 | No optimistic updates on financial mutations |
```

### Model profiles

The framework runs 7 agents per PRD. Each can use Opus or Sonnet independently. Three presets are available:

| Profile | Sonnet agents | Opus agents | Cost savings |
|---------|--------------|-------------|--------------|
| **reliable** | none | all 7 | — |
| **cost-optimized** | researcher, review-api, review-structure | prd-writer, prd-reviewer, review-flow, review-requirements | ~40-50% |
| **custom** | you pick | you pick | varies |

The cost-optimized preset keeps Opus where judgment matters most — PRD synthesis, smell detection, flow analysis, and cross-matrix verdicts — while switching mechanical agents (file reading, endpoint comparison, checklist verification) to Sonnet.

The profile is stored in the **Model Profile** table in `project-context.md`. Change it anytime by editing the table directly — no re-setup needed.

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
- **Requirements Smell Detection** (Femmer et al., TU Munich, 2017) — scans FR and AC text for 8 linguistic anti-patterns (vague verbs, loopholes, ambiguous pronouns, passive voice, open-ended lists, superlatives, incomplete conditionals, subjective language)
- **Defect Taxonomy Cross-Check** (derived from NASA/IBM defect classification) — categorizes findings into 6 defect types and does a second pass on any category with zero findings to catch blind spots
- **BABOK Verification Techniques** — requirement quality characteristics (atomic, necessary, feasible, consistent) applied as matrix columns

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI or IDE extension
- Claude Opus or Sonnet model (configurable per agent via [model profiles](#model-profiles))

## Contributing

Issues and PRs welcome. If you adapt the framework to a new tech stack or add section packs, consider contributing them back.

## License

[MIT](LICENSE)
