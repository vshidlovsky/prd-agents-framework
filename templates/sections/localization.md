# Section Pack: Localization

> **Insert into**: Technical Contract [TC-LK]
> **When**: Any feature with user-facing text that should be localized.

### Localization Keys

> **GUIDE**
> **What**: User-facing strings that need localization keys, with translations for supported languages.
> **Why**: Centralizes all user-facing strings. Prevents hardcoded strings. Including translations in the PRD ensures they ship with the feature.
> **How**:
> 1. **Detect the i18n setup first**: Search the codebase for localization files (e.g., `*.arb`, `locales/*.json`, `*.properties`, `messages_*.yaml`). Identify: the i18n library (i18next, flutter_localizations, Spring MessageSource, etc.), the file format (JSON, ARB, YAML, properties), and which languages are currently supported.
> 2. **Match the existing format**: If the project uses nested JSON keys, use nested keys. If flat keys, use flat keys. Match the existing key naming convention.
> 3. **Include all supported languages**: Add a column for each language the project currently supports — check the existing locale files. Do not add languages that don't exist yet.
> 4. **Group keys by screen/flow area**: Include keys for labels, errors, empty states, buttons, tooltips.
> 5. Before translating, read existing localization files to match tone, terminology, and phrasing.
> 6. Use PRD context (screen flow, user story) to ensure translations fit the UI context.
> 7. **Attempt real translations first.** Only flag with `[VERIFY]` when genuinely uncertain about correctness — this should be rare, not the default. Tables full of `[VERIFY]` defeat the purpose of including translations in the PRD.

| Key | en | [column per supported language] | Notes |
|-----|----|----|-------|
| `feature_screen_title` | "Title" | "..." | |
| `feature_error_message` | "Something went wrong" | "..." | |
