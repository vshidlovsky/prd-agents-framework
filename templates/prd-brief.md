# {Initiative Name} — Product Brief

<!-- GUIDE (delete all GUIDE comments in the output)
The product brief is the human-readable PRD. It is generated from the full spec
(the latest `{initiative}-prd-v*.md`) and never edited by hand.
Readers: PMs, business, design, dev leads, QA. They should understand WHAT changes
and WHY in one read, without learning the framework's notation.
Rules: plain language; short sentences; no [V#] markers; no "System MUST";
no "(PM, date)" tags; no references readers can't open (meeting codes, Q&A numbers);
no code, endpoints, field names (except analytics names in section 6).
The brief explains the product; the spec keeps the details. Nothing is decided here.
-->

## TL;DR

<!-- GUIDE: 2–4 bullets. What we're building, for whom, and the one safety rule (e.g. "if X fails, works as today"). -->

- {bullet}

---

## 1. Problem and why now

<!-- GUIDE: The problem in user and business terms, what exists today, why now (competitors, new capability). Then the user story. -->

- {bullet}

**User story.** As a {user}, I want {goal}, so {benefit}.

## 2. Goals and success metrics

| Goal | How we measure it | Target |
|---|---|---|
| **{goal}** | {metric in plain words} | {value or TBD with owner} |

## 3. Non-goals

<!-- GUIDE: What this feature deliberately doesn't do. One line each, with a short reason when there is one. -->

- {item}

## 4. Terms

<!-- GUIDE: Readers are the app team. Only concepts this feature introduces, or domain words with a feature-specific meaning. No existing app screens or elements, no common IT vocabulary, no description of what a UI element contains or looks like. Product constants go below the table. -->

| Term | Meaning |
|---|---|
| **{term}** | {meaning} |

**Product constant — PC-1:** {constant, value, what it bounds}.

---

## 5. User experience and requirements

<!-- GUIDE: Start with the one-line flow. Then one subsection per screen/step in flow order,
then "who sees it" (gate) first and "when things go wrong / change mid-flow" last.
Each requirement: **R-NN — Short title.** One or two sentences of observable behavior,
then sub-bullets for rules. Add a worked example only when it carries a number, an ordering, or a non-obvious case.
Write each requirement around one thing the user experiences, in your own words — not around the spec's FR/AC/edge-case structure.
"As today" is fine for behavior the feature does not change. -->

The flow: **{step → step → step}.** Anything not mentioned works as today.

### 5.1 Who sees it

- **R-01 — The gate.** {Feature elements} show only when **all** of these are true:
  - {condition};
  - {condition}.

  If any is false, {what the user sees instead}.

### 5.2 {Screen / step}

- **R-0N — {title}.** {behavior}
  - Example: {worked example}

### 5.N When things go wrong or change mid-flow

- **R-NN — {title}.** {behavior}

### 5.N Accessibility

- **R-NN.** {behavior}

---

## 6. Analytics

<!-- GUIDE: Analytics is product-owned and part of the requirements.
First the questions we want answered, then rules, then the event table.
Every event names the question(s) it answers. Event and property names belong here. -->

**What we want to learn**

| # | Question |
|---|---|
| Q1 | {question} |

**Rules**

- **R-NN.** {rule, e.g. event limits, when new properties are sent}

**Events**

| # | Answers | Event | When | Adds |
|---|---|---|---|---|
| AE-1 | Q1 | `{event}` — existing/new | {trigger} | {properties} |

## 7. Support

<!-- GUIDE: What support must be able to answer, not the runbook: one bullet per user complaint, naming the cases support must tell apart. No lookup steps, no escalation paths, no event IDs. -->

- **R-NN.** Support must be able to answer, by user and time:
  - **"{complaint}"** {cases to tell apart}

## 8. Rollout and control

- {toggle, default, kill switch}

---

## 9. Dependencies

| Dependency | Owner | Status |
|---|---|---|
| {what is needed} | {team — ticket link} | {status} |

## 10. Assumptions and risks

| # | Assumption / risk | Source | If wrong |
|---|---|---|---|
| A-1 | {assumption} | {source readers can open} | {impact} |

## 11. Open questions

<!-- GUIDE: The spec's open questions that still matter, plus contradictions you found (one row each, naming both versions in a sentence). Never resolve a contradiction yourself. -->

| # | Question | Ask | Note |
|---|---|---|---|
| OQ-N | {question} | {owner} | {note} |

---

## References

<!-- GUIDE: Document info. Take each value from the spec; if the spec doesn't state it, write "Not stated in the spec" — never guess a name, version or status. -->

| Item | Link / value |
|---|---|
| **Full spec (PRD)** | [{spec file name}](./{spec file name}) — the source of truth; all details live there |
| **Product owner / author** | {name from the spec} |
| **Status** | {status from the spec} |
| **Spec version** | {version or last-changed date from the spec's changelog} |
| **Brief version** | {Brief vN — increment by 1 if a brief already exists at the output path, else v1} |
| **Brief generated** | {YYYY-MM-DD} by `prd-brief-author` from `{spec file name}`. Do not edit by hand — regenerate from the spec. |
| **Business case** | {link} |
| **Other references** | {links} |

---

## Appendix A — Notes for tech and design

<!-- GUIDE: Optional. Short notes from the spec that the tech or design team would want flagged; the spec has the rest:
who computes what, data the feature needs, flag key ownership, exact copy/formats, colors, icons, QA setup. -->

### A.1 Tech

- {note}

### A.2 Design

- {note}

### A.3 QA setup

- {note}

