#!/usr/bin/env bash
# Started as "zsh run.sh" or "sh run.sh"? Carry on under bash, which this needs.
[ -n "${BASH_VERSION:-}" ] && case ":${SHELLOPTS:-}:" in *:posix:*) false ;; esac || exec bash "$0" "$@"
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
  "Save it as a workspace you can edit and check again"
)

step_1() {
  say "The shop app has an Ingress, a Certificate and a ServiceMonitor. Each one needs something a platform provides."
  explain "cub app check reads the app's YAML and works out what it assumes is already on the cluster. It runs on this laptop, with no account."
  show cub app check shop-web.yaml
  look "three NEEDS lines: an ingress controller, cert-manager, and a Prometheus operator."
}

step_2() {
  say "Here is the platform you picked from the Workshop Catalog."
  explain "grep prints the parts named in platform-first-try.yaml. The three platform parts are Catalog bundles pinned by digest. The last part is your own app file."
  show grep -E "^  name:|- name:|authored:" platform-first-try.yaml
  look "cert-manager, traefik and metrics-server, then shop-web."
}

step_3() {
  say "Will your app run on it?"
  explain "cub stack check pulls each Catalog bundle by digest and reads every object in every part. It checks for conflicts between parts, for CRDs arriving before the resources that use them, and for whether the platform carries what the app needs. Nothing is applied."
  show_refusal cub stack check platform-first-try.yaml
  look "=> REFUSED, and the two reasons under FAIL. The Ingress asks for class nginx on a Traefik platform, and nothing provides a Prometheus operator. Both would have failed quietly on a real cluster."
}

step_4() {
  say "The app changes one line, to the ingress class this platform has. The platform gains one part, the Prometheus operator the app asked for."
  explain "The first diff compares the app before and after. The second compares the platform before and after. Lines marked < are before, and lines marked > are after."
  show_diff shop-web.yaml shop-web-adapted.yaml
  show_diff platform-first-try.yaml platform.yaml
  look "one changed line in the app, nginx to traefik. In the platform, one added part, kube-prometheus-stack from the Catalog, pinned by digest."
}

step_5() {
  say "Ask the same question again."
  explain "This is the step 3 command, pointed at the fixed platform."
  show cub stack check platform.yaml
  look "=> CHECKED, and the line app needs met, which names all three needs from step 1. The WARN lines say what the check cannot see from here and the cluster must already have."
}

step_6() {
  say "Every object, in the order it has to be applied. kubectl, Argo CD and Flux all take this file as it is."
  explain "cub stack sandbox renders the whole platform with the app on it into one file, work/platform.yaml. Still nothing is applied."
  show cub stack sandbox platform.yaml --out "$WORK/platform.yaml"
  explain "grep counts the objects in that file."
  show grep -c "^kind:" "$WORK/platform.yaml"
  look "215, the same count the check read."
}

step_7() {
  say "Keep it as something you can edit."
  rm -rf "$WORK/shop-platform"
  explain "The same command with --workspace saves an editable copy: each part as its own file, the manifest, the render and the verdict."
  show cub stack sandbox platform.yaml --workspace "$WORK/shop-platform"
  explain "ls shows what was saved."
  show ls "$WORK/shop-platform"
  look "components, stack.yaml, rendered.yaml and result.json. Edit a component, then run cub stack check on that stack.yaml to check it again."
}

reset_demo() { rm -rf "$WORK"; }

demo_main "$@"
