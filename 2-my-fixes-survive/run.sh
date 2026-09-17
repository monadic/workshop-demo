#!/usr/bin/env bash
# Started as "zsh run.sh" or "sh run.sh"? Carry on under bash, which this needs.
[ -n "${BASH_VERSION:-}" ] && case ":${SHELLOPTS:-}:" in *:posix:*) false ;; esac || exec bash "$0" "$@"
# Step 2. One app. The assistant rewrote the file. Are your fixes still there?
# Steps 1 to 5 need no ConfigHub server, no account and no cluster.
# Steps 6 and 7 use a ConfigHub login, and are skipped without one.
source "$(dirname "$0")/../lib/demo.sh"

STEPS=(
  "Look at the three fixes you made by hand"
  "Look at the file the assistant wrote today"
  "Compare it with what you are running"
  "Put your fixes back, and compare again"
  "Keep a record of the review, and make it a gate"
  "With ConfigHub: let it remember your fixes"
  "With ConfigHub: let the assistant rewrite it again"
)

# Steps 6 and 7 write to ConfigHub, in one Space that --reset deletes.
# They use your current cub context. DEMO_CONTEXT=name picks another.
SPACE="workshop-demo-shop"
hub() {
  if [ -n "${DEMO_CONTEXT:-}" ]; then cub --context "$DEMO_CONTEXT" "$@"; else cub "$@"; fi
}
HUB_READY=""
hub_ready() {
  if [ -z "$HUB_READY" ]; then
    if hub space list >/dev/null 2>&1; then HUB_READY=yes; else HUB_READY=no; fi
  fi
  [ "$HUB_READY" = "yes" ] && return 0
  if [ -z "${HUB_TOLD:-}" ]; then
    say "Steps 6 and 7 use ConfigHub, and this terminal is not logged in. Steps 1 to 5 stand on their own without it."
    dim "    To run them, log in with cub auth login, then ./run.sh 6 and ./run.sh 7."
    HUB_TOLD=yes
  else
    dim "    Skipped, for the same reason."
  fi
  return 1
}

step_1() {
  say "This is the shop app you are running. Over two weeks you set the replicas, the database host and the memory limit."
  explain "grep prints the three lines you fixed by hand in app-committed.yaml, the file you are running today."
  show grep -n -E "replicas:|db.shop.internal|memory: 512Mi" app-committed.yaml
  look "three replicas, the real database host, and a 512Mi memory limit. Remember them."
}

step_2() {
  say "You asked for a readiness probe. The assistant wrote the whole file again, and it checks out."
  explain "cub config check reads the file the assistant wrote today and lists what it would install. It looks at this one file alone."
  show cub config check app-regenerated.yaml
  look "2 objects and four PASS lines. Looked at alone, nothing is wrong with this file."
}

step_3() {
  say "One change is the one you asked for. Count the others."
  explain "cub config diff compares the file you are running with the file the assistant wrote, object by object and field by field. It finds each container and each environment variable by name, so every change has an exact path."
  show cub config diff app-committed.yaml app-regenerated.yaml
  look "four changed fields. The readinessProbe is the one you asked for. The other three are your fixes undone: replicas 3 to 1, the database host back to localhost, and the memory limit down to 128Mi."
}

step_4() {
  say "With the three fixes restored, the only change left is the probe."
  explain "This is the same comparison, against a file with your three fixes put back."
  show cub config diff app-committed.yaml app-restored.yaml
  look "one changed field, the readinessProbe. That is the change you asked for, and nothing else."
}

step_5() {
  say "Keep the review, and make it a gate."
  explain "This is the step 3 comparison with two flags. --exit-code makes it exit 1 when anything changed, so CI stops for a review. --out writes the review to work/review.json."
  show_refusal cub config diff app-committed.yaml app-regenerated.yaml --exit-code --out "$WORK/review.json"
  explain "grep pulls the main parts out of that record."
  show grep -E '"sha256"|"changed"|"path"' "$WORK/review.json"
  look "two sha256 lines, which pin the record to these exact files, and one path line for each field that changed."
}

step_6() {
  hub_ready || return 0
  say "Step 4 was you, putting your fixes back by hand. It will happen again next week. ConfigHub can remember them."
  hub space delete --recursive-force "$SPACE" >/dev/null 2>&1
  explain "cub space create makes a Space in ConfigHub, a place to keep configuration. This is the first command today that needs an account."
  show hub space create "$SPACE"
  explain "cub unit create stores a file as a Unit. This one is what the assistant wrote two weeks ago, before you touched it. The assistant owns this Unit."
  show hub unit create --space "$SPACE" shop-web-generated app-generated.yaml
  explain "This makes your own copy, cloned from the assistant's. ConfigHub keeps the link between the two."
  show hub unit create --space "$SPACE" shop-web --upstream-unit shop-web-generated --upstream-space "$SPACE"
  explain "cub unit update puts the file you are running into your copy. ConfigHub records your three fixes as edits made on your side of that link."
  show hub unit update --space "$SPACE" shop-web app-committed.yaml --change-desc "my three hand fixes"
  explain "cub revision list shows the history of your copy."
  show hub revision list --space "$SPACE" shop-web
  look "the top line, your three hand fixes, with your description on it. Under it is the copy cloned from what the assistant wrote. ConfigHub now knows which edits are yours."
}

step_7() {
  hub_ready || return 0
  say "Today the assistant rewrites the file, exactly as in step 2. This time it lands in the assistant's Unit, and yours is untouched."
  explain "cub unit update replaces the assistant's Unit with today's rewrite, the one that adds the probe and undoes your fixes."
  show hub unit update --space "$SPACE" shop-web-generated app-regenerated.yaml --change-desc "add a readiness probe"
  explain "--upgrade brings the assistant's changes into your copy. ConfigHub merges them with the edits it recorded for you, field by field."
  show hub unit update --space "$SPACE" shop-web --upgrade
  explain "cub unit data prints your copy as it now stands, into work/from-confighub.yaml."
  show_into "$WORK/from-confighub.yaml" hub unit data --space "$SPACE" shop-web
  explain "This is the step 4 comparison again. The file on the right came out of ConfigHub, and nobody edited it by hand."
  show cub config diff app-committed.yaml "$WORK/from-confighub.yaml"
  look "one changed field, the readinessProbe. Your three replicas, your database host and your memory limit are all still there. ConfigHub did step 4 for you."
}

reset_demo() {
  rm -rf "$WORK"
  if hub space list >/dev/null 2>&1; then hub space delete --recursive-force "$SPACE" >/dev/null 2>&1; fi
  return 0
}

demo_main "$@"
