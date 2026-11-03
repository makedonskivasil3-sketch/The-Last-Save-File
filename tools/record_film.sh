#!/bin/sh
# Records an observer's film of the game, start to finish, as an MP4:
#   1. a fresh profile: the title, the memory card and the festival (tests/tour_film_opening.gd);
#   2. the run to an ending, played by the ending bot, pausing on every
#      story page for its reading time (BOT_READ=1).
# Needs Godot 4.3, ffmpeg and a display (xvfb-run on a server).
#   tools/record_film.sh [out.mp4] [bot filter, default test_full_game_message]
set -e
cd "$(dirname "$0")/.."
OUT=${1:-film.mp4}
BOT=${2:-test_full_game_message}
GODOT=${GODOT:-godot}
TMP=$(mktemp -d)
export XDG_DATA_HOME="$TMP/data"
RUN="$GODOT --path . --rendering-driver opengl3 --fixed-fps 30"
command -v xvfb-run >/dev/null && [ -z "$DISPLAY" ] && RUN="xvfb-run -a -s '-screen 0 1280x720x24' $RUN"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
eval "$RUN --write-movie '$TMP/1_opening.avi' -s res://tests/run_tests.gd -- --test-mode --tour --filter=tour_film_opening"
BOT_READ=1 eval "$RUN --write-movie '$TMP/2_run.avi' -s res://tests/run_tests.gd -- --test-mode --bots --filter=$BOT"
for f in 1_opening 2_run; do
	ffmpeg -loglevel error -y -i "$TMP/$f.avi" -c:v libx264 -preset veryfast -crf 26 -pix_fmt yuv420p -c:a aac -b:a 128k "$TMP/$f.mp4"
done
printf "file '%s'\nfile '%s'\n" "$TMP/1_opening.mp4" "$TMP/2_run.mp4" > "$TMP/list.txt"
ffmpeg -loglevel error -y -f concat -safe 0 -i "$TMP/list.txt" -c copy "$OUT"
rm -rf "$TMP"
echo "Film written to $OUT"
