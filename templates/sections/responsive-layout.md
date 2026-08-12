# Section Pack: Responsive Layout

> **Insert into**: Technical Contract [position: 1] (`full` mode) / Behavioral Contract — after Edge Cases [position: 2] (`slim` mode)
> **When**: Web applications that must work across viewport sizes.

#### Responsive Layout

> **GUIDE**
> **What**: How the page/feature behaves at each breakpoint the project's responsive shared requirement defines.
> **Why**: The breakpoint set is a project-level product decision, not a per-PRD choice. A hand-picked viewport list drifts from the project's actual breakpoints and silently skips whole device classes.
> **How**: Before writing, open the project's responsive shared requirement (the SR named in project-context.md / `docs/shared-requirements.md`) and enumerate its breakpoints. Write **one checklist row per breakpoint in that SR, using the SR's pixel values** — never example viewports, and never a subset. Each row states only the behavioral facts at that breakpoint: what is present, what is reachable. Reference layout components from the design system; only specify breakpoint-specific behavior that the layout system doesn't handle automatically. Reference a shared layout baseline (page shell, loading state) by its SR id, never by component class name — the SR alias is the stable product name; the class is dev-owned wiring.
> **Row-set discipline**: a row set that differs from the SR's breakpoint set — a missing breakpoint, or a viewport the SR does not define — requires an explicit override in Shared Requirements → Feature-specific overrides with justification; without one the reviewer FAILs the section. If the project has no responsive SR, state that on the section's first line and list the viewports agreed with design.
> **Slim mode — outcomes, not composition**: per-breakpoint rows state what is present and what the user can still do — every named element is present, nothing requires horizontal scrolling, the same information is available at every breakpoint. Never prescribe how content is arranged or stacked ("renders as a single column", "stacked in that order") — layout arrangement and content ordering are the design deliverable; point at the visual reference / `ds-gap` issue that owns them.

- [ ] [First breakpoint per the responsive SR, with its pixel value: behavioral facts at this breakpoint]
- [ ] [Second breakpoint per the responsive SR: behavioral facts]
- [ ] [...one row for every remaining breakpoint the SR defines]
