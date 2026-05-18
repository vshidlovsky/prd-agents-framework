# Behavioral/Technical Separation

PRDs MUST separate behavioral requirements from technical implementation details into two distinct sections: the **Behavioral Contract** and the **Technical Contract**.

## Core Principle

A requirement passes the behavioral test if a QA engineer can verify it without reading source code. If a requirement would break when an API field is renamed — but the observable behavior hasn't changed — it belongs in the Technical Contract.

## Behavioral Contract

Contains: FRs, ACs, Edge Cases, Key Entities, Success Criteria, Security, Accessibility, Compliance, Support/Observability.

Rules for this layer:
- Use **semantic concept names** for data attributes (e.g., "transaction identifier" not `tx_id`)
- Use **`[TC-*]` cross-reference anchors** to link concepts to their technical definitions
- Each semantic name maps to exactly one API field — if ambiguous, make it more specific
- **Never include**: API field names, endpoint paths, query keys, enum values, URL patterns, UI copy strings, analytics event names, pixel breakpoints, CSS class names, constructor signatures, framework-specific terminology

## Technical Contract

Contains: Data Sources, Query Configuration, Error Classification, Route Mapping, per-endpoint Field Mapping + Behavioral Mapping + Error Handling, Component Mapping, Localization Keys, Visual References, Screen Flow, MSW Mock Data, Configuration Attributes, Feature Flags.

Rules for this layer:
- **Cross-cutting concerns defined once**: Error classification, query config, route mapping each live in one table, referenced everywhere via anchors
- **Per-endpoint blocks** include: Field Mapping (API field → type → notes), Behavioral Mapping (which FRs/ACs each field drives + transformation rules), Error Handling (HTTP status → behavior)
- Every API field in a Field Mapping table SHOULD have a Behavioral Mapping entry tracing back to the FRs/ACs it supports

## `[TC-*]` Anchor Vocabulary

Fixed anchors (same for every PRD):

| Anchor | Section |
|--------|---------|
| `[TC-DS]` | Data Sources (endpoints, methods, paths) |
| `[TC-QC]` | Query Configuration (cache times, retry, stale behavior) |
| `[TC-EC]` | Error Classification (error types and display rules) |
| `[TC-RT]` | Route Mapping (route constants and navigation targets) |
| `[TC-CA]` | Configuration Attributes (env vars, base URLs) |
| `[TC-FF]` | Feature Flags (toggles and rollout config) |
| `[TC-CM]` | Component Mapping (UI components to source files) |
| `[TC-LK]` | Localization Keys (i18n string identifiers) |
| `[TC-VR]` | Visual References (screen-to-component mapping) |
| `[TC-SF]` | Screen Flow (route diagram with URLs) |
| `[TC-MSW]` | MSW Handlers (mock service worker test fixtures) |

Flexible anchors (initiative-specific, one per API endpoint consumed):

| Pattern | Example | Section |
|---------|---------|---------|
| `[TC-{XX}]` | `[TC-AM]` | Per-endpoint Field Mapping (Activity Mapping) |
| | `[TC-RM]` | Per-endpoint Field Mapping (Recipient Mapping) |
| | `[TC-UM]` | Per-endpoint Field Mapping (User Mapping) |

The prd-writer creates flexible anchors based on the initiative's data sources. The 2-letter code should be a mnemonic for the endpoint's semantic name.

## Detection

The prd-reviewer detects violations using the "Behavioral/Technical Separation Smells" in `agents/prd-smell-patterns.md`. Seven smell patterns cover: API field leaks, enum leaks, URL pattern leaks, UI copy in requirements, analytics event names inline, framework terminology, and design decisions in requirements.

## This Rule Applies To

- **prd-writer**: MUST produce separated Behavioral/Technical Contracts with `[TC-*]` cross-references
- **prd-reviewer**: MUST check for separation violations in FRs, ACs, and Edge Cases (FAIL for FRs/ACs, WARN for Edge Cases)
- **All agents**: MUST NOT embed technical details in the behavioral layer when writing or revising PRDs

This rule applies to all agents, skills, and conversations in this project.
