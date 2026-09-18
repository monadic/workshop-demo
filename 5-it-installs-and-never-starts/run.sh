#!/usr/bin/env bash
# Started as "zsh run.sh" or "sh run.sh"? Carry on under bash, which this needs.
[ -n "${BASH_VERSION:-}" ] && case ":${SHELLOPTS:-}:" in *:posix:*) false ;; esac || exec bash "$0" "$@"
# Step 5. The chart installs. The pods never start. One command says so first.
# Steps 1 to 5 need no cluster. Step 6 builds a throwaway one, and only if you ask.
source "$(dirname "$0")/../lib/demo.sh"

OLD=(oci://registry-1.docker.io/bitnamicharts/mysql --version 14.0.3)
SUCCESSOR=(mysql-operator --repo https://mysql.github.io/mysql-operator/ --version 2.3.0)
RECEIPT="https://raw.githubusercontent.com/confighub/helm-expt/main/runs/bitnami-source-fetch/all-originals-receipt.json"
CLUSTER="workshop-demo-trial"

STEPS=(
  "Read what the assistant wrote"
  "Render it and run the usual checks"
  "Ask whether the images can be pulled at all"
  "Read the Workshop's own record of that"
  "Check what the Catalog offers instead"
  "Prove it on a real cluster"
)

step_1() {
  say "You asked for MySQL. The assistant picked the chart version it knew."
  explain "cat prints the values file and the install command it gave you."
  show cat values.yaml
  look "an ordinary values file for a well-known chart. Nothing here is wrong."
}

step_2() {
  say "Check it before installing, the way you would check any chart."
  explain "helm template renders the chart into work/mysql.yaml. The chart itself still downloads: it was never withdrawn."
  show_into "$WORK/mysql.yaml" helm template shop-db "${OLD[@]}" --namespace shop -f values.yaml
  explain "cub config check lists what it installs and the work it carries."
  show cub config check "$WORK/mysql.yaml"
  look "every line passing, including the image line. The image is pinned to a version, which is what you want."
}

step_3() {
  say "One thing no local check can know: whether that image still exists."
  explain "cub config check --images asks each image's own registry, without an account, whether it can be pulled. It is the one part of check that uses the network."
  show cub config check "$WORK/mysql.yaml" --images
  look "NOT FOUND. The chart is fine, the values are fine, and the image this chart runs is gone."
}

step_4() {
  say "The Workshop keeps a record of that, re-measured and committed."
  explain "curl downloads the receipt behind the Workshop's page on Bitnami charts."
  show curl -s -o "$WORK/receipt.json" "$RECEIPT"
  explain "grep shows, for each pinned chart, the image it runs and whether that image resolves."
  show grep -E "\"(chart|reference|status|legacyStatus)\":" "$WORK/receipt.json"
  look "mysql and rabbitmq report not-found, with the same tag available under bitnamilegacy, which receives no updates. The other four run an image tagged latest."
}

step_5() {
  say "So ask the Catalog what it reviewed instead for MySQL."
  explain "The Catalog's successor for MySQL is the operator from Oracle's own MySQL team. Render it with --include-crds, because helm leaves a chart's CRDs out of a template render unless you ask for them."
  show_into "$WORK/successor.yaml" helm template shop-db "${SUCCESSOR[@]}" --namespace shop --include-crds
  explain "The same two checks."
  show cub config check "$WORK/successor.yaml" --images
  look "the images pull, and the CRDs line names five. A chart is worth nothing if its images are gone, and this is the check that says so before you install. The move is real work: this is an operator, so the shop then needs a custom resource of its own."
}

step_6() {
  if [ "${DEMO_CLUSTER:-0}" != "1" ]; then
    say "This step installs the broken chart on a throwaway cluster, to show that the check was right."
    dim "    It needs kind and kubectl, and takes about two minutes."
    dim "    To run it: DEMO_CLUSTER=1 ./run.sh 6, and ./run.sh --reset deletes the cluster."
    return 0
  fi
  for tool in kind kubectl; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      say "This step needs $tool, and it is not installed. Steps 1 to 5 stand on their own."
      return 0
    fi
  done
  say "Install the chart the assistant chose, on a cluster of its own."
  # A kubeconfig of its own, inside work/, so no other cluster of yours is touched.
  export KUBECONFIG="$WORK/kubeconfig"
  explain "kind builds a throwaway Kubernetes cluster. It touches no other cluster or kubeconfig you have."
  show kind create cluster --name "$CLUSTER" --kubeconfig "$KUBECONFIG"
  show kubectl create namespace shop
  explain "helm install runs the chart that passed every local check. It does not wait, because the pods are not going to start."
  show helm install shop-db "${OLD[@]}" -n shop -f values.yaml
  explain "sleep gives Kubernetes half a minute to try the image."
  show sleep 30
  show kubectl -n shop get pods
  explain "The events say why."
  show kubectl -n shop get events --field-selector reason=Failed
  look "ImagePullBackOff, on the same image cub config check --images called NOT FOUND. helm install said nothing."
}

reset_demo() {
  if command -v kind >/dev/null 2>&1 && kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
    echo "  deleting the throwaway cluster..."
    kind delete cluster --name "$CLUSTER" >/dev/null 2>&1
  fi
  rm -rf "$WORK"
}

demo_main "$@"
