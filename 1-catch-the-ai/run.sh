#!/usr/bin/env bash
# Started as "zsh run.sh" or "sh run.sh"? Carry on under bash, which this needs.
[ -n "${BASH_VERSION:-}" ] && case ":${SHELLOPTS:-}:" in *:posix:*) false ;; esac || exec bash "$0" "$@"
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
  explain "cat prints the values file the assistant wrote. Nothing is run or installed."
  show cat values.yaml
  look "anything wrong. Most people find nothing. Every setting you asked for is there, in tidy YAML."
}

step_2() {
  chart_ready
  say "Helm takes the file without a word. The render looks healthy."
  explain "helm template fetches the Redis chart from its public registry and fills it in with your values. It writes the Kubernetes objects it would install to work/redis.yaml. Nothing reaches a cluster."
  show_into "$WORK/redis.yaml" helm template shop-redis "${CHART[@]}" --namespace shop -f values.yaml
  look "a complaint from Helm. There is none. It exits 0, and that is the trap."
  explain "cub config check reads that file and lists what it would install, and any setup work such as CRDs, hooks or Jobs. It runs on this laptop, with no account."
  show cub config check "$WORK/redis.yaml"
  look "7 objects and four PASS lines. By every usual sign, this is a healthy install."
}

step_3() {
  chart_ready
  say "So which of your values did anything?"
  explain "cub config values renders the chart with your values, then once more for each value with that one value taken out. If the objects come out the same either way, that value did nothing. It also reads the chart's own defaults, to say where the chart does read that setting. No value is printed."
  show cub config values "${CHART[@]}" --values values.yaml
  look "the three IGNORED lines, and the last line, 3 of 7 values did nothing. Your disk size, memory limit and replica count never reached Redis."
}

step_4() {
  say "The assistant used another chart's names. This chart reads the same settings somewhere else, and it counts every pod, so two replicas is replicaCount 3."
  explain "diff compares the assistant's file with a corrected one. Lines marked < are the assistant's. Lines marked > are the fix."
  show_diff values.yaml values-fixed.yaml
  look "the same three settings, moved out of the master and replica sections to where this chart reads them."
}

step_5() {
  chart_ready
  say "Ask the same question about the corrected file."
  explain "This is the step 3 command again, pointed at values-fixed.yaml."
  show cub config values "${CHART[@]}" --values values-fixed.yaml
  look "no IGNORED lines, and the last line, Every value you set changed the result or matches the default."
}

step_6() {
  chart_ready
  say "Now see what you were really getting."
  explain "helm template renders the chart again, this time with the corrected values, into work/redis-fixed.yaml."
  show_into "$WORK/redis-fixed.yaml" helm template shop-redis "${CHART[@]}" --namespace shop -f values-fixed.yaml
  explain "cub config diff compares the two sets of Kubernetes objects, field by field, and names each field that differs. Generated passwords and checksums do not count."
  show cub config diff "$WORK/redis.yaml" "$WORK/redis-fixed.yaml"
  look "two changed fields. A memory limit is added, so before there was none. Storage goes from 8Gi to 1Gi, so before you had an 8Gi disk."
}

step_7() {
  chart_ready
  say "One line in CI, and this cannot happen again."
  explain "This is the step 3 command with --exit-code added. It exits 1 when any value did nothing, which fails a build."
  show_refusal cub config values "${CHART[@]}" --values values.yaml --exit-code
  look "the line saying it was refused. In CI that is a red build, before anything is installed."
}

reset_demo() { rm -rf "$WORK"; }

demo_main "$@"
