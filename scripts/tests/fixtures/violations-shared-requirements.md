# Shared Requirements

Fixture for `--mode shared-requirements`: stale patterns from previous
framework generations that the migration scan must flag. Each violating line
carries an `<!-- expect: LINT-2NN -->` annotation.

---

## SR-01: Authenticated access

Every page behind sign-in redirects unauthenticated visitors to the sign-in
screen. This SR is current and must not be flagged.

## SR-15: Localization

PRDs must include a Localization section listing all user-facing strings with keys and translations for all 4 languages. <!-- expect: LINT-201 -->

Each feature's Localization Keys table is reviewed by the translation vendor. <!-- expect: LINT-201 -->

## SR-16: API documentation

Every PRD must include a Technical Contract with a Data Sources table listing each endpoint. <!-- expect: LINT-202 -->

Per-endpoint error tables are required for every endpoint the feature reads or writes. <!-- expect: LINT-202 -->

## SR-17: Copy review

Error messages in ACs must quote the literal string shown to the user. <!-- expect: LINT-203 -->

Marketing-approved final copy is required in the PRD before review. <!-- expect: LINT-203 -->

## SR-18: Corrected rule (must not fire)

Copy, localization keys, and translations are design-owned; the PRD does not contain a Localization section.

```text
Fenced examples are never scanned: PRDs must include a Localization section
listing all user-facing strings with keys and translations for all 4 languages.
```
