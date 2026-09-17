#!/usr/bin/env bash
# Step 1. One chart. The assistant wrote the values. Did they do anything?
# No ConfigHub server, no account, no cluster.
source "$(dirname "$0")/../lib/demo.sh"

CHART=(oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11)

# The chart comes from a public registry. The first run with a network keeps a
# copy outside the repository, and a run without a network uses that copy.
# DEMO_OFFLINE=1 uses the copy without looking for the registry.
KEPT="${XDG_CACHE_HOME:-$HOME/.cache}/workshop-demo/redis-0.34.11"
CHART_READY=0

chart_ready() {
  [ "$CHART_READY" = "1" ] && return 0
  CHART_READY=1
  if [ "${DEMO_OFFLINE:-0}" != "1" ] && curl -s -o /dev/null --max-time 4 https://registry-1.docker.io/v2/; then
    if [ ! -d "$KEPT/redis" ]; then
      rm -rf "$KEPT.part"; mkdir -p "$KEPT.part"
      if helm pull "${CHART[@]}" --untar --untardir "$KEPT.part" >/dev/null 2>&1; then
        rm -rf "$KEPT"; mv "$KEPT.part" "$KEPT"
      else
        rm -rf "$KEPT.part"
      fi
    fi
    return 0
  fi
  if [ ! -d "$KEPT/redis" ]; then
    echo
    bold "The chart registry cannot be reached, and this machine has no kept copy of the chart."
    dim  "Run this demo once with a network, or show the files in expected/."
    exit 1
  fi
  say "The chart registry cannot be reached, so this run uses the copy of the chart kept from an earlier run."
  rm -rf "$WORK/chart"; mkdir -p "$WORK/chart"; cp -R "$KEPT/redis" "$WORK/chart/redis"
  CHART=("$WORK/chart/redis")
}

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
  chart_ready
  say "Helm takes the file without a word. The render looks healthy."
  show_into "$WORK/redis.yaml" helm template shop-redis "${CHART[@]}" --namespace shop -f values.yaml
  show cub config check "$WORK/redis.yaml"
}

step_3() {
  chart_ready
  say "The chart is rendered once with your values, then once more for each value with that value taken out."
  show cub config values "${CHART[@]}" --values values.yaml
}

step_4() {
  say "The assistant used another chart's names. This chart reads the same settings somewhere else, and it counts every pod, so two replicas is replicaCount 3."
  show_diff values.yaml values-fixed.yaml
}

step_5() {
  chart_ready
  show cub config values "${CHART[@]}" --values values-fixed.yaml
}

step_6() {
  chart_ready
  say "Render the fixed values, and compare the two sets of objects."
  show_into "$WORK/redis-fixed.yaml" helm template shop-redis "${CHART[@]}" --namespace shop -f values-fixed.yaml
  show cub config diff "$WORK/redis.yaml" "$WORK/redis-fixed.yaml"
}

step_7() {
  chart_ready
  say "With --exit-code the same check fails a build when a value did nothing."
  show_refusal cub config values "${CHART[@]}" --values values.yaml --exit-code
}

reset_demo() { rm -rf "$WORK"; }

demo_main "$@"
