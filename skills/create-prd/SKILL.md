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
4. Check if **Run Logs** are enabled in project-context.md. If enabled:
   ```bash
   RUN_ID=$(date -u +%Y%m%d-%H%M%S)
   LOG_FILE=".claude/prd-run-log.jsonl"
   STATE_FILE=".claude/prd-run-state.json"
   TIMING_FILE="{initiative_dir}/.run-timing.tmp"
   echo "pipeline_start=$(date +%s) $(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$TIMING_FILE"
   ```
   Record the profile name (from the `Profile` field in Model Profile) for the run log.

5. **Stale state recovery**: Check for an abandoned previous run:
   ```bash
   [ -f "$STATE_FILE" ] && cat "$STATE_FILE"
   ```
   If `$STATE_FILE` exists, a previous pipeline run was interrupted (user closed laptop, connection dropped, etc.). Recover it:
   1. Read the state file — extract `runId`, `initiative`, `currentPhase`, `startedAt`, `completedPhases`
   2. Append a `"terminated"` JSONL entry to `$LOG_FILE` capturing all completed phases and the phase that was in progress when it died:
      ```bash
      echo '{"entryType":"terminated","runId":"<from state>","initiative":"<from state>","terminatedAt":"<now ISO8601>","diedInPhase":"<currentPhase>","completedPhases":<array from state>,"reason":"abandoned"}' >> "$LOG_FILE"
      ```
   3. Delete the stale state file: `rm -f "$STATE_FILE"`
   4. Log a message: "Recovered abandoned run {runId} for {initiative} — terminated in {currentPhase} phase."

6. **Create state file** for the current run:
   ```bash
   echo '{"runId":"'"$RUN_ID"'","initiative":"{argument}","status":"in_progress","currentPhase":"preflight","cycle":1,"startedAt":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","profile":"<profile>","modelMap":<MODEL_MAP as JSON>,"completedPhases":[]}' > "$STATE_FILE"
   ```

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

If run logging is enabled:
```bash
echo "research_end=$(date +%s)" >> "$TIMING_FILE"
```
Update state file — mark research complete and append researcher JSONL entry:
1. Extract metrics from the research document (grep-based counts):
   ```bash
   ENDPOINTS=$(grep -c '| [0-9]' {research_path_endpoints_table} 2>/dev/null || echo 0)
   FILES_READ=$(grep -c '| \`' {research_path_files_table} 2>/dev/null || echo 0)
   AMBIGUITIES=$(grep -c '| [0-9]' {research_path_ambiguities_table} 2>/dev/null || echo 0)
   ```
2. Append researcher JSONL entry:
   ```bash
   echo '{"entryType":"researcher","runId":"'"$RUN_ID"'","initiative":"{argument}","agent":"researcher","model":"'"$MODEL_MAP_RESEARCHER"'","cycle":1,"startedAt":"<research_start ISO>","completedAt":"<research_end ISO>","durationSeconds":<research_end - research_start>,"inputSummary":"Initiative brief: {argument}","outputSummary":"Research doc with '$ENDPOINTS' endpoints, '$FILES_READ' files, '$AMBIGUITIES' ambiguities","artifactPath":"<research doc path>","handoffPath":null,"metrics":{"endpointsFound":'$ENDPOINTS',"filesRead":'$FILES_READ',"ambiguitiesFlagged":'$AMBIGUITIES'}}' >> "$LOG_FILE"
   ```
3. Update state file — set `currentPhase: "gate1"`, push researcher phase into `completedPhases`

### Gate 1: Research Review

If run logging is enabled:
```bash
echo "gate1_prompt=$(date +%s)" >> "$TIMING_FILE"
```
Update state file — set `currentPhase: "gate1"`.

Present the research findings to the user as a summary:
- Modules/packages involved (or "greenfield — no code yet")
- Key API endpoints found
- Business logic discovered
- Any flagged inconsistencies or ambiguities

Ask: **"Review the research above. Say 'continue' to proceed to PRD drafting, or provide feedback to adjust the research."**

For greenfield projects, also ask: **"Since there's no existing code, do you have requirements, specs, or design docs you'd like me to reference during PRD drafting?"**

If feedback is given, send it back to the researcher agent for revision. Repeat until the user says "continue."

If run logging is enabled:
```bash
echo "gate1_resume=$(date +%s)" >> "$TIMING_FILE"
```
Update state file — set `currentPhase: "writing"`.

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

If run logging is enabled:
```bash
echo "writing_end=$(date +%s)" >> "$TIMING_FILE"
```
Append writer JSONL entry:
1. Read the writer's handoff JSON — extract `prdMetrics` (frCount, acCount, edgeCaseCount, keyEntityCount, version, isFreshDraft, failsAddressed, sectionPacksUsed) and `apiEndpoints` count
2. Append:
   ```bash
   echo '{"entryType":"writer","runId":"'"$RUN_ID"'","initiative":"{argument}","agent":"prd-writer","model":"'"$MODEL_MAP_WRITER"'","cycle":<current_cycle>,"startedAt":"<writing_start ISO>","completedAt":"<writing_end ISO>","durationSeconds":<delta>,"inputSummary":"<research doc or revision of N FAILs>","outputSummary":"PRD <version> with <frCount> FRs, <acCount> ACs, <edgeCaseCount> edge cases","artifactPath":"<prd path>","handoffPath":"<handoff path>","metrics":<prdMetrics from handoff>}' >> "$LOG_FILE"
   ```
3. Update state file — set `currentPhase: "gate2"`, push writer phase into `completedPhases`

### Gate 2: PRD Draft Review

If run logging is enabled:
```bash
echo "gate2_prompt=$(date +%s)" >> "$TIMING_FILE"
```
Update state file — set `currentPhase: "gate2"`.

Tell the user: **"PRD draft is ready at `{prd_path}`. Review it, then say 'continue' to run the reviewer, or provide feedback for revisions."**

If feedback is given, send it back to the prd-writer for revision. Repeat until the user says "continue."

If run logging is enabled:
```bash
echo "gate2_resume=$(date +%s)" >> "$TIMING_FILE"
```
Update state file — set `currentPhase: "review"`.

## Phase 3: PRD Review (max 3 revision cycles)

If run logging is enabled:
```bash
echo "review_start=$(date +%s)" >> "$TIMING_FILE"
```
Update state file — set `currentPhase: "review"`.

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

First, verify all five prompt files from the dispatch JSON exist:
```bash
for f in "{promptFiles.api}" "{promptFiles.structure}" "{promptFiles.flow}" "{promptFiles.requirements}" "{promptFiles.smells}"; do
  [ -f "$f" ] || echo "MISSING: $f"
done
```
If any are missing, STOP and tell the user: "Reviewer Phase 1 failed to write all prompt files. Missing: [list]. Re-run the review."

Read each prompt file. Paths in the dispatch JSON are absolute — use them directly, do not join with the initiative directory.

If run logging is enabled: `echo "review_dispatch_start=$(date +%s)" >> "$TIMING_FILE"`

Spawn **all five agents in parallel**, using the model from `MODEL_MAP` for each:

- Agent 1 (API): read `{promptFiles.api}`, use its content as the agent prompt, `model: MODEL_MAP[review-api]`
- Agent 2 (Structure): read `{promptFiles.structure}`, use its content as the agent prompt, `model: MODEL_MAP[review-structure]`
- Agent 3 (Flow): read `{promptFiles.flow}`, use its content as the agent prompt, `model: MODEL_MAP[review-flow]`
- Agent 4 (Requirements): read `{promptFiles.requirements}`, use its content as the agent prompt, `model: MODEL_MAP[review-requirements]`
- Agent 5 (Smells): read `{promptFiles.smells}`, use its content as the agent prompt, `model: MODEL_MAP[review-smells]`

Wait for all five to complete.

If run logging is enabled: `echo "review_dispatch_end=$(date +%s)" >> "$TIMING_FILE"`

If run logging is enabled, read each sub-agent's timing file before cleanup:
```bash
for agent in api structure flow requirements smells; do
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

If run logging is enabled:
```bash
echo "review_assembly_end=$(date +%s)" >> "$TIMING_FILE"
```
Append reviewer JSONL entry:
1. Read the reviewer's handoff JSON — extract all metrics (totalCells, failCount, failsByMatrix, smellDetection, spotCheckOverrides, defectTaxonomy, reviewMode, isReReview, previousFailsVerified, prdSize)
2. Read sub-agent timing files (if parallel mode) for per-sub-agent durations
3. Append:
   ```bash
   echo '{"entryType":"reviewer","runId":"'"$RUN_ID"'","initiative":"{argument}","agent":"prd-reviewer","model":"'"$MODEL_MAP_REVIEWER"'","cycle":<current_cycle>,"startedAt":"<review_start ISO>","completedAt":"<review_assembly_end ISO>","durationSeconds":<delta>,"inputSummary":"PRD <version> at <path>, <frCount> FRs, <acCount> ACs","outputSummary":"<verdict>: <failCount> FAILs, <totalCells> cells filled, <spotCheckOverrides> spot-check overrides","artifactPath":"<review path>","handoffPath":"<review handoff path>","metrics":<all metrics from handoff>,"subAgentDurations":{"scaffold":<delta>,"api":<delta|null>,"structure":<delta|null>,"flow":<delta|null>,"requirements":<delta|null>,"smells":<delta|null>,"assembly":<delta>}}' >> "$LOG_FILE"
   ```
4. Update state file — set `currentPhase: "gate3"`, push reviewer phase into `completedPhases`

### Step 3.6: Defensive cleanup

After the reviewer returns from Phase 3, verify the commit succeeded before deleting temporary files. If the commit failed, the reviewer preserves these files as evidence — do not delete them.

```bash
# Only clean up if the reviewer's commit landed
if git log --oneline -1 | grep -q "{argument}.*PRD review"; then
  rm -f {initiative_dir}/*-review-prompt-*.md {initiative_dir}/*-review-dispatch.json
  rm -f {initiative_dir}/*-review-api.md {initiative_dir}/*-review-structure.md {initiative_dir}/*-review-flow.md {initiative_dir}/*-review-requirements.md {initiative_dir}/*-review-smells.md
  rm -f {initiative_dir}/*-review-*.md.timing
else
  echo "WARNING: Review commit not found — keeping sub-agent files for debugging."
fi
```

The reviewer now has the review file and handoff ready.

### Gate 3: Review Results + Proposed Lessons

If run logging is enabled:
```bash
echo "gate3_prompt=$(date +%s)" >> "$TIMING_FILE"
```
Update state file — set `currentPhase: "gate3"`.

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

If run logging is enabled:
```bash
echo "gate3_resume=$(date +%s)" >> "$TIMING_FILE"
```

On lesson approval, spawn a new Agent using `.claude/agents/prd-reviewer.md`, with `model: MODEL_MAP[prd-reviewer]`, and the prompt: "Run only Step 12. Write these approved lessons to `.claude/prd-lessons.md`: [list the approved lesson names and their content from the review file]. The review file is at {review_path}." This is a targeted callback — the agent reads the review, extracts the approved lessons, and appends them to the lessons file.

On glossary term approval, spawn a new Agent using `.claude/agents/prd-reviewer.md`, with `model: MODEL_MAP[prd-reviewer]`, and the prompt: "Run only Step 13. Write these approved glossary terms to the Domain Glossary table in `.claude/project-context.md`: [list the approved terms with their definitions]. The review file is at {review_path}." This is a targeted callback — the agent reads project-context.md and appends the approved terms to the glossary table.

If both lessons and glossary terms are approved, spawn both callbacks in parallel — they write to different files and don't conflict.

If "revise": increment the revision count. If run logging is enabled, increment `cycle` in the state file and set `currentPhase: "revision"`.
  - If revision count < 3: spawn a new prd-writer agent with `model: MODEL_MAP[prd-writer]` and the prompt: "This is a revision cycle. Read the existing PRD at {prd_path} and the review at {review_path}. Follow Step 3.5 (Revision Mode) — fix each FAIL in the review's Issues Found list. Do not rewrite the entire PRD." The writer's Step 3.5 handles versioning, targeted fixes, and handoff. **After the writer completes the revision, return to Step 3.1 to re-run the review.**
  - If revision count = 3: tell the user: **"This PRD has gone through 3 revision cycles and still has FAILs. Remaining issues: [list]. Options: 'override' to approve as-is, 'continue' to try one more cycle, or 'stop' to pause and resolve issues manually."**
If "override": mark as approved and end.

## Completion

### Write Run Log (if enabled)

If run logging is enabled in project-context.md, finalize the log before summarizing:

1. Record the end time:
   ```bash
   echo "pipeline_end=$(date +%s) $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$TIMING_FILE"
   ```

2. Read the timing file. Compute human wait time from gate pairs (`gate1_resume - gate1_prompt` + `gate2_resume - gate2_prompt` + `gate3_resume - gate3_prompt`). If a gate pair is missing (e.g., pipeline ended before Gate 3), skip it.

3. Append the **pipeline summary** JSONL entry:
   ```bash
   echo '{"entryType":"pipeline","runId":"'"$RUN_ID"'","initiative":"{argument}","agent":"create-prd","model":"opus","profile":"<profile>","cycle":<final_cycle>,"startedAt":"<pipeline_start ISO>","completedAt":"<pipeline_end ISO>","durationSeconds":<total_delta>,"inputSummary":"Initiative: {argument}, full pipeline run","outputSummary":"<totalCycles> cycles: <summary of each cycle verdict>","artifactPath":"<final prd path>","handoffPath":null,"metrics":{"totalCycles":<count>,"finalVerdict":"<READY|NEEDS_REVISION|OVERRIDE>","humanWaitSeconds":<sum>,"agentDurationSeconds":<total minus human>,"gateDurations":{"gate1":<delta|null>,"gate2":<delta|null>,"gate3":<delta|null>},"lessonsApproved":<count>,"glossaryTermsApproved":<count>}}' >> "$LOG_FILE"
   ```

   Individual agent entries (researcher, writer, reviewer) were already appended after each phase completed — the pipeline entry is the final summary that ties them together via `runId`.

4. Delete the timing file and state file:
   ```bash
   rm -f "$TIMING_FILE" "$STATE_FILE"
   ```

5. Commit the run log (do NOT push):
   ```bash
   git add "$LOG_FILE"
   git commit -m "docs: add {initiative} run log ({profile} profile, $RUN_ID)"
   ```

> **Note on token usage and cost**: Token counts are not available programmatically during a Claude Code session. To correlate cost with run logs, check your Anthropic dashboard usage for the session's time window. The `modelMap` and phase durations in the run log provide the basis for cost estimation.

### JSONL Schema Reference

Each line in `.claude/prd-run-log.jsonl` is one of these entry types:

**Common fields** (all entries): `entryType`, `runId` (YYYYMMDD-HHMMSS, shared across pipeline), `initiative`, `agent`, `model`, `profile`, `cycle` (1 = first draft+review), `startedAt`, `completedAt`, `durationSeconds`, `inputSummary`, `outputSummary`, `artifactPath`, `handoffPath`

**`"researcher"`** metrics: `endpointsFound`, `filesRead`, `ambiguitiesFlagged`

**`"writer"`** metrics: `frCount`, `acCount`, `edgeCaseCount`, `keyEntityCount`, `version`, `sectionPacksUsed`, `isFreshDraft`, `failsAddressed`

**`"reviewer"`** metrics: `totalCells`, `filledCells`, `subAgentCells`, `orchestratorCells`, `failCount`, `failsByMatrix` (A/B/C/S/D1/D2/E/F/G/H/I/P), `smellDetection` (totalChecked/linguisticSmellsFound/separationSmellsFound), `spotCheckOverrides`, `verdict`, `reviewMode`, `isReReview`, `previousFailsVerified`, `defectTaxonomy` (omission/ambiguity/inconsistency/incorrectFact/extraneousInfo/misplacedRequirement), `proposedLessons`, `proposedGlossaryTerms`. Plus `subAgentDurations` (scaffold/api/structure/flow/requirements/smells/assembly — null in single mode).

**`"pipeline"`** metrics: `totalCycles`, `finalVerdict`, `humanWaitSeconds`, `agentDurationSeconds`, `gateDurations` (gate1/gate2/gate3), `lessonsApproved`, `glossaryTermsApproved`

**`"terminated"`** (abandoned runs): `diedInPhase`, `completedPhases` (array of phase summaries), `reason` ("abandoned")

**`"judge"`** (LLM-as-Judge scores, appended after evaluation runs): `judgeModel`, `prdPath`, `reviewPath`, `scores` (object with dimensions: `completeness`, `precision`, `apiAccuracy`, `edgeCaseCoverage`, `testability`, `consistency`, `implementability` — each 1-5), `totalScore` (sum), `reasoning` (object with per-dimension explanation + evidence quotes)

**Optional field — all entries**: `experiment` (object, present only during `/evaluate` runs): `experimentId` (e.g., "exp6"), `batchId` (groups all runs in one evaluation session), `swapId` (e.g., "baseline", "swap-d"), `swapAgent` (agent name that was swapped, or null for baseline), `swapFrom` (original model), `swapTo` (new model), `runNumber` (1-based, for repeated runs), `fixtureSet` (path to fixtures used)

### Summary

Summarize what was produced:
- Research document path
- PRD path (with version)
- Review path
- Handoff file paths
- Final verdict
- Lessons added (if any)
- Run log path (if logging enabled)
