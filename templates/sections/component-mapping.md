# Section Pack: Component Mapping

> **Insert into**: Technical (after API Endpoints)
> **When**: Any frontend/mobile feature using a design system or component library.

### Component Mapping

> **GUIDE**
> **What**: Table mapping every UI element to a specific design system component, file path, and key props.
> **Why**: Makes the PRD implementation-ready. Without this, devs pick components by guessing, leading to inconsistent UI.
> **How**: One row per distinct UI element. If a needed component doesn't exist, flag it as a gap — don't include it here.

| UI Element | Component | Source File |
|-----------|-----------|-------------|
| [what the user sees] | `<ComponentName prop="value" />` | `path/to/component` |
