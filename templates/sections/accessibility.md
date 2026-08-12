# Section Pack: Accessibility

> **Insert into**: Behavioral Contract — after Edge Cases [position: 1]
> **When**: Features with forms, modals/dialogs/sheets, or complex interactions. Recommended for all user-facing features.

### Accessibility

> **GUIDE**
> **What**: Screen reader, focus management, and accessibility requirements.
> **Why**: Accessibility is a quality baseline. Specifying it in the PRD ensures it's built in, not bolted on.
> **How**: Cover:
> - Semantic labels for non-text elements (icons, images, badges)
> - Focus order in forms
> - Focus management after modal/sheet open and close, step transitions
> - Keyboard navigation (Tab order, Enter/Space activation) — for web
> - Screen reader behavior (VoiceOver/TalkBack) — for mobile
> **Slim mode — outcomes, not mechanisms**: feature-specific rows state what must be perceivable and operable — a message is announced to assistive technology when it appears, an affordance is reachable by keyboard, a state is not conveyed by color alone, a control's name conveys its destination. Mechanisms — live-region politeness levels ("announce politely/assertively"), focus targets, announcement wording — are design/dev-owned under the project's accessibility shared-requirement baseline. A focus rule is admissible only as an outcome: "an ignored repeat activation must not trap or move focus" passes; "focus stays on the retry affordance" does not.
