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
mkdir -p .claude/agents .claude/skills/create-prd docs/prd-sections

# Agents
cp path/to/prd-agents-framework/agents/*.md .claude/agents/

# Orchestration skill
cp path/to/prd-agents-framework/skills/create-prd/SKILL.md .claude/skills/create-prd/

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
4. **Ask about custom needs** — custom PRD sections your team always includes, custom research steps for cross-repo checks or external sources
5. **Choose a model profile** — reliable (all Opus) or cost-optimized (Sonnet for mechanical agents, Opus for judgment-heavy ones). See [Model profiles](#model-profiles) below.
6. **Draft `project-context.md`** — you review, resolve any TODOs, confirm

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
        ├── 🔵 Gate 3: You review findings
        └── Up to 3 revision cycles, then escalates
```

Human gates between every phase. Nothing runs without your approval.

### Output

```
docs/initiatives/payment-processing/
├── payment-processing-research.md     # Codebase research (one file, includes custom step results)
├── payment-processing-prd.md          # The PRD
└── payment-processing-prd-review.md   # Review with PASS/FAIL verdicts
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
