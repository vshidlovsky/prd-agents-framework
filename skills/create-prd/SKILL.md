---
name: create-prd
description: Full PRD creation pipeline — research, draft, and review with human gates between phases. Chains researcher → prd-writer → prd-reviewer agents.
argument-hint: <initiative-name>
---

# PRD Creation Pipeline

Run the full PRD workflow for `{argument}`.

## Pre-flight

1. Read `.claude/project-context.md` — confirm it exists and is filled in. If it doesn't exist, STOP and tell the user: "You need to set up `.claude/project-context.md` first. Copy the template from the framework and fill it in for your project."
2. Confirm the initiative directory exists or create it at the output path specified in project-context.md.

### Handoff file naming convention

All agents use this naming pattern — files go in the same directory as the PRD:
- Writer handoff: `{initiative}-prd-handoff.json`
- Reviewer handoff: `{initiative}-prd-review-handoff.json` (or `{initiative}-prd-review-v{N}-handoff.json` if versioned)

These names are stable across revision cycles. The reviewer reads the writer's handoff by this name. Neither agent overwrites the other's file.

## Phase 1: Research

Spawn an Agent using the prompt from `.claude/agents/researcher.md`:
- Pass `{argument}` as the INITIATIVE
- Let it scan the codebase (or docs/specs for greenfield) and produce a research document

The researcher will detect whether this is a greenfield project (no source code) or an existing codebase and adjust its approach automatically.

### Gate 1: Research Review

Present the research findings to the user as a summary:
- Modules/packages involved (or "greenfield — no code yet")
- Key API endpoints found
- Business logic discovered
- Any flagged inconsistencies or ambiguities

Ask: **"Review the research above. Say 'continue' to proceed to PRD drafting, or provide feedback to adjust the research."**

For greenfield projects, also ask: **"Since there's no existing code, do you have requirements, specs, or design docs you'd like me to reference during PRD drafting?"**

If feedback is given, send it back to the researcher agent for revision. Repeat until the user says "continue."

## Phase 2: PRD Drafting (max 3 revision cycles)

Spawn an Agent using the prompt from `.claude/agents/prd-writer.md`:
- Pass `{argument}` as the initiative name
- Pass the research document path as context

The prd-writer will:
1. Read the research
2. Ask clarifying questions (this is a human gate — wait for answers)
3. Draft the PRD
4. Write the handoff file

### Gate 2: PRD Draft Review

Tell the user: **"PRD draft is ready at `{prd_path}`. Review it, then say 'continue' to run the reviewer, or provide feedback for revisions."**

If feedback is given, send it back to the prd-writer for revision. Repeat until the user says "continue."

## Phase 3: PRD Review (max 3 revision cycles)

Track the revision count starting at 0.

Spawn an Agent using the prompt from `.claude/agents/prd-reviewer.md`:
- Pass `{argument}` as the initiative name
- It will find and read the latest PRD and handoff file

### Gate 3: Review Results + Proposed Lessons

Present the review verdict AND proposed lessons together in one output:

**First**, the verdict:
- If **READY**: "PRD approved with all checks passing."
- If **NEEDS_REVISION**: Present every FAIL item with its description.

**Then**, immediately show proposed lessons (if any). For each lesson, show:
- Number, name
- What was caught
- Writer rule (prevention)
- Reviewer check (detection)

If no lessons were proposed, say "No new lessons proposed."

**Then**, ask for action — one prompt covering both verdict and lessons:
- If READY: **"Approve lessons: all / specific (e.g., '1 and 3') / skip all. Then we're done."**
- If NEEDS_REVISION: **"For the review: 'revise' to send back to prd-writer, or 'override' to approve as-is. For the lessons: all / specific / skip."**

On lesson approval, spawn a new Agent using `.claude/agents/prd-reviewer.md` with the prompt: "Run only Step 12. Write these approved lessons to `.claude/prd-lessons.md`: [list the approved lesson names and their content from the review file]. The review file is at {review_path}." This is a targeted callback — the agent reads the review, extracts the approved lessons, and appends them to the lessons file.

If "revise": increment the revision count.
  - If revision count < 3: spawn a new prd-writer agent with the prompt: "This is a revision cycle. Read the existing PRD at {prd_path} and the review at {review_path}. Follow Step 3.5 (Revision Mode) — fix each FAIL in the review's Issues Found list. Do not rewrite the entire PRD." The writer's Step 3.5 handles versioning, targeted fixes, and handoff.
  - If revision count = 3: tell the user: **"This PRD has gone through 3 revision cycles and still has FAILs. Remaining issues: [list]. Options: 'override' to approve as-is, 'continue' to try one more cycle, or 'stop' to pause and resolve issues manually."**
If "override": mark as approved and end.

## Completion

Summarize what was produced:
- Research document path
- PRD path (with version)
- Review path
- Handoff file paths
- Final verdict
- Lessons added (if any)
