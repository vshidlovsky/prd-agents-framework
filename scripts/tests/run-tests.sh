#!/usr/bin/env bash
#
# Test harness for the framework's scripts: prd-lint.py, validate-handoff.py,
# and run-log.py.
#
# prd-lint.py asserts:
#   1. clean-prd.md and clean-prd-slim.md — exit 0, zero violations (no
#                          unexpected IDs). Same PRD, the two Technical Contract
#                          modes. clean-prd.md is full mode AND the backward-
#                          compatibility fixture: it is deliberately left in the
#                          pre-slim shape (per-endpoint vocabulary + API tables,
#                          no behavioral anchors), so it proves a document
#                          written under the old template still lints clean.
#                          clean-prd-slim.md is the slim shape — Product
#                          Constants, Semantic Vocabulary and Display Rules in
#                          the behavioral layer, no PRD-owned API tables. One
#                          rule set has to keep both clean.
#   2. violations-prd.md — exit 1, every `<!-- expect: LINT-00N -->` annotation
#                          is matched by a reported violation with the same ID
#                          on that line (+/- 1 line tolerance)
#   3. violations-prd.md — at least one violation for each of LINT-001..LINT-009
#   3b. violations-prd-slim.md — the slim-mode shape: the LINT-009 slim-anchor
#                          branch, a `[V#]` that resolves against no Semantic
#                          Vocabulary row, a duplicate V-number inside one
#                          layer, both LINT-010 shapes, and transport taxonomy
#                          in an Analytics Events property cell (LINT-011).
#                          The slim-only checks are locked in the other
#                          direction too: clean-prd.md (full mode) carries
#                          `error_status_code` in its Error Classification
#                          table and still lints clean
#   4. violations-review.md — same annotation contract in --mode review, and at
#                          least one violation for each of LINT-101..LINT-103
#   5. a missing input file exits 2
#
# validate-handoff.py asserts (fixtures in handoff-fixtures/):
#   6. every *-valid.json exits 0 for its type, including the senior-pm
#      delta-mode fixture (ticketsVerified present)
#   7. every *-invalid.json exits 1 AND names each planted defect — the
#      required substrings live in the sibling `<fixture>.expect` file
#   8. senior-pm-inconsistent.json — every field well-typed, but the
#      cross-field invariants (dispositionCounts vs the arrays, delta mode vs
#      ticketsVerified, nextAgent vs ticket count) all violated
#   9. missing file, malformed JSON, and unsupported --type all exit 2
#
# run-log.py asserts:
#  10. `append` writes exactly one parseable line and round-trips values that
#      would break shell-quoted JSON (quotes, `$(…)`, backslashes)
#  11. `append --strict` refuses to write an entry missing required fields,
#      while the default run warns and still writes
#  12. `append --entry-type senior-pm` is accepted and keeps its nested
#      judgment metrics as JSON
#  13. `timing` reads epoch / ISO / delta values, and reports missing keys and
#      unreadable files with distinct exit codes
#
# Usage: bash scripts/tests/run-tests.sh
# Exits non-zero on any assertion failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/../prd-lint.py"
VALIDATE="$SCRIPT_DIR/../validate-handoff.py"
RUNLOG="$SCRIPT_DIR/../run-log.py"
FIXTURES="$SCRIPT_DIR/fixtures"
HANDOFFS="$SCRIPT_DIR/handoff-fixtures"
PY="${PYTHON:-python3}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

failures=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }

if [ ! -f "$LINT" ]; then
  printf 'FAIL  linter not found at %s\n' "$LINT"
  exit 1
fi
if [ ! -f "$VALIDATE" ]; then
  printf 'FAIL  handoff validator not found at %s\n' "$VALIDATE"
  exit 1
fi
if [ ! -f "$RUNLOG" ]; then
  printf 'FAIL  run-log writer not found at %s\n' "$RUNLOG"
  exit 1
fi

# --------------------------------------------------------------------------
# 1. Clean fixtures: exit 0, zero violations — one per Technical Contract mode
# --------------------------------------------------------------------------
assert_clean() {
  local fixture="$1" name out status total
  name="$(basename "$fixture")"
  out="$TMP_DIR/$name.clean.json"

  "$PY" "$LINT" "$fixture" --format json >"$out" 2>&1
  status=$?
  if [ "$status" -ne 0 ]; then
    fail "$name exited $status (expected 0)"
    cat "$out"
  else
    pass "$name exits 0"
  fi

  total="$("$PY" - "$out" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        print(json.load(fh)["counts"].get("total", -1))
except Exception:
    print(-1)
PYEOF
)"
  if [ "$total" = "0" ]; then
    pass "$name reports zero violations (no unexpected IDs)"
  else
    fail "$name reported $total violation(s) (expected 0)"
    cat "$out"
  fi
}

assert_clean "$FIXTURES/clean-prd.md"
assert_clean "$FIXTURES/clean-prd-slim.md"

# --------------------------------------------------------------------------
# Annotation assertion helper
# --------------------------------------------------------------------------
# assert_annotated <fixture> <mode> <required-id> [<required-id> ...]
assert_annotated() {
  local fixture="$1" mode="$2"
  shift 2
  local name report status
  name="$(basename "$fixture")"
  report="$TMP_DIR/$name.json"

  "$PY" "$LINT" "$fixture" --mode "$mode" --format json >"$report" 2>&1
  status=$?
  if [ "$status" -eq 1 ]; then
    pass "$name exits 1 (violations found)"
  else
    fail "$name exited $status (expected 1)"
    cat "$report"
    return
  fi

  if "$PY" - "$fixture" "$report" "$@" <<'PYEOF'
import json
import re
import sys

fixture, report = sys.argv[1], sys.argv[2]
required = sys.argv[3:]

with open(fixture, encoding="utf-8") as fh:
    lines = fh.read().split("\n")

annotation = re.compile(r"<!--\s*expect:\s*(LINT-\d+)\s*-->")
expected = []
for number, text in enumerate(lines, start=1):
    for match in annotation.finditer(text):
        expected.append((number, match.group(1)))

with open(report, encoding="utf-8") as fh:
    data = json.load(fh)
found = {(item["line"], item["id"]) for item in data["violations"]}
found_ids = {item["id"] for item in data["violations"]}

problems = []
if not expected:
    problems.append("no `<!-- expect: LINT-00N -->` annotations found in fixture")

for number, check_id in expected:
    if not any((number + delta, check_id) in found for delta in (-1, 0, 1)):
        at_line = sorted(i for (ln, i) in found if abs(ln - number) <= 1)
        problems.append(
            "line %d: expected %s, reported %s"
            % (number, check_id, ", ".join(at_line) or "nothing")
        )

for check_id in required:
    if check_id not in found_ids:
        problems.append("no violation reported for required check %s" % check_id)

if problems:
    for problem in problems:
        sys.stderr.write("      %s\n" % problem)
    sys.exit(1)

sys.stdout.write("%d annotation(s) matched, %d required check ID(s) present\n"
                 % (len(expected), len(required)))
PYEOF
  then
    pass "$name annotations all matched"
  else
    fail "$name annotation assertions failed"
  fi
}

assert_annotated "$FIXTURES/violations-prd.md" prd \
  LINT-001 LINT-002 LINT-003 LINT-004 LINT-005 LINT-006 LINT-007 LINT-008 LINT-009

assert_annotated "$FIXTURES/violations-prd-slim.md" prd \
  LINT-001 LINT-009 LINT-010 LINT-011

assert_annotated "$FIXTURES/violations-review.md" review \
  LINT-101 LINT-102 LINT-103

# --------------------------------------------------------------------------
# 5. Usage errors exit 2
# --------------------------------------------------------------------------
"$PY" "$LINT" "$FIXTURES/does-not-exist.md" >/dev/null 2>&1
missing_status=$?
if [ "$missing_status" -eq 2 ]; then
  pass "missing input file exits 2"
else
  fail "missing input file exited $missing_status (expected 2)"
fi

# ==========================================================================
# validate-handoff.py
# ==========================================================================

# assert_valid_handoff <type> <fixture>
assert_valid_handoff() {
  local type="$1" fixture="$2" name out status
  name="$(basename "$fixture")"
  out="$TMP_DIR/$name.out"
  "$PY" "$VALIDATE" --type "$type" "$fixture" >"$out" 2>&1
  status=$?
  if [ "$status" -eq 0 ]; then
    pass "$name validates clean as --type $type"
  else
    fail "$name exited $status as --type $type (expected 0)"
    cat "$out"
  fi
}

# assert_invalid_handoff <type> <fixture>
# Requires a sibling `<fixture>.expect` file: one required output substring per
# line (blank lines and `#` comments ignored), one per planted defect.
assert_invalid_handoff() {
  local type="$1" fixture="$2" name out status expect missing line
  name="$(basename "$fixture")"
  out="$TMP_DIR/$name.out"
  expect="${fixture%.json}.expect"

  "$PY" "$VALIDATE" --type "$type" "$fixture" >"$out" 2>&1
  status=$?
  if [ "$status" -eq 1 ]; then
    pass "$name exits 1 as --type $type (problems found)"
  else
    fail "$name exited $status as --type $type (expected 1)"
    cat "$out"
    return
  fi

  if [ ! -f "$expect" ]; then
    fail "$name has no .expect file at $expect"
    return
  fi

  missing=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '' | '#'*) continue ;; esac
    if ! grep -Fq -- "$line" "$out"; then
      printf '      not reported: %s\n' "$line"
      missing=$((missing + 1))
    fi
  done <"$expect"

  if [ "$missing" -eq 0 ]; then
    printf '      reported: %s\n' "$(sed -e '/^#/d' -e '/^$/d' "$expect" | wc -l | tr -d ' ') planted defect(s)"
    pass "$name reports every planted defect"
  else
    fail "$name missed $missing planted defect(s)"
    cat "$out"
  fi
}

for handoff_type in writer reviewer dispatch senior-pm; do
  assert_valid_handoff "$handoff_type" "$HANDOFFS/$handoff_type-valid.json"
  assert_invalid_handoff "$handoff_type" "$HANDOFFS/$handoff_type-invalid.json"
done

# Senior-PM delta mode: ticketsVerified present, re-issued ticket, zero
# escalations. Full mode is covered by senior-pm-valid.json above.
assert_valid_handoff senior-pm "$HANDOFFS/senior-pm-delta-valid.json"

# Senior-PM cross-field invariants: every field is individually well-typed, so
# only the count/mode/nextAgent agreement rules can catch this one.
assert_invalid_handoff senior-pm "$HANDOFFS/senior-pm-inconsistent.json"

# Usage errors: unreadable file, malformed JSON, unsupported type.
"$PY" "$VALIDATE" --type writer "$HANDOFFS/does-not-exist.json" >/dev/null 2>&1
status=$?
if [ "$status" -eq 2 ]; then
  pass "validate-handoff: missing handoff file exits 2"
else
  fail "validate-handoff: missing handoff file exited $status (expected 2)"
fi

printf 'not json at all\n' >"$TMP_DIR/malformed.json"
"$PY" "$VALIDATE" --type writer "$TMP_DIR/malformed.json" >/dev/null 2>&1
status=$?
if [ "$status" -eq 2 ]; then
  pass "validate-handoff: malformed JSON exits 2"
else
  fail "validate-handoff: malformed JSON exited $status (expected 2)"
fi

retro_err="$TMP_DIR/retro.err"
"$PY" "$VALIDATE" --type retro "$HANDOFFS/writer-valid.json" >/dev/null 2>"$retro_err"
status=$?
if [ "$status" -eq 2 ] && grep -Fq "unknown type" "$retro_err"; then
  pass "validate-handoff: --type retro exits 2 with 'unknown type'"
else
  fail "validate-handoff: --type retro exited $status (expected 2 + 'unknown type')"
  cat "$retro_err"
fi

"$PY" "$VALIDATE" --type nonsense "$HANDOFFS/writer-valid.json" >/dev/null 2>&1
status=$?
if [ "$status" -eq 2 ]; then
  pass "validate-handoff: unrecognized --type exits 2"
else
  fail "validate-handoff: unrecognized --type exited $status (expected 2)"
fi

# ==========================================================================
# run-log.py — append
# ==========================================================================

LOG="$TMP_DIR/run-log.jsonl"

"$PY" "$RUNLOG" append --log-file "$LOG" --entry-type researcher \
  --data '{"runId":"20260810-142200","agent":"researcher","model":"sonnet","cycle":1,"startedAt":"2026-08-10T14:22:00Z","completedAt":"2026-08-10T14:31:00Z","durationSeconds":540,"inputSummary":"brief","outputSummary":"research doc","artifactPath":"docs/x-research.md","handoffPath":null,"metrics":{"endpointsFound":2,"filesRead":31,"ambiguitiesFlagged":4}}' \
  --field 'initiative=search "filters" & $(whoami)' \
  >"$TMP_DIR/append.out" 2>"$TMP_DIR/append.err"
status=$?
if [ "$status" -eq 0 ]; then
  pass "run-log append: complete researcher entry exits 0"
else
  fail "run-log append: complete researcher entry exited $status (expected 0)"
  cat "$TMP_DIR/append.err"
fi

if [ ! -s "$TMP_DIR/append.err" ]; then
  pass "run-log append: complete entry emits no warnings"
else
  fail "run-log append: complete entry warned unexpectedly"
  cat "$TMP_DIR/append.err"
fi

# Injection round-trip: the shell-hostile value must survive verbatim.
if "$PY" - "$LOG" <<'PYEOF'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    lines = [line for line in fh.read().split("\n") if line.strip()]

problems = []
if len(lines) != 1:
    problems.append("expected exactly 1 log line, found %d" % len(lines))
else:
    entry = json.loads(lines[0])
    if entry.get("initiative") != 'search "filters" & $(whoami)':
        problems.append("initiative did not round-trip: %r" % entry.get("initiative"))
    if entry.get("entryType") != "researcher":
        problems.append("entryType not set from --entry-type: %r" % entry.get("entryType"))
    if entry.get("metrics", {}).get("filesRead") != 31:
        problems.append("nested metrics lost: %r" % entry.get("metrics"))

if problems:
    for problem in problems:
        sys.stderr.write("      %s\n" % problem)
    sys.exit(1)
sys.stdout.write("one line, quotes/dollar round-tripped, nested metrics intact\n")
PYEOF
then
  pass "run-log append: line parses and round-trips shell-hostile values"
else
  fail "run-log append: line failed the round-trip assertion"
  cat "$LOG"
fi

# --field values that parse as JSON become JSON; the rest stay strings.
TYPED_LOG="$TMP_DIR/typed.jsonl"
"$PY" "$RUNLOG" append --log-file "$TYPED_LOG" --entry-type terminated \
  --data '{"runId":"20260810-142200","initiative":"x","terminatedAt":"2026-08-10T15:00:00Z","diedInPhase":"writing","reason":"abandoned"}' \
  --field 'completedPhases=["research","gate1"]' >/dev/null 2>&1
status=$?
if [ "$status" -eq 0 ] && "$PY" - "$TYPED_LOG" <<'PYEOF'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    entry = json.loads(fh.readline())
sys.exit(0 if entry.get("completedPhases") == ["research", "gate1"] else 1)
PYEOF
then
  pass "run-log append: --field parses JSON values (array stays an array)"
else
  fail "run-log append: --field JSON value did not survive as JSON"
  cat "$TYPED_LOG"
fi

# The senior-pm entry type is accepted, and its nested judgment metrics survive.
SPM_LOG="$TMP_DIR/senior-pm.jsonl"
"$PY" "$RUNLOG" append --log-file "$SPM_LOG" --entry-type senior-pm \
  --data '{"runId":"20260810-142200","initiative":"x","agent":"prd-senior-pm","model":"fable","cycle":1,"startedAt":"2026-08-10T16:30:00Z","completedAt":"2026-08-10T16:41:00Z","durationSeconds":660,"inputSummary":"full judgment of 9 FAILs","outputSummary":"2 tickets, 2 rejected, 1 escalation","artifactPath":"docs/x-senior-pm-review.md","handoffPath":"docs/x-senior-pm-handoff.json"}' \
  --field 'metrics={"mode":"full","failsJudged":9,"rootCauses":5,"dispositionCounts":{"fixTechnical":1,"fixProduct":1,"reject":2,"escalate":1},"ticketCount":2,"escalations":1}' \
  >/dev/null 2>"$TMP_DIR/spm.err"
status=$?
if [ "$status" -eq 0 ] && [ ! -s "$TMP_DIR/spm.err" ] && "$PY" - "$SPM_LOG" <<'PYEOF'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    entry = json.loads(fh.readline())

problems = []
if entry.get("entryType") != "senior-pm":
    problems.append("entryType not set from --entry-type: %r" % entry.get("entryType"))
if entry.get("metrics", {}).get("dispositionCounts", {}).get("reject") != 2:
    problems.append("nested dispositionCounts lost: %r" % entry.get("metrics"))
if entry.get("model") != "fable":
    problems.append("model tier did not round-trip: %r" % entry.get("model"))

if problems:
    for problem in problems:
        sys.stderr.write("      %s\n" % problem)
    sys.exit(1)
sys.exit(0)
PYEOF
then
  pass "run-log append: senior-pm entry accepted with nested disposition counts"
else
  fail "run-log append: senior-pm entry failed (exit $status)"
  cat "$TMP_DIR/spm.err"
fi

# Default run warns about missing required fields but still writes the line.
LOOSE_LOG="$TMP_DIR/loose.jsonl"
"$PY" "$RUNLOG" append --log-file "$LOOSE_LOG" --entry-type pipeline \
  --data '{}' --field 'initiative=bare' >/dev/null 2>"$TMP_DIR/loose.err"
status=$?
if [ "$status" -eq 0 ] && [ "$(wc -l <"$LOOSE_LOG" | tr -d ' ')" = "1" ] \
  && grep -Fq "warning: pipeline entry is missing required field 'runId'" "$TMP_DIR/loose.err"; then
  pass "run-log append: incomplete entry warns on stderr and still writes"
else
  fail "run-log append: incomplete entry did not warn-and-write (exit $status)"
  cat "$TMP_DIR/loose.err"
fi

# --strict refuses to write.
STRICT_LOG="$TMP_DIR/strict.jsonl"
"$PY" "$RUNLOG" append --log-file "$STRICT_LOG" --entry-type pipeline \
  --data '{}' --strict >/dev/null 2>"$TMP_DIR/strict.err"
status=$?
if [ "$status" -eq 1 ] && [ ! -f "$STRICT_LOG" ] \
  && grep -Fq "error: pipeline entry is missing required field" "$TMP_DIR/strict.err"; then
  pass "run-log append --strict: exits 1 and writes nothing"
else
  fail "run-log append --strict: exited $status (expected 1, no file written)"
  cat "$TMP_DIR/strict.err"
fi

"$PY" "$RUNLOG" append --log-file "$TMP_DIR/bad.jsonl" --entry-type pipeline \
  --data '{not json}' >/dev/null 2>&1
status=$?
if [ "$status" -eq 2 ] && [ ! -f "$TMP_DIR/bad.jsonl" ]; then
  pass "run-log append: malformed --data exits 2 and writes nothing"
else
  fail "run-log append: malformed --data exited $status (expected 2)"
fi

"$PY" "$RUNLOG" append --log-file "$TMP_DIR/bad2.jsonl" --entry-type pipeline \
  --field 'novalue' >/dev/null 2>&1
status=$?
if [ "$status" -eq 2 ]; then
  pass "run-log append: --field without '=' exits 2"
else
  fail "run-log append: --field without '=' exited $status (expected 2)"
fi

# ==========================================================================
# run-log.py — timing
# ==========================================================================

TIMING="$TMP_DIR/run-timing.tmp"
{
  printf 'pipeline_start=1754800000 2025-08-10T04:26:40Z\n'
  printf 'research_start=1754800010\n'
  printf 'research_end=1754800130\n'
} >"$TIMING"

got="$("$PY" "$RUNLOG" timing --file "$TIMING" --get research_start 2>&1)"
if [ "$got" = "1754800010" ]; then
  pass "run-log timing --get returns the epoch value"
else
  fail "run-log timing --get returned '$got' (expected 1754800010)"
fi

got="$("$PY" "$RUNLOG" timing --file "$TIMING" --get pipeline_start --iso 2>&1)"
if [ "$got" = "2025-08-10T04:26:40Z" ]; then
  pass "run-log timing --get --iso returns the recorded ISO timestamp"
else
  fail "run-log timing --get --iso returned '$got' (expected 2025-08-10T04:26:40Z)"
fi

got="$("$PY" "$RUNLOG" timing --file "$TIMING" --get research_start --iso 2>&1)"
if [ "$got" = "2025-08-10T04:26:50Z" ]; then
  pass "run-log timing --get --iso derives ISO from a bare epoch"
else
  fail "run-log timing --get --iso derived '$got' (expected 2025-08-10T04:26:50Z)"
fi

got="$("$PY" "$RUNLOG" timing --file "$TIMING" --delta research_start research_end 2>&1)"
if [ "$got" = "120" ]; then
  pass "run-log timing --delta returns end - start in seconds"
else
  fail "run-log timing --delta returned '$got' (expected 120)"
fi

"$PY" "$RUNLOG" timing --file "$TIMING" --get gate9_prompt >/dev/null 2>&1
status=$?
if [ "$status" -eq 1 ]; then
  pass "run-log timing: unknown key exits 1"
else
  fail "run-log timing: unknown key exited $status (expected 1)"
fi

"$PY" "$RUNLOG" timing --file "$TMP_DIR/no-such-timing" --get pipeline_start >/dev/null 2>&1
status=$?
if [ "$status" -eq 2 ]; then
  pass "run-log timing: unreadable file exits 2"
else
  fail "run-log timing: unreadable file exited $status (expected 2)"
fi

printf '\n'
if [ "$failures" -eq 0 ]; then
  printf 'All tests passed (prd-lint, validate-handoff, run-log).\n'
  exit 0
fi
printf '%d test(s) failed.\n' "$failures"
exit 1
