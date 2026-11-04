#!/usr/bin/env bash
# The error gate's own regression (tests/check_engine_errors.sh): it must
# fail an unexpected error, a deliberate error in the wrong case, and one
# outside any case, and pass the allowed one. Run by CI before the suite.
set -u
cd "$(dirname "$0")/.."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
printf 'x.case_a|^ERROR: Parse JSON failed\\.\n' > "$T/allow"
fail=0
check() {  # <name> <expected exit> <log text>
	printf '%b' "$3" > "$T/log"
	tests/check_engine_errors.sh "$T/log" "$T/allow" > /dev/null; got=$?
	if [ "$got" != "$2" ]; then echo "FAIL: $1 (exit $got, expected $2)"; fail=1; else echo "PASS: $1"; fi
}
check "a clean log passes" 0 '  RUN   x.case_a\n  PASS  x.case_a\n==== 1 passed, 0 failed (1.0s) ====\n'
check "a deliberate error in its own case passes" 0 '  RUN   x.case_a\nERROR: Parse JSON failed. Error at line 0: Expected key\n  PASS  x.case_a\n'
check "the same error in another case fails" 1 '  RUN   x.case_b\nERROR: Parse JSON failed. Error at line 0: Expected key\n'
check "a freed lambda capture fails" 1 '  RUN   x.case_a\nERROR: Lambda capture at index 0 was freed. Passed "null" instead.\n'
check "an error before any case fails" 1 'ERROR: Failed to load script\n  RUN   x.case_a\n'
check "an error after the summary fails" 1 '  RUN   x.case_a\n==== 1 passed, 0 failed (1.0s) ====\nERROR: 3 resources still in use at exit\n'
check "a user error (push_error) fails" 1 '  RUN   x.case_a\nUSER ERROR: something broke\n'
exit $fail
