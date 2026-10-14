#!/usr/bin/env bash
# Runs the test suite headless. Fails if any test fails OR if Godot printed a
# script error anywhere (errors in game code don't always fail a test directly).
#
#   tests/run.sh                    # all tests, Godot from $GODOT or PATH
#   tests/run.sh --filter=story     # only matching files/methods
#   GODOT=/path/to/godot tests/run.sh
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . -s res://tests/run_tests.gd -- --test-mode "$@" 2>&1 | tee "$LOG"
status=${PIPESTATUS[0]}

if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
	echo ""
	echo "FAILED: Godot reported script errors:"
	grep -E -A2 "SCRIPT ERROR|Parse Error" "$LOG" | head -40
	exit 1
fi
exit "$status"
