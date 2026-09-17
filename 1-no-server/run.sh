#!/usr/bin/env bash
# Demo 1. What will this install, and is my change the one I meant?
# No ConfigHub server, no account, no cluster.
source "$(dirname "$0")/../lib/demo.sh"

STEPS=(
  "See exactly what Redis installs, before anything runs"
  "Keep the reviewed objects as a file"
  "Make a change, then check it is the change you meant"
  "Certify a whole platform the same way"
  "Watch a bad composition get refused"
)

step_1() {
  say "One command renders the chart from the public Catalog and names every object."
  show cub config check redis
}

step_2() {
  say "The same check writes the exact objects to a file you can read, diff and keep."
  show cub config check redis --out "$WORK/before.yaml"
  show grep -c "^kind:" "$WORK/before.yaml"
}

step_3() {
  say "You meant to scale the master to three replicas. The same edit also set a disruption budget to zero, which blocks every node drain."
  python3 - "$WORK/before.yaml" "$WORK/after.yaml" <<'EOF'
import re, sys
text = open(sys.argv[1]).read()
text = re.sub(r"(\n\s*replicas:\s*)1\b", r"\g<1>3", text, count=1)
text = re.sub(r"(\n\s*maxUnavailable:\s*)1\b", r"\g<1>0", text, count=1)
open(sys.argv[2], "w").write(text)
EOF
  show cub config diff "$WORK/before.yaml" "$WORK/after.yaml"
  say "In CI the same command is a gate. It exits non-zero when anything changed."
  show_refusal cub config diff "$WORK/before.yaml" "$WORK/after.yaml" --exit-code
}

step_4() {
  say "A stack is many parts in one manifest. This one is an AI inference platform."
  show cub stack sandbox eks-inference
}

step_5() {
  say "Two components claim the same nine objects. Certify refuses the whole stack."
  show_refusal cub stack certify metrics-double
}

reset_demo() { rm -rf "$WORK"; }

demo_main "$@"
