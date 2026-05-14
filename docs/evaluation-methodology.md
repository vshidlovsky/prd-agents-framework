# Evaluation Methodology for the PRD Agents Framework

A structured approach to testing and validating the framework's quality across model configurations. Designed to support a research paper with quantitative, reproducible results.

---

## Overview

The evaluation uses four complementary methods, each answering a different question:

| Method | Question it answers | Evidence type |
|--------|-------------------|---------------|
| Seeded Defect Study | Does the reviewer catch known issues? | Precision, recall, F1 |
| LLM-as-Judge | How good are the PRDs on multiple quality dimensions? | Rubric scores (1-5) |
| Ablation Study | What's the cost-quality tradeoff across model profiles? | Run log metrics |
| Consistency Study | How reliable are the results across repeated runs? | Variance statistics |

Human expert evaluation validates the LLM-as-Judge on a small sample.

---

## 1. Seeded Defect Study

The primary quantitative method. Plant known defects into PRDs and measure detection rates.

Adapted from software inspection research (Basili & Selby, 1987) and requirements smell validation (Femmer et al., 2017).

### Setup

1. Create or select 3-5 "clean" PRDs — human-validated, zero real defects, covering different project types (frontend, backend, mobile, greenfield).

2. For each PRD, systematically inject 10-15 defects from the framework's defect taxonomy:

   | Category | Example seeded defect |
   |----------|----------------------|
   | Omission | Remove an edge case for a nullable field |
   | Ambiguity | Replace a concrete verb with "handle" or "manage" |
   | Inconsistency | Make two FRs contradict each other on a business rule |
   | Incorrect Fact | Change an API endpoint path to one that doesn't exist |
   | Extraneous Info | Add an architecture decision (DI registration, file structure) |
   | Misplaced Requirement | Put an FR in the edge cases table |

3. Also seed smell-specific defects to test the smell detection pipeline:

   | Smell pattern | Example |
   |--------------|---------|
   | Vague verb | "System MUST handle payment errors" |
   | Loophole | "Display fee breakdown if possible" |
   | Ambiguous pronoun | "When the user selects a recipient, it is validated" |
   | Passive voice | "The transaction is approved" (by whom?) |
   | Open-ended list | "Support Visa, Mastercard, etc." |
   | Incomplete conditional | "If balance > $500, show warning" (no else case) |
   | Subjective language | "Provide a seamless transfer experience" |

4. Record a defect manifest: defect ID, category, location in PRD, exact text, expected detection matrix (e.g., "should be caught by Matrix B, Smell Flags column").

### Execution

Run the reviewer on each seeded PRD. For each model profile (reliable, cost-optimized, all-sonnet):

```
For each PRD (3-5):
  For each profile (3):
    Run prd-reviewer → produces review + run log
    Map each FAIL to a seeded defect (or mark as false positive)
    Record: which seeded defects were caught, which were missed
```

Total runs: 3-5 PRDs × 3 profiles = 9-15 review runs.

### Metrics

For each profile, compute:

- **Recall** = seeded defects caught / total seeded defects
- **Precision** = true FAILs / total FAILs reported (false positives = FAILs not matching any seeded defect)
- **F1** = harmonic mean of precision and recall

Break down by:
- Defect category (omission, ambiguity, inconsistency, etc.)
- Matrix (A, B, C, D1, D2, E, F, G)
- Smell pattern (vague verb, loophole, etc.)
- Model profile

### What to report

- Table: recall per defect category × model profile
- Table: precision per model profile
- Chart: F1 score across profiles (shows the cost-quality tradeoff curve)
- Heatmap: detection rate per matrix × profile (shows which sub-agents degrade most on cheaper models)

### References

- Basili, V.R. & Selby, R.W. (1987). "Comparing the Effectiveness of Software Testing Strategies." IEEE TSE.
- Femmer, H. et al. (2017). "Rapid Quality Assurance with Requirements Smells." Journal of Systems and Software.
- Berry, D.M. et al. (2012). "The Case for Dumb Requirements Engineering Tools." REFSQ.

---

## 2. LLM-as-Judge

Use a separate LLM instance to score PRD + review quality on a rubric. Scales to more initiatives than human evaluation.

Based on G-Eval (Liu et al., 2023) and LLM-as-Judge methodology (Zheng et al., 2023).

### Rubric

Score each PRD on 7 dimensions, 1-5 scale:

| Dimension | 1 (Poor) | 3 (Adequate) | 5 (Excellent) |
|-----------|----------|--------------|---------------|
| **Completeness** | Missing sections, open questions remain | All sections present, minor gaps | Every section filled, zero open questions, all tiers addressed |
| **Precision** | Vague requirements, multiple smells | Mostly concrete, occasional ambiguity | Every FR atomic, every AC testable, zero smells |
| **API Accuracy** | Endpoints unverified or wrong | Most endpoints verified, minor param mismatches | Every endpoint verified against docs, request/response shapes match |
| **Edge Case Coverage** | Ad hoc, major gaps | Covers obvious cases, misses boundary values | Systematic generation (entity × dimension), all checklists applied |
| **Testability** | ACs require reading code to verify | Most ACs testable from running app | Every AC verifiable from the running application |
| **Consistency** | FRs contradict each other, terms shift meaning | Minor inconsistencies | Zero contradictions, terms used consistently throughout |
| **Implementability** | Developer would need significant clarification | Developer could implement with minor questions | Developer could implement with zero clarification |

### Judge configuration

- **Judge model**: Use a model at least as capable as the one being evaluated. For evaluating Opus outputs, use Opus from a different provider or a rubric-bound Opus instance with a different system prompt. For evaluating Sonnet outputs, Opus is acceptable as judge.

- **Chain-of-thought scoring**: The judge must explain its reasoning for each dimension before assigning a score. This improves alignment with human judgment (G-Eval).

- **Judge prompt structure**:
  ```
  You are evaluating a Product Requirements Document and its review.
  
  Score the PRD on each dimension using the rubric below.
  For each dimension:
  1. Quote specific evidence from the PRD (good or bad)
  2. Explain your reasoning
  3. Assign a score (1-5)
  
  [rubric table]
  
  PRD to evaluate:
  [PRD content]
  
  Review produced by the framework:
  [review content]
  ```

- **Bias controls**:
  - Run each evaluation twice with dimensions in different order — average the scores
  - Do not reveal which model profile produced the PRD
  - Normalize for PRD length (longer ≠ better)

### Validation against human scores

Select 5 PRDs from the evaluation set. Have 3+ human evaluators (PMs and engineers) score them on the same rubric. Compute:

- **Inter-annotator agreement**: Krippendorff's alpha (α > 0.67 is acceptable, α > 0.80 is good)
- **Judge-human correlation**: Spearman rank correlation between LLM judge scores and human mean scores per dimension
- Report correlation per dimension — some dimensions (API Accuracy) may correlate better than others (Implementability)

### What to report

- Table: mean score per dimension × model profile
- Scatter plot: LLM judge scores vs human scores (validation)
- Correlation coefficient per dimension

### References

- Zheng, L. et al. (2023). "Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena." NeurIPS.
- Liu, Y. et al. (2023). "G-Eval: NLG Evaluation using GPT-4 with Better Human Alignment." EMNLP.
- Shankar, S. et al. (2024). "Who Validates the Validators? Aligning LLM-Assisted Evaluation of LLM Outputs with Human Preferences." 

---

## 3. Ablation Study

Use the framework's model profile system and run logs to measure cost-quality tradeoffs.

### Experiments

| # | Experiment | What varies | Control | Metric |
|---|-----------|------------|---------|--------|
| 1 | **Model tier** | reliable vs cost-optimized vs all-sonnet | Same initiative, same PRD | Run log quality metrics |
| 2 | **Agent removal** | Skip researcher (writer works from brief only) | Full pipeline | PRD API accuracy, completeness |
| 3 | **Review depth** | Single-agent review vs parallel (4 sub-agents) | Same PRD | FAIL count, detection rate, time |
| 4 | **Smell detection** | With vs without smell patterns file | Same PRD | Ambiguity FAIL count in Matrix B/C |
| 5 | **Revision cycles** | 0 max vs 1 max vs 3 max | Same PRD, same initial review | Final FAIL count convergence |
| 6 | **Individual agent swap** | Swap one agent at a time to Sonnet | Reliable profile as baseline | Per-matrix FAIL delta |

Experiment 6 is the most informative for the model profile design: it isolates which agent's quality degrades most when moved to a cheaper model.

### Execution

For experiments 1, 3, and 6, use the same 5 initiatives across all configurations:

```
For each initiative (5):
  For each configuration:
    Run /create-prd → run log produced
    Collect: timing, quality metrics, prdSize
```

### Metrics from run logs

The run logs already capture everything needed:

| Run log field | What it measures |
|--------------|-----------------|
| `agentDurationSeconds` | Speed (excluding human wait) |
| `quality.failCount` | Overall quality |
| `quality.failsByMatrix` | Per-agent quality (maps to sub-reviewer responsibility) |
| `quality.smellDetection` | Smell detection capability |
| `quality.spotCheckOverrides` | Phase 3 catch rate (did the orchestrator override sub-agents?) |
| `quality.defectTaxonomy` | Which defect types are affected |
| `prdSize.*` | Normalization basis |
| `phases.review.subAgents.agents.*` | Per-agent timing |

### Cost estimation

Token counts aren't in the run logs, but cost can be estimated:

```
Estimated cost = Σ (agent_duration × tokens_per_second_estimate × price_per_token)
```

Or more practically: check Anthropic dashboard usage for each run's time window. The run log's `startedAt` / `completedAt` timestamps plus `modelMap` make this straightforward.

### What to report

- Table: quality metrics per configuration (experiments 1-5)
- Chart: cost (or time) vs quality across model profiles (Pareto frontier)
- Heatmap: per-matrix FAIL delta when swapping individual agents (experiment 6)
- Line chart: FAIL count convergence across revision cycles (experiment 5)

---

## 4. Consistency Study

Measure output variance across repeated runs with identical inputs.

### Setup

Select 3 initiatives of varying complexity:
- Small (< 20 extractable items, single-agent review mode)
- Medium (20-50 items, parallel review mode)
- Large (50+ items, parallel review mode)

### Execution

```
For each initiative (3):
  For each profile (reliable, cost-optimized):
    Run /create-prd 5 times → 5 run logs
```

Total: 3 × 2 × 5 = 30 runs.

### Metrics

For each initiative × profile group (5 runs):

- **FAIL count**: mean, standard deviation, min, max
- **Stable FAILs**: defects caught in all 5 runs (reliable detections)
- **Flaky FAILs**: defects caught in 1-4 of 5 runs (unreliable detections)
- **Stability rate**: stable FAILs / (stable + flaky)
- **Per-matrix variance**: standard deviation of FAIL count per matrix
- **Smell detection variance**: std dev of `smellsFound` across runs
- **Timing variance**: std dev of `agentDurationSeconds`

### What to report

- Table: stability rate per initiative × profile
- Chart: FAIL count distribution (box plot, 5 runs per group)
- List: which specific defects are flaky and in which matrix (indicates where the framework's judgment is least reliable)

---

## Recommended evaluation tools

| Tool | Use for | Notes |
|------|---------|-------|
| [Promptfoo](https://github.com/promptfoo/promptfoo) | Model comparison, custom assertions, ablations | Open source, YAML-based config, supports side-by-side diffs |
| [DeepEval](https://github.com/confident-ai/deepeval) | G-Eval metric (LLM-as-Judge with CoT), automated scoring | Python, built-in rubric scoring, integrates with pytest |
| [Braintrust](https://www.braintrust.dev/) | Evaluation platform with comparison views, scoring | Good for tracking evals over time |

For the seeded defect study, a custom script that maps reviewer FAILs to the defect manifest is simplest — the tools above are more useful for the LLM-as-Judge and ablation workflows.

---

## Paper structure suggestion

```
1. Introduction
   - Problem: PRDs are bottleneck, AI can help but quality is uncertain
   - Contribution: multi-agent framework + systematic evaluation

2. Related Work
   - AI-assisted requirements engineering
   - Multi-agent LLM systems
   - LLM evaluation methodology

3. Framework Design
   - Pipeline architecture (researcher → writer → reviewer)
   - Review methodology (perspective-based reading, smell detection, matrix-driven)
   - Configurable model profiles

4. Evaluation
   4.1 Seeded Defect Study — precision, recall, F1
   4.2 LLM-as-Judge — rubric scores, validated against human
   4.3 Ablation Study — cost-quality tradeoffs
   4.4 Consistency Study — reliability across runs

5. Results
   - Which defect types are caught reliably?
   - Where does Sonnet degrade vs Opus?
   - What's the Pareto frontier of cost vs quality?
   - How stable are the results?

6. Discussion
   - Limitations (token cost not directly measurable, human gate timing noise)
   - Threats to validity
   - Practical implications for teams adopting the framework

7. Conclusion
```

---

## Relevant research to cite

**Requirements engineering + AI:**
- Berry, D.M. et al. (2012). "The Case for Dumb Requirements Engineering Tools." REFSQ.
- Femmer, H. et al. (2017). "Rapid Quality Assurance with Requirements Smells." JSS.
- Dalpiaz, F. et al. (2019). "Requirements Engineering in the Days of Artificial Intelligence." IEEE Software.

**Software inspection and review:**
- Basili, V.R. & Selby, R.W. (1987). "Comparing the Effectiveness of Software Testing Strategies." IEEE TSE.
- Basili, V.R. et al. (1996). "The Empirical Investigation of Perspective-Based Reading." Empirical Software Engineering.
- Porter, A. et al. (1995). "Comparing Detection Methods for Software Requirements Inspections." IEEE TSE.

**LLM evaluation methodology:**
- Zheng, L. et al. (2023). "Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena." NeurIPS.
- Liu, Y. et al. (2023). "G-Eval: NLG Evaluation using GPT-4 with Better Human Alignment." EMNLP.
- Shankar, S. et al. (2024). "Who Validates the Validators?"
- Chang, Y. et al. (2024). "A Survey on Evaluation of Large Language Models." ACM TIST.

**LLM agents and multi-agent systems:**
- Jimenez, C.E. et al. (2024). "SWE-bench: Can Language Models Resolve Real-World GitHub Issues?" ICLR.
- Liu, X. et al. (2023). "AgentBench: Evaluating LLMs as Agents." ICLR.
- Wang, L. et al. (2024). "A Survey on Large Language Model Based Autonomous Agents."

**Defect taxonomy:**
- IEEE 1044-2009. "Standard Classification for Software Anomalies."
- Walia, G.S. & Carver, J.C. (2009). "A Systematic Literature Review to Identify and Classify Software Requirement Errors." IST.
