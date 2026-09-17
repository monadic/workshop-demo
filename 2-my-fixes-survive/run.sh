#!/usr/bin/env bash
# Step 2. One app. The assistant rewrote the file. Are your fixes still there?
# No ConfigHub server, no account, no cluster.
source "$(dirname "$0")/../lib/demo.sh"

STEPS=(
  "Look at the three fixes you made by hand"
  "Look at the file the assistant wrote today"
  "Compare it with what you are running"
  "Put your fixes back, and compare again"
  "Keep a record of the review, and make it a gate"
)

step_1() {
  say "This is the shop app you are running. Over two weeks you set the replicas, the database host and the memory limit."
  show grep -n -E "replicas:|db.shop.internal|memory: 512Mi" app-committed.yaml
}

step_2() {
  say "You asked for a readiness probe. The assistant wrote the whole file again, and it checks out."
  show cub config check app-regenerated.yaml
}

step_3() {
  say "One change is the one you asked for. Count the others."
  show cub config diff app-committed.yaml app-regenerated.yaml
}

step_4() {
  say "With the three fixes restored, the only change left is the probe."
  show cub config diff app-committed.yaml app-restored.yaml
}

step_5() {
  say "With --exit-code any change stops for a review, and --out keeps both file hashes and every field that changed."
  show_refusal cub config diff app-committed.yaml app-regenerated.yaml --exit-code --out "$WORK/review.json"
  show grep -E '"sha256"|"changed"|"path"' "$WORK/review.json"
}

reset_demo() { rm -rf "$WORK"; }

demo_main "$@"
