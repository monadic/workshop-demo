#!/usr/bin/env bash
# Step 1. One chart. The assistant wrote the values. Did they do anything?
# No ConfigHub server, no account, no cluster.
source "$(dirname "$0")/../lib/demo.sh"

CHART=(oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11)

STEPS=(
  "Read what the assistant wrote"
  "Let Helm render it, and see what it would install"
  "Ask which of those values did anything"
  "Put each setting where this chart reads it"
  "Ask again"
  "See what the fix changes in the objects"
  "Make it a gate"
)

step_1() {
  say "You asked for a password, two replicas, a 1Gi disk, a memory limit and metrics. This came back."
  show cat values.yaml
}

step_2() {
  say "Helm takes the file without a word. The render looks healthy."
  show_into "$WORK/redis.yaml" helm template shop-redis "${CHART[@]}" --namespace shop -f values.yaml
  show cub config check "$WORK/redis.yaml"
}

step_3() {
  say "The chart is rendered once with your values, then once more for each value with that value taken out."
  show cub config values "${CHART[@]}" --values values.yaml
}

step_4() {
  say "The assistant used another chart's names. This chart reads the same settings somewhere else, and it counts every pod, so two replicas is replicaCount 3."
  show_diff values.yaml values-fixed.yaml
}

step_5() {
  show cub config values "${CHART[@]}" --values values-fixed.yaml
}

step_6() {
  say "Render the fixed values, and compare the two sets of objects."
  show_into "$WORK/redis-fixed.yaml" helm template shop-redis "${CHART[@]}" --namespace shop -f values-fixed.yaml
  show cub config diff "$WORK/redis.yaml" "$WORK/redis-fixed.yaml"
}

step_7() {
  say "With --exit-code the same check fails a build when a value did nothing."
  show_refusal cub config values "${CHART[@]}" --values values.yaml --exit-code
}

reset_demo() { rm -rf "$WORK"; }

demo_main "$@"
