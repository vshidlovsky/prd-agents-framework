# Section Pack: Responsive Layout

> **Insert into**: Technical Contract [position: 1] (`full` mode) / Behavioral Contract — after Edge Cases [position: 2] (`slim` mode)
> **When**: Web applications that must work across viewport sizes.

#### Responsive Layout

> **GUIDE**
> **What**: How the page/feature behaves at different viewport sizes.
> **Why**: Layout must work at both mobile and desktop extremes.
> **How**: Reference layout components from the design system. Only specify viewport-specific behavior that the layout system doesn't handle automatically. Reference a shared layout baseline (page shell, loading presentation) by its SR id, never by component class name — the SR alias is the stable product name; the class is dev-owned wiring.

- [ ] [Mobile viewport: behavior that differs from desktop]
- [ ] [Desktop viewport: behavior that differs from mobile]
