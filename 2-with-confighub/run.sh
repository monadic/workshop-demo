#!/usr/bin/env bash
# Demo 2. Now keep it, place it, gate it and release it.
# Needs a ConfigHub account: cub auth login, in the organization you want to use.
#
#   CUB_CONTEXT=<name>  run against a named cub context instead of the current one
#   DEMO_PREFIX=<word>  prefix for every Space this demo creates (default: wsdemo)
source "$(dirname "$0")/../lib/demo.sh"

P="${DEMO_PREFIX:-wsdemo}"
# hub and hub_refusal run a cub command against ConfigHub. With CUB_CONTEXT set
# they add --context, and the command shown on screen is the real one.
hub() {
  if [ -n "${CUB_CONTEXT:-}" ]; then show cub "$@" --context "$CUB_CONTEXT"; else show cub "$@"; fi
}
hub_refusal() {
  if [ -n "${CUB_CONTEXT:-}" ]; then show_refusal cub "$@" --context "$CUB_CONTEXT"; else show_refusal cub "$@"; fi
}
hub_quiet() {
  if [ -n "${CUB_CONTEXT:-}" ]; then cub "$@" --context "$CUB_CONTEXT"; else cub "$@"; fi
}

BASE="$P-redis-base"
CLUSTER="$P-staging"
PLACED="$P-redis-staging"

STEPS=(
  "Confirm where you are logged in"
  "Start from the file you reviewed for free"
  "Upload it into ConfigHub as a base"
  "Add a delivery target, standing in for a cluster"
  "Require an approval before anything from this base can ship"
  "Place the base on the target"
  "Try to release it, and get refused by the gate"
  "Approve, then release by digest"
  "If there is time: change the base and promote the change"
)

step_1() {
  say "Everything below happens in this organization, in Spaces that start with '$P-'."
  hub context get
}

step_2() {
  show cub config check redis --out "$WORK/redis.yaml"
}

step_3() {
  say "ConfigHub splits the file into one Unit per object and keeps every revision."
  hub variant upload --component "$P-redis" --variant base "$WORK/redis.yaml"
  hub unit list --space "$BASE"
}

step_4() {
  say "A Target is where a release is delivered. Your Argo CD or Flux pulls from it."
  hub space create "$CLUSTER" --label Layer=cluster
  hub worker create worker --space "$CLUSTER" --is-server-worker
  hub target create target "{}" worker --space "$CLUSTER" -p OCI -t Any
}

step_5() {
  say "One Trigger on the base. Every copy placed from this base inherits it."
  hub trigger create require-approval Mutation Kubernetes/YAML vet-approvedby 1 --space "$BASE"
}

step_6() {
  say "Placing creates a variant of the base, bound to the target. A release belongs to its target."
  hub variant create staging "$BASE" --target "$CLUSTER/target"
  hub unit list --space "$PLACED" --where "LEN(ApplyGates) > 0"
}

step_7() {
  say "Nobody has approved these Units, so the release is refused and the gate is named."
  hub_refusal release publish "$PLACED"
}

step_8() {
  hub unit approve --space "$PLACED" --where "LEN(ApplyGates) > 0"
  hub release publish "$PLACED"
  say "The digest below is what a reconciler pulls. It never changes for this release."
  hub release list --space "$PLACED"
}

step_9() {
  say "Scale the master in the base. The placed copy has not changed yet."
  hub function do --space "$BASE" --where "Slug = 'redis-master'" set-replicas 3 --change-desc "Scale the master to three"
  hub variant promote "$PLACED" --dry-run
  hub variant promote "$PLACED"
  say "The promoted Units are gated again. Approve, then release a second digest."
  hub unit approve --space "$PLACED" --where "LEN(ApplyGates) > 0"
  hub release publish "$PLACED"
  hub release list --space "$PLACED"
}

reset_demo() {
  # The placed Space refers to the target, so it goes first.
  for space in "$PLACED" "$BASE" "$CLUSTER"; do
    hub_quiet space delete --recursive-force "$space" >/dev/null 2>&1 && echo "deleted $space"
  done
  rm -rf "$WORK"
}

demo_main "$@"
