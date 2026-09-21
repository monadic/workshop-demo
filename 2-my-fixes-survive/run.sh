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

# Steps 6 and 7 write to a caller-named ConfigHub Space. They use your current
# cub context; DEMO_CONTEXT=name picks another. There is no default Space name:
# a named Space makes the server work an intentional, personal continuation.
SPACE="${DEMO_SPACE:-}"
SPACE_MARKER="$WORK/demo-space"
hub() {
  if [ -n "${DEMO_CONTEXT:-}" ]; then cub --context "$DEMO_CONTEXT" "$@"; else cub "$@"; fi
}
space_selected() {
  if [ -n "$SPACE" ]; then return 0; fi
  say "Steps 6 and 7 need a new Space name that you choose. The local steps are complete."
  dim "    To continue, run DEMO_SPACE=my-workshop-space ./run.sh 6, then use the same name for step 7."
  return 1
}
identity_valid() {
  local first second
  case "$1" in
    *'|'*) first=${1%%|*}; second=${1#*|} ;;
    *) return 1 ;;
  esac
  [ -n "$first" ] && [ -n "$second" ] && [ "$second" != "$1" ] && [[ "$second" != *'|'* ]]
}
context_identity() {
  local identity
  identity="$(hub context get -o 'jq=[.coordinate.serverURL, .coordinate.organizationID] | join("|")')" || return 1
  identity_valid "$identity" || { echo "ConfigHub returned an incomplete server identity." >&2; return 1; }
  printf '%s\n' "$identity"
}
space_identity() {
  local identity
  identity="$(hub space get "$SPACE" -o 'jq=[.Space.OrganizationID, .Space.SpaceID] | join("|")')" || return 1
  identity_valid "$identity" || { echo "ConfigHub returned an incomplete Space identity." >&2; return 1; }
  printf '%s\n' "$identity"
}
record_space_marker() {
  local context_id space_id
  context_id="$(context_identity)" || return 1
  space_id="$(space_identity)" || return 1
  printf '%s\n%s\n' "$context_id" "$space_id" > "$SPACE_MARKER"
}
space_created_here() {
  local marker_context marker_space current_context current_space
  [ -f "$SPACE_MARKER" ] || return 1
  marker_context="$(sed -n '1p' "$SPACE_MARKER")"
  marker_space="$(sed -n '2p' "$SPACE_MARKER")"
  identity_valid "$marker_context" && identity_valid "$marker_space" || return 1
  current_context="$(context_identity)" || return 2
  current_space="$(space_identity)" || return 2
  [ "$marker_context" = "$current_context" ] && [ "$marker_space" = "$current_space" ]
}
HUB_READY=""
hub_ready() {
  if [ -z "$HUB_READY" ]; then
    if hub space list >/dev/null; then HUB_READY=yes; else HUB_READY=no; fi
  fi
  [ "$HUB_READY" = "yes" ] && return 0
  if [ -z "${HUB_TOLD:-}" ]; then
    say "Steps 6 and 7 use ConfigHub, but cub could not list Spaces in this context. Steps 1 to 5 stand on their own without it."
    dim "    Check the error above, then run cub auth login if needed and retry. No demo Space was created or changed."
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
  space_selected || return 0
  hub_ready || return 1
  say "Step 4 was you, putting your fixes back by hand. It will happen again next week. ConfigHub can remember them."
  explain "cub space create makes the new Space you named in ConfigHub, a place to keep configuration. It fails if that name already exists, so this demo never replaces a Space."
  show hub space create "$SPACE"
  if ! record_space_marker; then
    echo
    bold "The new Space was created, but its server identity could not be recorded. No Units were created."
    dim "    Check the error above before using or deleting the Space."
    exit 1
  fi
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
  local continuation_status=0
  space_selected || return 0
  hub_ready || return 1
  space_created_here || continuation_status=$?
  if [ "$continuation_status" -ne 0 ]; then
    case "$continuation_status" in
      1) say "Step 7 only continues the Space that step 6 created from this folder with this DEMO_SPACE value."
         dim "    Run DEMO_SPACE=$SPACE ./run.sh 6 first, or choose a new Space name. No existing Space was changed." ;;
      2) say "Step 7 could not confirm the saved server and Space identities."
         dim "    Check the error above. No existing Space was changed."
    esac
    return 1
  fi
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
  if [ -n "$SPACE" ]; then
    dim "    Reset removed local work only. The ConfigHub Space $SPACE remains unchanged."
  fi
  return 0
}

demo_main "$@"
