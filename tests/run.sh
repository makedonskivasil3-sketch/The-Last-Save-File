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
IMPORT_LOG="$(mktemp)"
trap 'rm -f "$LOG" "$IMPORT_LOG"' EXIT

if ! "$GODOT" --headless --path . --import >"$IMPORT_LOG" 2>&1; then
    cat "$IMPORT_LOG"
    echo "FAILED: Godot project import did not complete."
    exit 1
fi
if grep -qE "SCRIPT ERROR|Parse Error" "$IMPORT_LOG"; then
    cat "$IMPORT_LOG"
    echo "FAILED: Godot project import reported script errors."
    exit 1
fi
"$GODOT" --headless --path . -s res://tests/run_tests.gd -- --test-mode "$@" 2>&1 | tee "$LOG"
status=${PIPESTATUS[0]}

if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
	echo ""
	echo "FAILED: Godot reported script errors:"
	grep -E -A2 "SCRIPT ERROR|Parse Error" "$LOG" | head -40
	exit 1
fi
if ! grep -qE '^==== [1-9][0-9]* passed, 0 failed \([0-9.]+s\) ====$' "$LOG"; then
    echo "FAILED: no completed, non-empty successful test summary."
    exit 1
fi
exit "$status"
