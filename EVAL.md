# EVAL.md — how to evaluate a new framework version

Methodology for testing whether a framework change actually improved anything, distilled from a
full two-arm evaluation of a major release (the "worked example" numbers below). Reuse this
every time a release claims to make PRDs better.

**The one rule that governs everything:** an LLM reviewer is a noisy instrument. In our
test-retest study, the same reviewer on the same frozen PRD returned 12, 14, 24, and 24 FAIL
cells across four runs — a 2× spread, with different headline defects each time. Therefore:

> Count deltas are *suggestive* unless they exceed the measured noise band.
> Mechanism deltas are *conclusive* — a behavior that only exists where the machinery exists
> cannot be produced by sampling luck.
> A blind judge is a *tiebreaker*, never the verdict.

## The four tiers

Run the cheapest tier that can answer your question. Most releases ship on Tiers 0–2.

### Tier 0 — CI (free, every commit)
`python3 scripts/check-docs.py` + `bash scripts/tests/run-tests.sh`. Catches doc drift,
count mismatches, banned-term regressions, script breakage. Already enforced on every PR.

### Tier 1 — Asymmetric review (~400k tokens, every release)
Run the NEW reviewer + `scripts/prd-lint.py` against 1–2 PRDs the OLD framework approved.
Then run a deflation pass (the senior-PM agent, or a manual audit) on the result before
believing any number:
- Collapse FAIL cells to root causes — cells triple-count defects across matrices.
- Attribute each finding to the check that produced it. "New-standard catch" claims must be
  verified against the old framework's actual text (keep a copy of the old version; in the
  worked example, ~61 claimed new-standard cells deflated to ~12, and to 2 confirmed real
  defects).
- Treat what the old reviewer *should have caught but didn't* as variance data, not as a win.

### Tier 2 — Mechanism checks (~free, every release)
For each changed rule, one artifact-level assertion that dice cannot fake:
- **Same instrument, both artifacts**: run the identical lint script over an old-framework
  final and a new-framework final (worked example: 39 violations vs 0).
- **Gate fired**: count writer self-catches the old framework structurally cannot produce
  (worked example: 12 wire-value leaks caught pre-review by the lint gate).
- **Behavior exists only where machinery exists**: e.g., zero re-litigation of rejected
  findings across all revision cycles is only possible with a decision-memory layer.
- **Question asked that the old framework cannot ask**: a section pack or checklist that
  didn't exist producing a question is structural, not stochastic.

### Tier 3 — Full two-arm comparison (~10M tokens, major versions only)
The complete ceremony. Only when the release is big enough to justify it:

1. **Pre-register** before any run: hypotheses, metric stack in trust order, known biases,
   and the commitment to publish nulls. Freeze it.
2. **Inputs held constant**: one brief, pasted verbatim into both arms; a decision sheet
   written *before* the runs from source-of-truth evidence; every agent question answered
   only from the sheet; out-of-sheet questions answered once and reused verbatim in the
   other arm. Run the old arm first (learning bias then favors old — a new-arm win is
   stronger).
3. **Isolation**: two git worktrees from the same commit; the old framework restored from a
   dated backup of the consuming project (the authentic system as it ran, not a
   reconstruction).
4. **Same cycle cap for both arms** (we use 3). An arm that doesn't converge is recorded as
   terminal at its cap — no extensions.
5. **Cross-review (2×2)**: each terminal PRD reviewed by BOTH framework versions. The
   off-diagonal cells are the signal; root-cause-collapse and spot-verify before counting.
6. **Test-retest band (E-2)**: 3+ fresh reviews of one frozen terminal PRD by the same
   reviewer. This calibrates every count in the study. The band survives across releases
   until the reviewer changes materially.
7. **Blind judge panel — two role-based lenses, not one generic judge.** Strip titles and
   changelogs (they reveal revision history), randomize A/B, each judge scores with citations
   and reports whether blinding held. The standing panel:
   - **Tech Lead lens** — ticketability, guessCount (count the actual would-have-to-ask
     instances — the single most decision-relevant number a judge produces), contract
     fidelity, failure-mode coverage, implementation freedom, estimability.
   - **Senior PM lens** — value per requirement, scope sanity, over-specification priced as
     a DEFECT, decision quality, outcome-based success criteria (would they fail if the
     feature flops?).
   Do NOT use a generic conformance/completeness judge as a verdict source: in the worked
   example it systematically rewarded volume (verbosity bias) — the heavier, grind-bloated
   document beat the leaner one until a lens priced gold-plating as a defect, which flipped
   the verdict by the panel's widest margin. Layer-scoped cuts (e.g., behavioral-only) are
   one-off instruments for specific design questions, each with a pre-registered hypothesis
   — not standing fixtures.
   **Tie rule: a margin of ≤3 points on these rubrics is a tie, full stop.** Single-run judge
   scores inherit the reviewer-noise problem; the judges' real product is their *cited,
   decisive differences*, not their totals. Never re-run or add judges to break a tie —
   that is judge-shopping; every judge run publishes.
8. **Human pick** — the final metric and the tiebreaker: which document would you actually
   hand to a builder.

## Standing assets (create once, reuse)

- The pre-registration template and the metric trust-order.
- The noise band from the last E-2 run (currently: 12–24 FAIL cells, 8–16 distinct defects
  on a ~1,200-cell review of a ~140KB PRD).
- A lab notebook, updated as events happen — numbers logged after the fact get lost or
  flattering.
- A dated backup (tarball) of the consuming project's installed framework before each major
  upgrade — it is the only authentic "old arm" you will ever have.

## Contamination traps (all hit in the worked example — design around them)

1. **Shared external state**: GitHub issues filed by one arm are visible to the other.
   Either block issue-filing during runs or log every filing as a contamination event.
2. **Shared artifact names**: both arms writing "corrected by <initiative>" into their own
   copies of a reference doc produces false FAILs when a cross-reviewer greps the wrong
   worktree. Give arms distinct initiative names, or forbid cross-worktree reads entirely
   and verify by content.
3. **Repo-wide greps leak prior verdicts**: reviewers grepping for a symbol will surface
   earlier review files. Instruct agents to exclude review artifacts from search paths and
   to disclose any leak plus re-derive the affected cells independently.
4. **The judging environment carries one arm's edits**: verify factual disputes directly in
   code, and have the judge disclose environment artifacts.

## Operational lessons

- **Transient API failures are routine at this scale** (6 in the worked example, including a
  session limit that killed three parallel runs at once). Resume agents from their
  transcripts rather than restarting; log every interruption — resumed runs are disclosed in
  the results.
- **Degraded review modes are results too**: record whether each run completed in parallel,
  degraded-parallel, or single mode; modes are not directly comparable.
- **Coaching is a disclosure**: if the orchestrator gives one arm guidance its framework
  doesn't provide (e.g., "resolve root causes before cells"), record it and state which arm
  it favored.
- **Expect a split verdict and publish it**: in the worked example, counts favored the new
  version (inside noise), mechanisms clearly favored it (conclusive), and the blind judge
  narrowly favored the old document twice — partly because the old arm's brute-force
  revision grind forced hardening (a test-coverage section, extra instrumentation) that the
  new framework had dropped or relocated. A split like this is not a failed eval; it is the
  eval working — each disagreement names a concrete next improvement.

## Worked example (major release, two arms, one initiative)

| Measure | Old arm | New arm | Reading |
|---|---|---|---|
| Cycle-1 review FAIL cells | 89 | 64 | inside noise band — suggestive only |
| Cycles to READY (cap 3) | never (11 at cap) | never (12 cells / 9 defects at cap) | neither converged |
| New defects introduced per revision | 15, then 2 | 6, then 5 | ticket-based revision halves, doesn't cure |
| Lint on finals (same script) | 39 | 0 | **conclusive** |
| Writer self-catches pre-review | — (no gate) | 12 | **conclusive** |
| Rejected findings re-litigated | n/a (no mechanism) | 0 of 9 over 3 cycles | **conclusive** |
| Cross-review, other ruler's distinct defects | 28 found in old PRD | 13 found in new PRD | direction consistent, counts noisy |
| Blind judge — conformance lens | 31/35 | 29/35 | tie by the ≤3 rule; lens later retired for verbosity bias |
| Blind judge — behavioral layer only | 28/30 | 25/30 | tie by the ≤3 rule; strict separation moves content out of the judged layer |
| Blind judge — senior PM lens | 17/30 | 23/30 | new — over-specification priced as a defect flips the verdict |
| Blind judge — tech lead lens | 24/30 | 25/30 | tie by the ≤3 rule; guessCount: old ~6 + a hard stop, new ~4 + one silent trap |
| Human pick | — | ✓ | final |
| Total tokens | ~1.7M | ~2.6M | the judgment layer costs ~50% more |

Verdict shape: the release changed *process behavior* conclusively; document-quality deltas
were within noise and the judge split. The eval's product was not a winner — it was the next
release's backlog.
