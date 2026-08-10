# Section Pack: Analytics Events

> **Insert into**: Behavioral Contract — after Acceptance Criteria [position: 1]
> **When**: Any feature that should be instrumented with analytics events.
> **Separation note**: This table is the source of truth for event names and properties. FRs and ACs in the Behavioral Contract reference events using semantic trigger names (e.g., "the page-viewed analytics event") — not raw event names. The table itself holds the actual `event_name` values.

#### Analytics Events

> **GUIDE**
> **What**: All analytics events for this feature — view events and interaction events.
> **Why**: Every screen/page must fire a view event so user journeys are readable in analytics tools.
> **How**:
> - Follow the naming convention established in the codebase (check project-context.md or existing events)
> - Every screen/page MUST have a view event
> - Interaction events track what users do (taps, submissions, errors)
> - Include event properties when relevant
> - Check existing events in the codebase first to avoid duplicates
> - Every event gets a stable ID: AE-001, AE-002, ...
> - If the project maintains a central analytics event catalog (see Registry-Mirrored Catalogs in project-context.md), mirror every event addition, property change, and removal into the catalog in the same PRD edit — the lockstep applies to property updates and removals, not just new event names
>
> **AC-binding rules** (writer):
> - When an AC fires an analytics event, the AC MUST list every required property on that event, matching the Properties column in this table verbatim. Whenever this table is updated, grep every AC referencing that event and update the AC's property list in the same edit.
> - For every analytics event whose Trigger describes a successful data outcome (not just a user interaction), add an AC binding the event by name and listing every property. If any event in this table is named by zero ACs, it has no test surface.
> - ACs MUST reference events by AE-number (e.g., "fires AE-001"), NOT by literal event name inline. This table is the single source of truth for event names and properties; the AC asserts when the event fires and under what conditions.

| # | Event Name | Trigger | Properties | Description |
|---|---|---|---|---|
| AE-001 | `[event_name]` | [Screen becomes visible] | [properties] | [Screen view event] |
| AE-002 | `[event_name]` | [User action] | [properties] | [Interaction event] |
