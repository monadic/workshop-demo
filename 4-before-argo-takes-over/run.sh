#!/usr/bin/env bash
# Started as "zsh run.sh" or "sh run.sh"? Carry on under bash, which this needs.
[ -n "${BASH_VERSION:-}" ] && case ":${SHELLOPTS:-}:" in *:posix:*) false ;; esac || exec bash "$0" "$@"
# Step 4. Redis has run from helm install for a month. Argo CD is about to take over.
# No ConfigHub server, no account, no cluster. It needs a network.
source "$(dirname "$0")/../lib/demo.sh"

BITNAMI=(oci://registry-1.docker.io/bitnamicharts/redis --version 25.5.3)
SUCCESSOR=(oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11)
LISTINGS="https://confighub.github.io/helm-expt/site/listings"

STEPS=(
  "Read what has been running for a month"
  "See what it installs"
  "Render it twice, the way Argo CD will"
  "Ask what the chart does that you did not write"
  "Try to pin the image to a version"
  "Ask the Workshop Catalog for a reviewed alternative"
  "Check the alternative, with your memory limit"
  "Render the alternative twice"
)

step_1() {
  say "An assistant wrote this a month ago, and helm install has run it ever since. Now the shop is moving to Argo CD."
  explain "cat prints the values file. Three lines, and nothing looks wrong."
  show cat values.yaml
  look "a password switched on and nothing else. The chart decides the rest."
}

step_2() {
  say "First, what does the chart really install?"
  explain "helm template renders the chart with these values, the way Argo CD does, into work/bitnami.yaml. Nothing reaches a cluster."
  show_into "$WORK/bitnami.yaml" helm template shop-redis "${BITNAMI[@]}" --namespace shop -f values.yaml
  explain "cub config check lists what that file installs, and anything that needs work before or after."
  show cub config check "$WORK/bitnami.yaml"
  look "the NOTE line. The Redis image is tagged latest, so the same name can pull a different Redis next week."
}

step_3() {
  say "Argo CD renders the chart on every sync, without reading anything back from your cluster. Do that twice."
  explain "The same command, the same values, a second time, into work/bitnami-again.yaml."
  show_into "$WORK/bitnami-again.yaml" helm template shop-redis "${BITNAMI[@]}" --namespace shop -f values.yaml
  explain "cub config diff compares the two renders field by field. A Secret's values are never printed, only a short hash of each."
  show cub config diff "$WORK/bitnami.yaml" "$WORK/bitnami-again.yaml"
  look "one changed field, the Redis password. Same chart, same values, a different password. Under Argo CD every sync writes a new one, and the shop app still holds the old one."
}

step_4() {
  say "helm install hid that, because it reads the Secret back from the cluster. What else is the chart deciding for you?"
  explain "cub config values renders the chart once per value you set, and now also names what the chart does that you never wrote. No value is printed."
  show cub config values "${BITNAMI[@]}" --release shop-redis --namespace shop --values values.yaml
  look "two NOTE lines. A resource preset called nano sets Redis's memory, 192Mi, and you never chose it. The password field changes on every render."
}

step_5() {
  say "You can fix the password with an existing Secret. The floating image is harder. Try to pin a Redis version."
  explain "oras asks Docker Hub, without an account, for a versioned Bitnami Redis image. This tag is the one an older release of this same chart, 20.6.0, pinned."
  show_refusal oras manifest fetch docker.io/bitnami/redis:7.4.1-debian-12-r2
  explain "The same tag, in the repository Bitnami moved its old images to."
  show oras manifest fetch --descriptor docker.io/bitnamilegacy/redis:7.4.1-debian-12-r2
  look "the first refused, the second found. Versioned Bitnami images now sit behind a paid tier, and the legacy copies get no updates. The free chart runs latest."
}

step_6() {
  say "So ask the Workshop Catalog. It is public, it is data, and it needs no account."
  explain "curl downloads the Catalog's listing index, one line per reviewed configuration."
  show curl -s -o "$WORK/index.json" "$LISTINGS/index.json"
  explain "grep finds the reviewed Redis alternatives in it."
  show grep -o "\"id\": \"cloudpirates-redis[^\"]*\"" "$WORK/index.json"
  explain "curl downloads the listing for the base that keeps the password in a Secret you create, and grep shows what it is."
  show curl -s -o "$WORK/listing.json" "$LISTINGS/cloudpirates-redis-0-34-11-reuse-existing-secret.json"
  show grep -m 3 -o -E "\"(name|version|base)\": \"[^\"]*\"" "$WORK/listing.json"
  explain "And the exact package the Catalog reviewed, pinned by digest."
  show grep -m 1 -o "\"sourcePackageRef\": \"[^\"]*\"" "$WORK/listing.json"
  look "cloudpirates/redis 0.34.11 with the base reuse-existing-secret, and the reviewed package pinned by digest. values-successor.yaml in this folder is that base's values, with your 512Mi memory limit on top."
}

step_7() {
  say "Check the alternative the same way."
  explain "helm template renders it with the Catalog's base and your memory limit, into work/successor.yaml."
  show_into "$WORK/successor.yaml" helm template shop-redis "${SUCCESSOR[@]}" --namespace shop -f values-successor.yaml
  explain "The step 2 check."
  show cub config check "$WORK/successor.yaml"
  explain "The step 4 check."
  show cub config values "${SUCCESSOR[@]}" --release shop-redis --namespace shop --values values-successor.yaml
  look "images tagged latest: 0, because the image is pinned by digest. Every value applied. No preset, and nothing that changes on every render."
}

step_8() {
  say "And the step 3 test, the one Argo CD runs on every sync."
  explain "Render the alternative a second time."
  show_into "$WORK/successor-again.yaml" helm template shop-redis "${SUCCESSOR[@]}" --namespace shop -f values-successor.yaml
  explain "Compare the two renders."
  show cub config diff "$WORK/successor.yaml" "$WORK/successor-again.yaml"
  look "0 changed. Argo CD would find nothing to change, and the password stays in the Secret you own."
}

reset_demo() { rm -rf "$WORK"; }

demo_main "$@"
