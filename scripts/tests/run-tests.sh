#!/usr/bin/env bash
#
# Test harness for scripts/prd-lint.py.
#
# Asserts:
#   1. clean-prd.md      — exit 0, zero violations (no unexpected IDs)
#   2. violations-prd.md — exit 1, every `<!-- expect: LINT-00N -->` annotation
#                          is matched by a reported violation with the same ID
#                          on that line (+/- 1 line tolerance)
#   3. violations-prd.md — at least one violation for each of LINT-001..LINT-009
#   4. violations-review.md — same annotation contract in --mode review, and at
#                          least one violation for each of LINT-101..LINT-103
#   5. a missing input file exits 2
#
# Usage: bash scripts/tests/run-tests.sh
# Exits non-zero on any assertion failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT="$SCRIPT_DIR/../prd-lint.py"
FIXTURES="$SCRIPT_DIR/fixtures"
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

# --------------------------------------------------------------------------
# 1. Clean fixture: exit 0, zero violations
# --------------------------------------------------------------------------
clean_out="$TMP_DIR/clean.json"
"$PY" "$LINT" "$FIXTURES/clean-prd.md" --format json >"$clean_out" 2>&1
clean_status=$?
if [ "$clean_status" -ne 0 ]; then
  fail "clean-prd.md exited $clean_status (expected 0)"
  cat "$clean_out"
else
  pass "clean-prd.md exits 0"
fi

clean_total="$("$PY" - "$clean_out" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as fh:
        print(json.load(fh)["counts"].get("total", -1))
except Exception:
    print(-1)
PYEOF
)"
if [ "$clean_total" = "0" ]; then
  pass "clean-prd.md reports zero violations (no unexpected IDs)"
else
  fail "clean-prd.md reported $clean_total violation(s) (expected 0)"
  cat "$clean_out"
fi

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

printf '\n'
if [ "$failures" -eq 0 ]; then
  printf 'All prd-lint tests passed.\n'
  exit 0
fi
printf '%d prd-lint test(s) failed.\n' "$failures"
exit 1
