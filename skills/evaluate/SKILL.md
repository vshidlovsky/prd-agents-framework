---
name: evaluate
description: Runs model evaluation experiments. Swaps agent models, replays fixtures, collects JSONL telemetry for comparison.
argument-hint: <experiment> <initiative> [swap-id]
---

# Evaluation Runner

Run model evaluation experiments with controlled inputs and isolated outputs.

## Usage

```
/evaluate exp6 <initiative> [swap-id]
```

- `/evaluate exp6 transaction-history` — run all 9 swaps for transaction-history
- `/evaluate exp6 transaction-history swap-d` — run only swap D (review-api → sonnet)
- `/evaluate exp6 transaction-history baseline` — run baseline only (captures fixtures)
- `/evaluate judge transaction-history` — run LLM-as-Judge on all completed experiment outputs

## Pre-flight

1. Read `.claude/project-context.md` — confirm it exists. Extract `MODEL_MAP` from Model Profile table.
2. Read the experiment plan from the framework: `docs/experiment-6-plan.md` (or from the local `.claude/` if copied).
3. Set up experiment variables:
   ```bash
   EXPERIMENT_ID="exp6"
   BATCH_ID=$(date -u +%Y%m%d-%H%M%S)
   LOG_FILE=".claude/prd-run-log.jsonl"
   EVAL_DIR="eval/${EXPERIMENT_ID}/{initiative}"
   mkdir -p "$EVAL_DIR"
   ```

4. Parse the `{argument}` to extract experiment type, initiative name, and optional swap-id filter.

## Experiment 6: Individual Agent Swap

### Swap Definitions

| Swap ID | Agent swapped | Model change | Phases to run |
|---|---|---|---|
| `baseline` | none | all opus | full pipeline |
| `swap-a` | researcher | opus → sonnet | full pipeline |
| `swap-b` | prd-writer | opus → sonnet | write + review |
| `swap-c` | prd-reviewer | opus → sonnet | review only |
| `swap-d` | review-api | opus → sonnet | review only |
| `swap-e` | review-structure | opus → sonnet | review only |
| `swap-f` | review-flow | opus → sonnet | review only |
| `swap-g` | review-requirements | opus → sonnet | review only |
| `swap-h` | review-smells | opus → sonnet | review only |

### Step 1: Check for Baseline

Before any swap run, verify baseline fixtures exist:
```bash
FIXTURE_DIR="eval/fixtures/{initiative}"
[ -f "$FIXTURE_DIR/research.md" ] && [ -f "$FIXTURE_DIR/prd.md" ] && [ -f "$FIXTURE_DIR/qa.json" ]
```

If missing and `swap-id` is NOT `baseline`, STOP: **"No baseline fixtures for {initiative}. Run `/evaluate exp6 {initiative} baseline` first."**

### Step 2: Determine Run List

- If `swap-id` is specified: run only that swap
- If no `swap-id`: run all 9 swaps in sequence (baseline first, then A through H)

For each swap in the run list, execute Step 3.

### Step 3: Execute Single Swap Run

#### 3.1 Set Up Isolation

```bash
SWAP_ID="{current swap id}"
RUN_DIR="$EVAL_DIR/$SWAP_ID"
mkdir -p "$RUN_DIR"
RUN_ID=$(date -u +%Y%m%d-%H%M%S)
```

#### 3.2 Build Model Map Override

Start with the baseline MODEL_MAP (all opus). Apply the swap:
```
swap-a: MODEL_MAP[researcher] = sonnet
swap-b: MODEL_MAP[prd-writer] = sonnet
swap-c: MODEL_MAP[prd-reviewer] = sonnet
swap-d: MODEL_MAP[review-api] = sonnet
swap-e: MODEL_MAP[review-structure] = sonnet
swap-f: MODEL_MAP[review-flow] = sonnet
swap-g: MODEL_MAP[review-requirements] = sonnet
swap-h: MODEL_MAP[review-smells] = sonnet
```

For baseline: no changes (all opus).

#### 3.3 Execute Pipeline Phases

The phases that run depend on the swap type:

**Baseline (full pipeline)**:

1. Run researcher (opus) → save research to `$RUN_DIR/`
2. Gate 1: auto-approve ("continue")
3. Run writer (opus) → save PRD + Q&A log + handoff to `$RUN_DIR/`
4. Gate 2: auto-approve ("continue")
5. Run reviewer (opus, all sub-agents opus) → save review + handoff to `$RUN_DIR/`
6. Gate 3: auto-approve, skip lessons/glossary ("skip")
7. **Capture fixtures**: Copy research, PRD, and Q&A log to `eval/fixtures/{initiative}/`:
   ```bash
   FIXTURE_DIR="eval/fixtures/{initiative}"
   mkdir -p "$FIXTURE_DIR"
   cp "$RUN_DIR/{initiative}-research.md" "$FIXTURE_DIR/research.md"
   cp "$RUN_DIR/{initiative}-prd-v1.md" "$FIXTURE_DIR/prd.md"
   cp "$RUN_DIR/{initiative}-writer-qa.json" "$FIXTURE_DIR/qa.json"
   ```

**Swap A (researcher → sonnet, full pipeline)**:

1. Run researcher (sonnet) → save to `$RUN_DIR/`
2. Gate 1: auto-approve ("continue")
3. Run writer (opus) with the sonnet researcher's output. Writer gets the Q&A fixture for reference — if it asks a question already in the fixture, replay the answer. If it asks a novel question, log it in the Q&A with `"source": "novel"` and provide a neutral answer. Save PRD + Q&A + handoff to `$RUN_DIR/`.
4. Gate 2: auto-approve ("continue")
5. Run reviewer (opus) → save to `$RUN_DIR/`
6. Gate 3: auto-approve, skip lessons/glossary

**Swap B (writer → sonnet, write + review)**:

1. **Skip research** — copy fixture: `cp "$FIXTURE_DIR/research.md" "$RUN_DIR/{initiative}-research.md"`
2. Run writer (sonnet) with pinned research. Replay Q&A from fixture. If novel questions appear, log with `"source": "novel"` and provide neutral answer. Save PRD + Q&A + handoff to `$RUN_DIR/`.
3. Gate 2: auto-approve ("continue")
4. Run reviewer (opus) on the sonnet writer's PRD → save to `$RUN_DIR/`
5. Gate 3: auto-approve, skip lessons/glossary

**Swaps C-H (reviewer agents → sonnet, review only)**:

1. **Skip research and writing** — copy fixtures:
   ```bash
   cp "$FIXTURE_DIR/research.md" "$RUN_DIR/{initiative}-research.md"
   cp "$FIXTURE_DIR/prd.md" "$RUN_DIR/{initiative}-prd-v1.md"
   ```
   Also create a writer handoff from the fixture PRD (extract counts from the pinned PRD).
2. Run reviewer with the swapped model map → save to `$RUN_DIR/`
3. Gate 3: auto-approve, skip lessons/glossary

#### 3.4 Agent Invocation

For each agent spawn, use the same Agent tool pattern as `/create-prd`, but with these differences:

- **Output directory**: all paths point to `$RUN_DIR/` instead of the normal initiative directory
- **Model**: use the swap-modified MODEL_MAP
- **Q&A replay**: when invoking the writer, append to the prompt: "Q&A fixture is available at `{qa_fixture_path}`. For any question you would ask that matches a question in the fixture (same topic, same decision), use the fixture's `resolvedValue` as the answer without asking the user. If you have a question NOT covered by the fixture, ask the user and tag it as `novel` in the Q&A log."
- **No commits**: do NOT commit artifacts during evaluation runs — all files stay in `$RUN_DIR/`
- **No lessons/glossary callbacks**: always skip

#### 3.5 Log JSONL Entry

After each agent completes, append a JSONL entry to `$LOG_FILE` with the standard fields PLUS the `experiment` object:

```json
{
  "experiment": {
    "experimentId": "exp6",
    "batchId": "<BATCH_ID>",
    "swapId": "<SWAP_ID>",
    "swapAgent": "<agent name or null for baseline>",
    "swapFrom": "opus",
    "swapTo": "sonnet",
    "runNumber": 1,
    "fixtureSet": "<FIXTURE_DIR path>"
  }
}
```

After all phases for this swap complete, append a pipeline summary entry with the same experiment metadata.

#### 3.6 Report Swap Result

After each swap completes, print a one-line summary:
```
[exp6/{initiative}/swap-d] DONE — reviewer: 3 FAILs (A:0 B:1 C:1 S:1), 42 cells, 185s
```

### Step 4: Batch Summary

After all swaps in the run list complete, print a comparison table:

```
## Experiment 6 Results: {initiative}

| Swap | Agent | Model | FAILs | By Matrix (A/B/C/S/D1/D2/E/F/G/H/I/P) | Smells | Duration |
|------|-------|-------|-------|----------------------------------------|--------|----------|
| baseline | — | opus | 2 | 0/1/0/1/0/0/0/0/0/0/0/0 | 1 | 210s |
| swap-d | review-api | sonnet | 4 | 0/1/1/1/1/0/0/0/0/0/0/0 | 1 | 145s |
| ... | ... | ... | ... | ... | ... | ... |
```

Tell the user: **"Evaluation complete. Run `/evaluate judge {initiative}` to score each PRD with LLM-as-Judge."**

## LLM-as-Judge

When invoked as `/evaluate judge <initiative>`:

### Step 1: Collect Artifacts

Find all completed swap runs:
```bash
ls eval/exp6/{initiative}/*/
```

For each swap directory, locate the PRD and review files.

### Step 2: Build Judge Prompt

For each swap, spawn a judge agent with `model: opus` and this prompt:

```
You are evaluating a Product Requirements Document and its review.

Score the PRD on each dimension using the rubric below.
For each dimension:
1. Quote specific evidence from the PRD (good or bad)
2. Explain your reasoning
3. Assign a score (1-5)

| Dimension | 1 (Poor) | 3 (Adequate) | 5 (Excellent) |
|-----------|----------|--------------|---------------|
| Completeness | Missing sections, open questions remain | All sections present, minor gaps | Every section filled, zero open questions |
| Precision | Vague requirements, multiple smells | Mostly concrete, occasional ambiguity | Every FR atomic, every AC testable, zero smells |
| API Accuracy | Endpoints unverified or wrong | Most endpoints verified, minor mismatches | Every endpoint verified, shapes match |
| Edge Case Coverage | Ad hoc, major gaps | Covers obvious cases, misses boundaries | Systematic generation, all checklists applied |
| Testability | ACs require reading code to verify | Most ACs testable from running app | Every AC verifiable from running application |
| Consistency | FRs contradict, terms shift meaning | Minor inconsistencies | Zero contradictions, terms consistent |
| Implementability | Developer needs significant clarification | Developer could implement with minor questions | Developer could implement with zero clarification |

PRD to evaluate:
[PRD content from $RUN_DIR/{initiative}-prd-*.md]

Review produced by the framework:
[Review content from $RUN_DIR/{initiative}-*-review.md]

Output your scores as JSON:
{
  "scores": {
    "completeness": <1-5>,
    "precision": <1-5>,
    "apiAccuracy": <1-5>,
    "edgeCaseCoverage": <1-5>,
    "testability": <1-5>,
    "consistency": <1-5>,
    "implementability": <1-5>
  },
  "totalScore": <sum>,
  "reasoning": {
    "completeness": { "score": <1-5>, "evidence": "<quote>", "explanation": "<why>" },
    ...
  }
}
```

**Bias controls**: Do NOT reveal which model profile produced the PRD. Run each evaluation twice with dimensions in different order — average the scores.

### Step 3: Log Judge Results

For each swap, append a `"judge"` JSONL entry:
```json
{
  "entryType": "judge",
  "runId": "<judge run id>",
  "initiative": "<initiative>",
  "agent": "judge",
  "model": "opus",
  "experiment": {
    "experimentId": "exp6",
    "batchId": "<BATCH_ID>",
    "swapId": "<swap being judged>",
    "swapAgent": "<agent or null>",
    "swapFrom": "opus",
    "swapTo": "sonnet",
    "runNumber": 1,
    "fixtureSet": "<path>"
  },
  "metrics": {
    "judgeModel": "opus",
    "prdPath": "<path>",
    "reviewPath": "<path>",
    "scores": { ... },
    "totalScore": 28,
    "reasoning": { ... }
  }
}
```

### Step 4: Judge Summary

Print a comparison table with judge scores:

```
## LLM-as-Judge Scores: {initiative}

| Swap | Comp | Prec | API | Edge | Test | Cons | Impl | Total |
|------|------|------|-----|------|------|------|------|-------|
| baseline | 5 | 4 | 5 | 4 | 5 | 5 | 4 | 32 |
| swap-d | 5 | 4 | 3 | 4 | 5 | 5 | 4 | 30 |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |
```

Highlight any dimension where a swap scored 2+ points below baseline.
