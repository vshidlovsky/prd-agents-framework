# PRD Pipeline Integrity and Source Policy

## Pipeline integrity

A PRD is produced only through `/create-prd`. The skill holds the order that makes the result trustworthy: review mode, the 3-cycle limit, the human gates, versioned files, the run log, and the writer's record of applied tickets.

- **Never run researcher, prd-writer, prd-reviewer or prd-senior-pm outside `/create-prd`** for a PRD that is meant to ship. To continue an interrupted PRD, run `/create-prd <initiative>` again.
- **The main session never edits a PRD.** Every change after a draft goes through prd-writer (the user's draft feedback at Gate 2, or approved tickets after Gate 3). A hand edit has no changelog row, no new version and no `ticketsApplied` record, so the senior PM cannot verify it.
- **The main session never writes lessons, glossary terms, vocabulary entries or SRs itself.** It passes the user's approval to the approval-gated callback step after Gate 3.
- **The main session never chooses the review mode.** The reviewer decides single or parallel mode from its own item count. A prompt that asks for a lighter mode is ignored.
- **Agents refuse to run outside a pipeline run.** Each pipeline agent checks for the run state file (`{initiative_dir}/_artifacts/.run-state.json`, `status: in_progress`, matching `runId`) and stops without it. When the user explicitly asks for a standalone agent run, the agent may continue, but it stamps its output `STANDALONE — not a pipeline result`. A standalone READY never counts as a finished PRD.

## Source policy

A PRD comes first. Design, delivery tickets and technical designs are produced from it. Feeding them back in makes the PRD copy early drafts instead of deciding the product.

| Allowed sources | Excluded by default (downstream artifacts) |
|---|---|
| The PM's initiative brief and answers to clarifying questions | Design files and drafts (Figma, prototypes, screenshots of unshipped screens) |
| Business requirement pages | Delivery tickets: epics, stories, tasks, spikes (Jira and similar) |
| Shipped code and API documentation, as checked by the researcher | Technical design documents for unbuilt work (PDRs, RFCs, tech specs) |
| Meeting notes | |

- **Intake.** At Phase 0 the orchestrator sorts every link and file the user provides into these two columns and tells the user which ones it excluded and why.
- **Override.** The user may keep an excluded item by naming it and giving a reason. The orchestrator records it in the run state under `sources.overrides`. An overridden item is context only: agents may use it to ask better questions, but never cite it as the source of a requirement and never copy its names, layout or wording.
- **Facts vs plans.** What a downstream artifact says is a plan, not a fact. A behavior counts as existing only when shipped code or API documentation shows it.
- **Found by accident.** A design link or ticket found during research (in code comments, a README, a business page) is not a source either. Note it in the research document as a pointer only.
- **In the PRD.** No design file is cited outside a full-mode Visual References section. No ticket is cited outside Boundaries → Dependencies, where a blocking capability may cite its ticket. `prd-lint` LINT-015 enforces this mechanically.

This rule applies to all agents, skills, and conversations in this project.
