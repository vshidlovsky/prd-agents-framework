# Experiment 6: Individual Agent Swap (Opus → Sonnet)

**Goal**: Isolate which agent degrades most when swapped from opus to sonnet.

**Initiatives**: transaction-history, brclub

**Status**: Planning

---

## The "Different Questions" Problem

When you swap the researcher to sonnet, it might find different things, so the writer gets different context and asks different questions. Same if you swap the writer.

**Solution: pin the inputs at each phase boundary.**

1. **Run baseline once** (all opus) for each initiative. Save:
   - Research doc (as-is, already saved)
   - Writer's Q&A log — every question asked + your answer (**new**, not currently captured)
   - PRD output
   - Review output

2. **For all swap runs**, reuse pinned inputs:
   - **Swaps C-H** (reviewer/sub-reviewers): reuse baseline research + baseline PRD. Only the review phase runs. Writer doesn't run at all — testing review quality on an identical PRD.
   - **Swap B** (writer): reuse baseline research. Writer runs on sonnet. If it asks a question already in the Q&A fixture, replay the answer. If it asks a **new** question — that's signal, log it as "novel question" and provide a neutral answer.
   - **Swap A** (researcher): researcher runs on sonnet, produces different research. Writer runs on opus with that research. Different questions are expected — answer them live, but log everything.

3. **Gates**: always "continue" (no feedback). This removes human variance.

Swaps C-H are cheap (only review phase), Swap B is medium (write + review), Swap A is expensive (full pipeline).

---

## Logging Gaps to Fix Before Running

| Gap | What's missing | Fix |
|---|---|---|
| **Experiment metadata** | No way to tag a run as "experiment 6, swap D, run 1" | Add `experiment` object to pipeline JSONL entry |
| **Artifact isolation** | Runs overwrite each other's PRDs and reviews | Output to per-run subdirectory: `eval/exp6/{swap-id}/` |
| **Writer Q&A log** | Questions + answers not captured | New artifact: `{initiative}-writer-qa.json` |
| **Novel questions** | When swapped writer asks something new, we lose that signal | Log in Q&A artifact with `"source": "novel"` flag |
| **Judge scores** | No entry type for LLM-as-Judge results | New JSONL entry type `"judge"` |
| **Research diff** | When researcher is swapped, no way to compare outputs | Both research docs saved — just need distinct paths |

---

## Prerequisites (One-Time)

1. Ensure transaction-history and brclub both have a completed baseline run (all opus, READY verdict)
2. Extract golden fixtures from each baseline:
   - `eval/fixtures/{initiative}-research.md` (copy of baseline research)
   - `eval/fixtures/{initiative}-prd.md` (copy of baseline PRD)
   - `eval/fixtures/{initiative}-qa.json` (writer Q&A — needs to be captured)
   - `eval/fixtures/{initiative}-gate-answers.json` (always "continue")

---

## Run Matrix

18 runs total (9 configs x 2 initiatives):

| Run | Swapped agent | Phases that execute | Input source |
|---|---|---|---|
| **Baseline** | none (all opus) | full pipeline | live (captures fixtures) |
| **Swap A** | researcher -> sonnet | full pipeline | live brief, opus writer answers new Qs |
| **Swap B** | prd-writer -> sonnet | write + review | pinned research, replay Q&A |
| **Swap C** | prd-reviewer -> sonnet | review only | pinned PRD |
| **Swap D** | review-api -> sonnet | review only | pinned PRD |
| **Swap E** | review-structure -> sonnet | review only | pinned PRD |
| **Swap F** | review-flow -> sonnet | review only | pinned PRD |
| **Swap G** | review-requirements -> sonnet | review only | pinned PRD |
| **Swap H** | review-smells -> sonnet | review only | pinned PRD |

Swaps C-H are fast (review only). Swap B is medium. Swap A is the long one.

---

## Per-Run Output

Each run writes to `eval/exp6/{initiative}/{swap-id}/`:
- PRD (if writer ran)
- Research doc (if researcher ran)
- Review + handoff
- Writer Q&A log (if writer ran)
- JSONL entry appended to the shared log with experiment tags

---

## After All 18 Runs

Run the LLM-as-Judge on each PRD + review pair. Append `"judge"` entries to JSONL. Then you have a complete dataset for analysis.

---

## What We'll Be Able to Answer

- Which agent degrades most on sonnet? (FAIL delta per swap)
- Which matrix is most model-sensitive? (failsByMatrix comparison)
- Does sonnet writer ask different questions? (novel question count)
- Does sonnet researcher miss endpoints? (research diff)
- Is review quality uniform across sub-reviewer swaps? (Swaps D-H comparison)
- Time/cost savings per swap (duration delta)

---

## Implementation Steps

1. [ ] Fix logging gaps (experiment metadata, Q&A log, judge entry type, artifact isolation)
2. [ ] Build `/evaluate` skill with experiment runner loop
3. [ ] Run baseline for transaction-history (captures fixtures)
4. [ ] Run baseline for brclub (captures fixtures)
5. [ ] Run Swaps C-H for both initiatives (review-only, fast)
6. [ ] Run Swap B for both initiatives (write + review)
7. [ ] Run Swap A for both initiatives (full pipeline)
8. [ ] Run LLM-as-Judge on all 18 outputs
9. [ ] Analyze results
