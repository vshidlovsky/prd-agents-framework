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

## Phase 0: Scope Clarification

Before spending time on research, analyze the initiative brief (`{argument}`) for ambiguity. Ask the user **2-4 framing questions** to lock down scope before the researcher starts. This prevents misdirected research.

Focus on:
- **Ambiguous terms**: Does the initiative name map to one specific feature, or could it mean multiple things? (e.g., "payment processing" could mean adding a new payment method, building the processing pipeline, or adding transaction history)
- **Scope boundaries**: Is this a full feature or a slice? New build or extension of existing behavior?
- **Target users/systems**: Who or what is this for? (e.g., end users, internal ops, another service)

**Format**: Present each question with your best guess based on the initiative name and what you know about the project from project-context.md:
> "Before I research, a few quick scope questions:
> 1. 'Payment processing' — does this mean (a) adding a new payment method to the existing checkout, (b) building the backend processing pipeline, or (c) both? I'm guessing (a) based on the project type.
> 2. Is this for all users or a specific segment?

If the user provides a detailed brief (more than 2 sentences with clear scope), you may skip this phase — the brief itself answers the framing questions. Say: **"Your brief is clear on scope — moving straight to research."**

Pass the clarified scope to the researcher so it knows exactly what to focus on.

## Phase 1: Research

Spawn an Agent using the prompt from `.claude/agents/researcher.md`:
- Pass `{argument}` as the INITIATIVE
- Pass the clarified scope from Phase 0 (if any) as additional context
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

### Step 3.1: Scaffold (reviewer Phase 1)

Spawn an Agent using `.claude/agents/prd-reviewer.md` with the prompt:

> "Run Phase 1 only for initiative '{argument}'. Write the scaffold, determine review mode. If single mode (< 20 items), fill all matrices yourself and complete the full review (Steps 0-12). If parallel mode (>= 20 items), write the scaffold, construct sub-agent prompt files, write the dispatch JSON, then STOP."

### Step 3.2: Check review mode

After the reviewer returns, check if a dispatch file exists:
```bash
cat {initiative_dir}/{argument}-review-dispatch.json 2>/dev/null
```

- **If no dispatch file**: the reviewer completed in single-agent mode. The review file and handoff are done. Skip to Gate 3.
- **If dispatch file exists**: read it. Proceed to Step 3.3.

### Step 3.3: Dispatch sub-reviewers (parallel)

First, verify all four prompt files from the dispatch JSON exist:
```bash
for f in "{promptFiles.api}" "{promptFiles.structure}" "{promptFiles.flow}" "{promptFiles.requirements}"; do
  [ -f "$f" ] || echo "MISSING: $f"
done
```
If any are missing, STOP and tell the user: "Reviewer Phase 1 failed to write all prompt files. Missing: [list]. Re-run the review."

Read each prompt file. Paths in the dispatch JSON are absolute — use them directly, do not join with the initiative directory.

Spawn **all four agents in parallel**, each with `model: opus`:

- Agent 1 (API): read `{promptFiles.api}`, use its content as the agent prompt
- Agent 2 (Structure): read `{promptFiles.structure}`, use its content as the agent prompt
- Agent 3 (Flow): read `{promptFiles.flow}`, use its content as the agent prompt
- Agent 4 (Requirements): read `{promptFiles.requirements}`, use its content as the agent prompt

Wait for all four to complete.

### Step 3.4: Assembly (reviewer Phase 3)

Spawn an Agent using `.claude/agents/prd-reviewer.md` with the prompt:

> "Run Phase 3 only for initiative '{argument}'. Sub-agents have completed. The dispatch file is at {absolute_path_to_dispatch_json}. Re-read project context, lessons, PRD, and scaffold. Assemble sub-agent outputs, fill Matrix H, run completeness verification, spot-check, dynamic findings, defect taxonomy, verdict, and commit."

### Step 3.6: Defensive cleanup

After the reviewer returns from Phase 3, verify the commit succeeded before deleting temporary files. If the commit failed, the reviewer preserves these files as evidence — do not delete them.

```bash
# Only clean up if the reviewer's commit landed
if git log --oneline -1 | grep -q "{argument}.*PRD review"; then
  rm -f {initiative_dir}/*-review-prompt-*.md {initiative_dir}/*-review-dispatch.json
  rm -f {initiative_dir}/*-review-api.md {initiative_dir}/*-review-structure.md {initiative_dir}/*-review-flow.md {initiative_dir}/*-review-requirements.md
else
  echo "WARNING: Review commit not found — keeping sub-agent files for debugging."
fi
```

The reviewer now has the review file and handoff ready.

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
  - If revision count < 3: spawn a new prd-writer agent with the prompt: "This is a revision cycle. Read the existing PRD at {prd_path} and the review at {review_path}. Follow Step 3.5 (Revision Mode) — fix each FAIL in the review's Issues Found list. Do not rewrite the entire PRD." The writer's Step 3.5 handles versioning, targeted fixes, and handoff. **After the writer completes the revision, return to Step 3.1 to re-run the review.**
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
