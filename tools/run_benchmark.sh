#!/bin/sh
# Real-hardware benchmark (docs/RELEASE_READINESS.md, "Measuring on a real GPU").
# Needs: this repository and the Godot 4.3 editor binary (the benchmark uses
# the test harness, which exported builds don't include). Run it with a
# window on the machine being measured, nothing else heavy running.
#
#   GODOT=/path/to/Godot_v4.3-stable tools/run_benchmark.sh [out.json]
#
# Optional: BENCH_SECONDS (default 60), BENCH_WARMUP (5), BENCH_RUNS (3),
# BENCH_ONLY (e.g. "square,edge"). Results: out.json (default
# benchmark-<commit>.json here), plus a table on the console.
set -e
GODOT=${GODOT:-godot}
cd "$(dirname "$0")/.."
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
OUT=${1:-"$PWD/benchmark-$COMMIT.json"}
BENCH_COMMIT=$COMMIT BENCH_OUT="$OUT" "$GODOT" --path . -s res://tests/run_tests.gd -- --test-mode --tour --filter=tour_benchmark
echo "Results written to $OUT"
