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
3. Read the **Model Profile** table from project-context.md. Extract the `Model` column for each agent row. Store as `MODEL_MAP` — a lookup from agent name to model (e.g., `researcher → sonnet`, `prd-writer → opus`). If the Model Profile section is missing, default all agents to `opus`.
4. Check if **Run Logs** are enabled in project-context.md. If enabled, initialize the timing file:
   ```bash
   TIMING_FILE="{initiative_dir}/.run-timing.tmp"
   echo "pipeline_start=$(date +%s) $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$TIMING_FILE"
   ```
   Record the profile name (from the `Profile` field in Model Profile) for the run log.

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

If run logging is enabled: `echo "research_start=$(date +%s)" >> "$TIMING_FILE"`

Spawn an Agent using the prompt from `.claude/agents/researcher.md`, with `model: MODEL_MAP[researcher]`:
- Pass `{argument}` as the INITIATIVE
- Pass the clarified scope from Phase 0 (if any) as additional context
- Let it scan the codebase (or docs/specs for greenfield) and produce a research document

The researcher will detect whether this is a greenfield project (no source code) or an existing codebase and adjust its approach automatically.

If run logging is enabled: `echo "research_end=$(date +%s)" >> "$TIMING_FILE"`

### Gate 1: Research Review

If run logging is enabled: `echo "gate1_prompt=$(date +%s)" >> "$TIMING_FILE"`

Present the research findings to the user as a summary:
- Modules/packages involved (or "greenfield — no code yet")
- Key API endpoints found
- Business logic discovered
- Any flagged inconsistencies or ambiguities

Ask: **"Review the research above. Say 'continue' to proceed to PRD drafting, or provide feedback to adjust the research."**

For greenfield projects, also ask: **"Since there's no existing code, do you have requirements, specs, or design docs you'd like me to reference during PRD drafting?"**

If feedback is given, send it back to the researcher agent for revision. Repeat until the user says "continue."

If run logging is enabled: `echo "gate1_resume=$(date +%s)" >> "$TIMING_FILE"`

## Phase 2: PRD Drafting (max 3 revision cycles)

If run logging is enabled: `echo "writing_start=$(date +%s)" >> "$TIMING_FILE"`

Spawn an Agent using the prompt from `.claude/agents/prd-writer.md`, with `model: MODEL_MAP[prd-writer]`:
- Pass `{argument}` as the initiative name
- Pass the research document path as context

The prd-writer will:
1. Read the research
2. Ask clarifying questions (this is a human gate — wait for answers)
3. Draft the PRD
4. Write the handoff file

If run logging is enabled: `echo "writing_end=$(date +%s)" >> "$TIMING_FILE"`

### Gate 2: PRD Draft Review

If run logging is enabled: `echo "gate2_prompt=$(date +%s)" >> "$TIMING_FILE"`

Tell the user: **"PRD draft is ready at `{prd_path}`. Review it, then say 'continue' to run the reviewer, or provide feedback for revisions."**

If feedback is given, send it back to the prd-writer for revision. Repeat until the user says "continue."

If run logging is enabled: `echo "gate2_resume=$(date +%s)" >> "$TIMING_FILE"`

## Phase 3: PRD Review (max 3 revision cycles)

If run logging is enabled: `echo "review_start=$(date +%s)" >> "$TIMING_FILE"`

Track the revision count starting at 0.

### Step 3.1: Scaffold (reviewer Phase 1)

If run logging is enabled: `echo "review_scaffold_start=$(date +%s)" >> "$TIMING_FILE"`

Spawn an Agent using `.claude/agents/prd-reviewer.md`, with `model: MODEL_MAP[prd-reviewer]`, and the prompt:

> "Run Phase 1 only for initiative '{argument}'. Write the scaffold, determine review mode. If single mode (< 20 items), fill all matrices yourself and complete the full review (Steps 0-12). If parallel mode (>= 20 items), write the scaffold, construct sub-agent prompt files, write the dispatch JSON, then STOP."

If run logging is enabled: `echo "review_scaffold_end=$(date +%s)" >> "$TIMING_FILE"`

### Step 3.2: Check review mode

After the reviewer returns, check if a dispatch file exists:
```bash
cat {initiative_dir}/{argument}-review-dispatch.json 2>/dev/null
```

- **If no dispatch file**: the reviewer completed in single-agent mode. The review file and handoff are done. Skip to Gate 3.
- **If dispatch file exists**: read it. The dispatch JSON includes a `models` object with per-agent model assignments — use these for sub-agent dispatch (they match `MODEL_MAP` but are authoritative for this review run). Proceed to Step 3.3.

### Step 3.3: Dispatch sub-reviewers (parallel)

First, verify all four prompt files from the dispatch JSON exist:
```bash
for f in "{promptFiles.api}" "{promptFiles.structure}" "{promptFiles.flow}" "{promptFiles.requirements}"; do
  [ -f "$f" ] || echo "MISSING: $f"
done
```
If any are missing, STOP and tell the user: "Reviewer Phase 1 failed to write all prompt files. Missing: [list]. Re-run the review."

Read each prompt file. Paths in the dispatch JSON are absolute — use them directly, do not join with the initiative directory.

If run logging is enabled: `echo "review_dispatch_start=$(date +%s)" >> "$TIMING_FILE"`

Spawn **all four agents in parallel**, using the model from `MODEL_MAP` for each:

- Agent 1 (API): read `{promptFiles.api}`, use its content as the agent prompt, `model: MODEL_MAP[review-api]`
- Agent 2 (Structure): read `{promptFiles.structure}`, use its content as the agent prompt, `model: MODEL_MAP[review-structure]`
- Agent 3 (Flow): read `{promptFiles.flow}`, use its content as the agent prompt, `model: MODEL_MAP[review-flow]`
- Agent 4 (Requirements): read `{promptFiles.requirements}`, use its content as the agent prompt, `model: MODEL_MAP[review-requirements]`

Wait for all four to complete.

If run logging is enabled: `echo "review_dispatch_end=$(date +%s)" >> "$TIMING_FILE"`

If run logging is enabled, read each sub-agent's timing file before cleanup:
```bash
for agent in api structure flow requirements; do
  TFILE="{initiative_dir}/{argument}-review-${agent}.md.timing"
  if [ -f "$TFILE" ]; then
    while IFS='=' read -r key val; do
      echo "subagent_${agent}_${key}=${val}" >> "$TIMING_FILE"
    done < "$TFILE"
  fi
done
```

### Step 3.4: Assembly (reviewer Phase 3)

If run logging is enabled: `echo "review_assembly_start=$(date +%s)" >> "$TIMING_FILE"`

Spawn an Agent using `.claude/agents/prd-reviewer.md`, with `model: MODEL_MAP[prd-reviewer]`, and the prompt:

> "Run Phase 3 only for initiative '{argument}'. Sub-agents have completed. The dispatch file is at {absolute_path_to_dispatch_json}. Re-read project context, lessons, PRD, and scaffold. Assemble sub-agent outputs, fill Matrix H, run completeness verification, spot-check, dynamic findings, defect taxonomy, verdict, and commit."

If run logging is enabled: `echo "review_assembly_end=$(date +%s)" >> "$TIMING_FILE"`

### Step 3.6: Defensive cleanup

After the reviewer returns from Phase 3, verify the commit succeeded before deleting temporary files. If the commit failed, the reviewer preserves these files as evidence — do not delete them.

```bash
# Only clean up if the reviewer's commit landed
if git log --oneline -1 | grep -q "{argument}.*PRD review"; then
  rm -f {initiative_dir}/*-review-prompt-*.md {initiative_dir}/*-review-dispatch.json
  rm -f {initiative_dir}/*-review-api.md {initiative_dir}/*-review-structure.md {initiative_dir}/*-review-flow.md {initiative_dir}/*-review-requirements.md
  rm -f {initiative_dir}/*-review-*.md.timing
else
  echo "WARNING: Review commit not found — keeping sub-agent files for debugging."
fi
```

The reviewer now has the review file and handoff ready.

### Gate 3: Review Results + Proposed Lessons

If run logging is enabled: `echo "gate3_prompt=$(date +%s)" >> "$TIMING_FILE"`

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

**Then**, show proposed glossary terms (if any). Collect proposals from BOTH the writer's handoff (`proposedGlossaryTerms`) and the reviewer's handoff/review document. Deduplicate by term name — if both proposed the same term, prefer the reviewer's definition (it has the benefit of seeing the full PRD). For each term, show:
- Number, term
- Proposed definition
- Reason

If no glossary terms were proposed, say "No new glossary terms proposed."

**Then**, ask for action — one prompt covering verdict, lessons, and glossary terms:
- If READY: **"Approve lessons: all / specific (e.g., '1 and 3') / skip. Approve glossary terms: all / specific / skip. Then we're done."**
- If NEEDS_REVISION: **"For the review: 'revise' to send back to prd-writer, or 'override' to approve as-is. For lessons: all / specific / skip. For glossary terms: all / specific / skip."**

If run logging is enabled: `echo "gate3_resume=$(date +%s)" >> "$TIMING_FILE"`

On lesson approval, spawn a new Agent using `.claude/agents/prd-reviewer.md`, with `model: MODEL_MAP[prd-reviewer]`, and the prompt: "Run only Step 12. Write these approved lessons to `.claude/prd-lessons.md`: [list the approved lesson names and their content from the review file]. The review file is at {review_path}." This is a targeted callback — the agent reads the review, extracts the approved lessons, and appends them to the lessons file.

On glossary term approval, spawn a new Agent using `.claude/agents/prd-reviewer.md`, with `model: MODEL_MAP[prd-reviewer]`, and the prompt: "Run only Step 13. Write these approved glossary terms to the Domain Glossary table in `.claude/project-context.md`: [list the approved terms with their definitions]. The review file is at {review_path}." This is a targeted callback — the agent reads project-context.md and appends the approved terms to the glossary table.

If both lessons and glossary terms are approved, spawn both callbacks in parallel — they write to different files and don't conflict.

If "revise": increment the revision count.
  - If revision count < 3: spawn a new prd-writer agent with `model: MODEL_MAP[prd-writer]` and the prompt: "This is a revision cycle. Read the existing PRD at {prd_path} and the review at {review_path}. Follow Step 3.5 (Revision Mode) — fix each FAIL in the review's Issues Found list. Do not rewrite the entire PRD." The writer's Step 3.5 handles versioning, targeted fixes, and handoff. **After the writer completes the revision, return to Step 3.1 to re-run the review.**
  - If revision count = 3: tell the user: **"This PRD has gone through 3 revision cycles and still has FAILs. Remaining issues: [list]. Options: 'override' to approve as-is, 'continue' to try one more cycle, or 'stop' to pause and resolve issues manually."**
If "override": mark as approved and end.

## Completion

### Write Run Log (if enabled)

If run logging is enabled in project-context.md, write the run log before summarizing:

1. Record the end time:
   ```bash
   echo "review_end=$(date +%s)" >> "$TIMING_FILE"
   echo "pipeline_end=$(date +%s) $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$TIMING_FILE"
   ```

2. Read the timing file and the reviewer's handoff JSON (`{initiative}-prd-review-handoff.json`).

3. Compute durations from epoch timestamps (subtract `_start` from `_end` for each pair). Compute human wait time from gate pairs (`gate1_resume - gate1_prompt` + `gate2_resume - gate2_prompt` + `gate3_resume - gate3_prompt`). If a gate pair is missing (e.g., pipeline ended before Gate 3), skip it.

4. Extract quality metrics from the review handoff: `verdict`, `totalCells`, `failCount`, `failsByMatrix`, `smellDetection`, `spotCheckOverrides`, `issuesSummary` (count by category for defect taxonomy).

5. If sub-agent timing entries exist in the timing file (`subagent_api_start`, etc.), compute per-sub-agent durations.

6. Create the run log directory if it doesn't exist:
   ```bash
   mkdir -p {run_log_output_path}
   ```

7. Write the run log JSON to `{run_log_output_path}/run-{YYYYMMDD-HHMMSS}.json`:

   ```json
   {
     "runId": "<YYYYMMDD-HHMMSS>",
     "initiative": "<name>",
     "profile": "<reliable|cost-optimized|custom>",
     "startedAt": "<ISO8601 from pipeline_start>",
     "completedAt": "<ISO8601 from pipeline_end>",
     "totalDurationSeconds": "<pipeline_end - pipeline_start>",
     "agentDurationSeconds": "<totalDurationSeconds minus humanWaitSeconds>",
     "humanWaitSeconds": "<sum of all gate durations>",
     "modelMap": {
       "researcher": "<model>",
       "prd-writer": "<model>",
       "prd-reviewer": "<model>",
       "review-api": "<model>",
       "review-structure": "<model>",
       "review-flow": "<model>",
       "review-requirements": "<model>"
     },
     "phases": {
       "research": {
         "model": "<MODEL_MAP[researcher]>",
         "agentDurationSeconds": "<research_end - research_start>",
         "gateDurationSeconds": "<gate1_resume - gate1_prompt>"
       },
       "writing": {
         "model": "<MODEL_MAP[prd-writer]>",
         "agentDurationSeconds": "<writing_end - writing_start>",
         "gateDurationSeconds": "<gate2_resume - gate2_prompt>"
       },
       "review": {
         "orchestratorModel": "<MODEL_MAP[prd-reviewer]>",
         "reviewMode": "<parallel|single>",
         "totalDurationSeconds": "<review_end - review_start, including revision cycles>",
         "gateDurationSeconds": "<gate3_resume - gate3_prompt>",
         "scaffold": {
           "durationSeconds": "<review_scaffold_end - review_scaffold_start>"
         },
         "subAgents": {
           "batchDurationSeconds": "<review_dispatch_end - review_dispatch_start>",
           "agents": {
             "api": { "model": "<model>", "durationSeconds": "<from timing file, or null>" },
             "structure": { "model": "<model>", "durationSeconds": "<from timing file, or null>" },
             "flow": { "model": "<model>", "durationSeconds": "<from timing file, or null>" },
             "requirements": { "model": "<model>", "durationSeconds": "<from timing file, or null>" }
           }
         },
         "assembly": {
           "durationSeconds": "<review_assembly_end - review_assembly_start>"
         },
         "revisionCycles": "<count>"
       }
     },
     "prdSize": {
       "frCount": "<from handoff>",
       "acCount": "<from handoff>",
       "endpointCount": "<from handoff>",
       "entityCount": "<from handoff>"
     },
     "quality": {
       "verdict": "<READY|NEEDS_REVISION>",
       "totalCells": "<integer>",
       "failCount": "<integer>",
       "failsByMatrix": {
         "A": 0, "B": 0, "C": 0, "D1": 0, "D2": 0,
         "E": 0, "F": 0, "G": 0, "H": 0, "I": 0, "P": 0
       },
       "defectTaxonomy": {
         "omission": "<count from issuesSummary where category=Omission>",
         "ambiguity": "<count>",
         "inconsistency": "<count>",
         "incorrectFact": "<count>",
         "extraneousInfo": "<count>",
         "misplacedRequirement": "<count>"
       },
       "smellDetection": {
         "totalChecked": "<from handoff>",
         "smellsFound": "<from handoff>"
       },
       "spotCheckOverrides": "<from handoff>"
     },
     "artifacts": {
       "researchPath": "<relative path>",
       "prdPath": "<relative path>",
       "reviewPath": "<relative path>"
     }
   }
   ```

   All numeric fields must be integers. Use `null` for sub-agent durations if timing files were missing (e.g., single-agent mode). Use the Write tool to create the file.

8. Delete the timing file: `rm -f "$TIMING_FILE"`

9. Commit the run log (do NOT push):
   ```bash
   git add {run_log_file_path}
   git commit -m "docs: add {initiative} run log ({profile} profile)"
   ```

> **Note on token usage and cost**: Token counts are not available programmatically during a Claude Code session. To correlate cost with run logs, check your Anthropic dashboard usage for the session's time window. The `modelMap` and phase durations in the run log provide the basis for cost estimation.

### Summary

Summarize what was produced:
- Research document path
- PRD path (with version)
- Review path
- Handoff file paths
- Final verdict
- Lessons added (if any)
- Run log path (if logging enabled)
