# Section Pack: Design Prototype Mapping

> **Insert into**: Contract (after Acceptance Criteria, before Screen Flow)
> **When**: Projects with a design system, Storybook, or prototype components that serve as visual authority for implementation.

### Visual Source of Truth

> **GUIDE**
> **What**: A table mapping every screen or step to its visual reference — a DS prototype component, a Figma URL, or a blocker flag.
> **Why**: Every screen needs an authoritative visual reference that devs implement against and reviewers verify against. Without this, devs guess at layout and reviewers can't catch visual drift.
> **How**:
> - One row per screen or wizard step, in flow order.
> - **Visual Reference** column: link to a prototype file path (preferred), a Figma URL, or **"BLOCKED — no prototype"** if none exists (must have a corresponding issue or gap filed).
> - **Notes** column: intentional deviations from the prototype, or "Matches prototype" if none.
> - Before filling this table, search for existing prototype components in the codebase (check project-context.md for prototype locations).

| Screen / Step | Visual Reference | Notes |
|---|---|---|
| [Screen name] | Prototype: `path/to/prototype/component` | [Deviations, or "Matches prototype"] |
| [Screen name] | [Figma URL](https://...) | [Notes] |
| [Screen name] | **BLOCKED — no prototype** | Must be built before implementation |
