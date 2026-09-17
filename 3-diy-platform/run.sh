#!/usr/bin/env bash
# Demo 3. Build your own platform from certified parts.
# No ConfigHub server, no account, no cluster. The last step says where an account takes it.
source "$(dirname "$0")/../lib/demo.sh"

STEPS=(
  "See the parts you can build with"
  "Read the platform two teams wrote together"
  "Certify it, and get refused"
  "Fix the manifest"
  "Certify it again"
  "Render the whole platform to one file"
  "Save it as a workspace you can edit and re-certify"
)

step_1() {
  say "Each shipped stack is a list of Catalog parts, pinned by digest."
  show cub stack list
}

step_2() {
  say "A cache, a database and metrics. Team B added metrics too, under another name."
  show cat stack-v1.yaml
}

step_3() {
  say "Certify reads every object in every part before anything renders."
  show_refusal cub stack certify stack-v1.yaml
}

step_4() {
  say "The fix is to take the duplicate out. These are the only lines that change."
  printf '\n\033[36m$ diff stack-v1.yaml stack-v2.yaml\033[0m\n'
  pause
  diff stack-v1.yaml stack-v2.yaml || true
}

step_5() {
  show cub stack certify stack-v2.yaml
}

step_6() {
  say "Thirty objects, in the order they have to be applied."
  show cub stack sandbox stack-v2.yaml --out "$WORK/platform.yaml"
  show grep -c "^kind:" "$WORK/platform.yaml"
}

step_7() {
  rm -rf "$WORK/my-platform"
  show cub stack sandbox stack-v2.yaml --workspace "$WORK/my-platform"
  show ls "$WORK/my-platform"
  say "With a ConfigHub account the same stack uploads as governed Spaces, and a fleet places it on clusters."
}

reset_demo() { rm -rf "$WORK"; }

demo_main "$@"
