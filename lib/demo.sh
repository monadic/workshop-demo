#!/usr/bin/env bash
# Shared step runner for the three demos.
#
#   ./run.sh            walk every step, pausing before each command
#   ./run.sh 3          run step 3 only
#   ./run.sh --list     list the steps
#   ./run.sh --reset    remove everything the demo created
#   DEMO_AUTO=1 ./run.sh    no pauses (rehearsal, or recording expected/ output)
#   DEMO_RECORD=1 DEMO_AUTO=1 ./run.sh    also save each step's output in expected/
#
# A demo defines step_1 .. step_N and a STEPS array of titles, then calls
# demo_main "$@". Inside a step, use `show` for a command that should succeed
# and `show_refusal` for one that is supposed to be refused.

set -u
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
# Every step runs from the demo's own folder, so the commands on screen use
# short relative paths and read the same on any machine.
cd "$DEMO_DIR"
WORK="work"
mkdir -p "$WORK"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }

pause() {
  [ "${DEMO_AUTO:-0}" = "1" ] && return 0
  # Talk to the terminal directly, so the prompt shows even when output is piped.
  printf '      press Enter to run ' >/dev/tty 2>/dev/null || return 0
  read -r _ </dev/tty || true
}

# render <command...>: the command as you would type it, with quotes kept.
render() {
  local out="" arg
  # A demo may wrap cub in a function named hub, to pick a context. Show it as cub.
  if [ "${1:-}" = "hub" ]; then shift; set -- cub "$@"; fi
  for arg in "$@"; do
    case "$arg" in
      *[!A-Za-z0-9_./:=@%+,-]*|"") out="$out \"$arg\"" ;;
      *) out="$out $arg" ;;
    esac
  done
  printf '%s' "${out# }"
}

# show <command...>: print the command, pause, run it. A failure stops the demo.
show() {
  printf '\n\033[36m$ %s\033[0m\n' "$(render "$@")"
  pause
  if ! "$@"; then
    echo
    bold "That command failed, and this step expected it to succeed."
    dim  "Fix the cause, or run ./run.sh --reset and start again."
    exit 1
  fi
}

# show_refusal <command...>: the same, for a command that is meant to be refused.
show_refusal() {
  printf '\n\033[36m$ %s\033[0m\n' "$(render "$@")"
  pause
  if "$@"; then
    echo
    bold "That command succeeded, and this step expected a refusal."
    exit 1
  fi
  dim "      (refused, exit code non-zero, as intended)"
}

# show_into <file> <command...>: run a command and keep what it prints in a file.
show_into() {
  local file=$1; shift
  printf '\n\033[36m$ %s > %s\033[0m\n' "$(render "$@")" "$file"
  pause
  if ! "$@" > "$file"; then
    echo
    bold "That command failed, and this step expected it to succeed."
    exit 1
  fi
}

# show_diff <a> <b>: a plain diff of two files. diff exits non-zero when they differ.
show_diff() {
  printf '\n\033[36m$ diff %s %s\033[0m\n' "$1" "$2"
  pause
  diff "$1" "$2" || true
}

say() { echo; echo "$*"; }

# explain <sentences>: what the next command does, said before it runs.
# look <sentences>: what to notice in the output it just printed.
# Both wrap to the terminal and sit indented, so they read apart from real output.
wrapped() { printf '%s\n' "$*" | fold -s -w 76 | sed 's/^/    /'; }
explain() { echo; printf '\033[33m'; wrapped "$*"; printf '\033[0m'; }
look()    { echo; printf '\033[32m'; wrapped "Look for $*"; printf '\033[0m'; }

run_step() {
  local n=$1
  echo
  bold "Step $n of ${#STEPS[@]}. ${STEPS[$((n-1))]}"
  # Live, a step talks straight to the terminal. When recording, absolute paths
  # become relative, colours are dropped, and anything that identifies the
  # person or organization who recorded it is replaced, so expected/ reads the
  # same anywhere and is safe to publish.
  if [ "${DEMO_RECORD:-0}" = "1" ]; then
    "step_$n" 2>&1 | sed -e "s|$DEMO_DIR/||g" -e "s|$HOME|~|g" \
      | tee >(sed -E \
          -e $'s/\033\\[[0-9;]*m//g' \
          -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/you@example.com/g' \
          -e 's/ --context [A-Za-z0-9_-]+//g' \
          -e 's/^(Context Name +).*/\1your-context/' \
          -e 's/^(Organization Name +).*/\1Your Organization/' \
          -e 's/^(Organization ID +).*/\100000000-0000-0000-0000-000000000000/' \
          -e 's/^(User ID +).*/\100000000-0000-0000-0000-000000000000/' \
          -e 's/^(Default Space +).*/\1default/' \
          -e 's/^(Token Status +).*/\1valid/' \
          -e '/^Selected By /d' \
          > "$DEMO_DIR/expected/step-$n.txt")
    return "${PIPESTATUS[0]}"
  fi
  "step_$n"
}

demo_main() {
  case "${1:-}" in
    --list)  local i=1; for t in "${STEPS[@]}"; do echo "  $i. $t"; i=$((i+1)); done ;;
    --reset) reset_demo; echo "reset done" ;;
    "")      local i; for i in $(seq 1 ${#STEPS[@]}); do run_step "$i" || exit $?; done
             echo; bold "Done. ./run.sh --reset removes what this demo created." ;;
    *[!0-9]*) echo "usage: ./run.sh [N | --list | --reset]"; exit 2 ;;
    *)       run_step "$1" ;;
  esac
}
