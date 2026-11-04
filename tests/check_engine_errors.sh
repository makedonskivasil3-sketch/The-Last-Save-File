#!/usr/bin/env bash
# Prints every engine error in a test log that the case printing it doesn't
# cause on purpose (tests/allowed_engine_errors.txt); exits 1 if there is one.
#   tests/check_engine_errors.sh <log> [allowlist]
# Each error belongs to the case whose "  RUN   <case>" line came last; one
# before any case is "(startup)", one after the summary is "(exit)".
set -uo pipefail
LOG="$1"
ALLOW="${2:-$(dirname "$0")/allowed_engine_errors.txt}"
OUT=$(awk -v allow="$ALLOW" '
	BEGIN {
		while ((getline line < allow) > 0) {
			if (line ~ /^#/ || line == "") continue
			i = index(line, "|"); n++; t[n] = substr(line, 1, i - 1); r[n] = substr(line, i + 1)
		}
		cur = "(startup)"
	}
	/^  RUN   / { cur = $0; sub(/^  RUN   /, "", cur); next }
	/^==== / { cur = "(exit)" }
	/^(USER )?ERROR: / { ok = 0; for (k = 1; k <= n; k++) if (cur == t[k] && $0 ~ r[k]) ok = 1; if (!ok) print cur ": " $0 }
' "$LOG")
if [ -n "$OUT" ]; then
	echo "$OUT"
	exit 1
fi
exit 0
