# Project Context

> Fill this file once per project. The PRD agents read it before every run.
> Delete the `> GUIDE` blocks after filling each section.

---

## Project Identity

> GUIDE: One paragraph. What this project is, who uses it, what problem it solves.

- **Name**: [project name]
- **Description**: [one sentence — what it does and for whom]
- **Tech stack**: [language, framework, build tool — e.g., "Java 17, Spring Boot 3.2, Gradle"]
- **Repo**: [GitHub URL]
- **Repo structure**: [monorepo with multiple apps / single service / multi-repo system]

---

## Repo Layout

> GUIDE: Map the key directories so agents know where to look.
> Adapt the entries below to match your project — delete rows that don't apply, add rows that do.

| Path | Contains |
|------|----------|
| `src/main/java/...` | Application source code |
| `src/test/java/...` | Unit and integration tests |
| `docs/` | Documentation, API specs |
| `src/main/resources/` | Configuration files |

---

## API Documentation

> GUIDE: The project-setup agent creates `docs/api-sources.md` during setup — a consolidated index
> of every API documentation source (Swagger files, registries, code annotations, external URLs).
> The researcher reads this file to find API contracts and refuses to proceed if it doesn't exist.

- **Location**: `docs/api-sources.md`

---

## Domain Glossary

> GUIDE: Business terms that agents must understand to write correct PRDs.
> Only include terms that aren't obvious from the code — things a new team member would need explained.

| Term | Definition |
|------|-----------|
| [term] | [what it means in this project's context] |

---

## Conventions

> GUIDE: Naming, structure, and patterns that PRDs and research docs should follow.

- **File naming**: [snake_case / kebab-case / PascalCase]
- **Branch naming**: [pattern — e.g., "feature/JIRA-123-description"]
- **Commit style**: [conventional commits / free-form / etc.]
- **Test location**: [co-located / separate tree / both]

---

## PRD Configuration

### Output Paths

> GUIDE: Where agents save their output files and find templates.

- **PRD template**: [e.g., `docs/prd-template.md`]
- **Section packs directory**: [e.g., `docs/prd-sections/`]
- **Research docs**: [e.g., `docs/initiatives/{initiative}/{initiative}-research.md`]
- **PRDs**: [e.g., `docs/initiatives/{initiative}/{initiative}-prd.md`]
- **Reviews**: [e.g., `docs/initiatives/{initiative}/{initiative}-prd-review.md`]
- **Handoff files**: [same directory as the PRD, `.json` extension]
- **Lessons**: `.claude/prd-lessons.md` (auto-managed — reviewer proposes, user approves)

### PRD Versioning

> GUIDE: How PRD versions are tracked. Set to "none" if you don't need versioning.

- **Style**: [versioned filenames (`-v1`, `-v2`) / single file with changelog / none]

### Included Section Packs

> GUIDE: List which section packs from `templates/sections/` apply to this project.
> The prd-writer will include these sections in every PRD. The prd-reviewer will validate them.

Check the sections that apply to your project. Uncheck the rest.

- [x] screen-flow — Mermaid screen flow diagrams
- [x] navigation — Entry points, back behavior, deep links
- [x] analytics-events — Analytics event definitions
- [x] localization — Localization keys and translations
- [x] component-mapping — UI component to design system mapping
- [x] feature-flags — Feature flags / remote config
- [x] accessibility — Accessibility requirements
- [ ] design-prototype — Screen-to-visual-authority mapping (projects with DS/Storybook/Figma prototypes)
- [ ] user-journey — Tap-by-tap navigation path (frontend/mobile)
- [ ] responsive-layout — Responsive breakpoint behavior (web)
- [ ] database-changes — DB schema changes and migrations (backend)
- [ ] service-integration — Upstream/downstream service contracts (backend)
- [ ] monitoring — Monitoring, alerting, SLA targets (backend)
- [ ] compliance — Compliance / KYC triggers (fintech)
- [ ] platform-considerations — iOS/Android differences (mobile)

### Custom Section Packs

> GUIDE: If your project needs sections not covered by the built-in packs, add them here.
> Each custom pack is a markdown file following the same format as the built-in packs
> (frontmatter with "Insert into" tag, a GUIDE block, and the section template).
> The prd-writer includes them, the prd-reviewer validates they are filled in.

Custom section pack files (one path per line, or "none"):

- none

### Project-Specific Review Checks

> GUIDE: Additional review checks beyond the universal ones.
> The prd-reviewer runs these ON TOP OF the 8 universal checks.
> Write each as a checklist the reviewer can verify against the codebase.

Add one table per custom check, or leave this section empty if none apply.

<!-- EXAMPLE — DELETE EVERYTHING BETWEEN THESE MARKERS AFTER COPYING
#### Example: Spring Security
| # | Check Item |
|---|-----------|
| 1 | Every new endpoint specifies required roles via @PreAuthorize |
| 2 | No endpoint is unintentionally public |

#### Example: Remote Config Naming
| # | Check Item |
|---|-----------|
| 1 | Firebase console key uses SCREAMING_SNAKE_CASE with domain prefix |
| 2 | Dart enum member uses camelCase |
| 3 | Code fallback is false |
END EXAMPLE — DELETE -->

---

## Research Configuration

### Codebase Research Strategy

> GUIDE: How the researcher agent should navigate the codebase.

- **Knowledge base**: [path to .ai-docs/ if it exists, or "none"]
- **Entry points for research**: [where to start looking — e.g., "controllers in src/main/java/**/controller/", "screens in lib/presentation/"]
- **API tracing method**: [e.g., "follow @RestController → @Service → @Repository", "follow Widget → Cubit → Repository → ApiService"]
- **Permalink format**: [e.g., `https://github.com/{org}/{repo}/blob/{COMMIT_SHA}/{path}` for GitHub, `https://gitlab.com/{org}/{repo}/-/blob/{COMMIT_SHA}/{path}` for GitLab, or "none" for local-only repos]

### Custom Research Steps

> GUIDE: Additional research steps the researcher executes after the standard codebase scan.
> Each step is a markdown file in `docs/research-steps/` describing what to do, where to look, and what section to add to the research output.
> Use this for cross-repo checks, external API lookups, compliance database queries, or any project-specific research needs.
> Keep research steps separate from section packs (`docs/prd-sections/`) — they serve different agents at different pipeline stages.

Check the steps that apply. Each file must define: **When** (always, or condition), **What To Do** (numbered instructions), **Where To Look** (paths/URLs), and **Output Section** (section name and what to include).

- none

### Research Scope

> GUIDE: What directories to search and what to skip.

- **Include**: [list of paths the researcher should search]
- **Exclude**: [list of paths to skip — e.g., test fixtures, generated code, other apps in a monorepo]
