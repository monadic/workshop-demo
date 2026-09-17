#!/usr/bin/env bash
# Step 3. One small platform. What does the app need, and does the platform provide it?
# No ConfigHub server, no account, no cluster.
source "$(dirname "$0")/../lib/demo.sh"

STEPS=(
  "Ask what the app needs from a platform"
  "Look at the platform you picked first"
  "Certify the app on that platform, and get refused"
  "Fix both sides"
  "Certify again"
  "Render the platform with the app on it"
  "Save it as a workspace you can edit and re-certify"
)

step_1() {
  say "The shop app has an Ingress, a Certificate and a ServiceMonitor. Each one needs something a platform provides."
  show cub app check shop-web.yaml
}

step_2() {
  say "Three Catalog parts pinned by digest, and the app."
  show grep -E "^  name:|- name:|authored:" platform-first-try.yaml
}

step_3() {
  say "Certify reads every object in every part, and what the app asks for."
  show_refusal cub stack certify platform-first-try.yaml
}

step_4() {
  say "The app changes one line, to the ingress class this platform has. The platform gains one part, the Prometheus operator the app asked for."
  show_diff shop-web.yaml shop-web-adapted.yaml
  show_diff platform-first-try.yaml platform.yaml
}

step_5() {
  show cub stack certify platform.yaml
}

step_6() {
  say "Every object, in the order it has to be applied. kubectl, Argo CD and Flux all take this file as it is."
  show cub stack sandbox platform.yaml --out "$WORK/platform.yaml"
  show grep -c "^kind:" "$WORK/platform.yaml"
}

step_7() {
  rm -rf "$WORK/shop-platform"
  show cub stack sandbox platform.yaml --workspace "$WORK/shop-platform"
  show ls "$WORK/shop-platform"
}

reset_demo() { rm -rf "$WORK"; }

demo_main "$@"
