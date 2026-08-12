# Shared Requirements

Cross-cutting requirements that every PRD inherits by reference.
PRDs reference SR IDs — they do not restate SR content inline.

**Ownership**: PM-owned. Agents consume but never modify without explicit user approval.

---

## SR-01: Authenticated access

Every page behind sign-in redirects unauthenticated visitors to the sign-in
screen and returns them to their original destination after a successful
sign-in.

## SR-02: Internationalization from day one

The product supports four languages: en, es, pt-BR, tl. Every feature must
work in all supported languages from its first release. Copy, localization
keys, and translations are design-owned — the PRD describes copy intent per
state and never contains a Localization section, literal strings, or keys.

## SR-03: Responsive breakpoints

Every page supports three breakpoints: mobile (up to 767px), tablet
(768-1023px), desktop (1024px and up). A PRD's responsive-layout rows use
exactly these three breakpoints and pixel values; deviations require an
explicit override in the PRD's Shared Requirements section.

## SR-04: Error recovery

Every failed data load offers the user a way to retry without losing entered
state. Error presentation must distinguish "we could not reach the service"
from "the service rejected the request".

## SR-05: Accessibility baseline

Every interactive element is keyboard-reachable and screen-reader labeled.
Modal dialogs trap focus while open and restore focus on close.
