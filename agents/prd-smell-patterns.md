# Requirements Smell Patterns

Canonical list of linguistic anti-patterns in requirements. Used by the PRD reviewer
and its sub-agents when evaluating FR and AC quality.

Source: Femmer et al., TU Munich, 2017 — adapted for PRD review.

---

- **Vague verb**: "handle", "manage", "process", "support", "deal with" — require a concrete verb (display, send, reject, store, calculate)
- **Loophole**: "if possible", "as appropriate", "when feasible", "as needed", "where applicable" — gives dev permission to skip
- **Ambiguous pronoun**: "it", "they", "this" without clear antecedent in same sentence
- **Passive voice hiding actor**: "is validated", "is shown" — WHO does it? The system, the API, the user?
- **Open-ended list**: "etc.", "and so on", "such as" used as substitute for a complete list
- **Superlative/comparative**: "fastest", "better", "optimal" — unmeasurable without baseline
- **Incomplete conditional**: "if X then Y" without specifying what happens when X is false
- **Subjective language**: "user-friendly", "intuitive", "clean", "simple", "seamless" — not testable
