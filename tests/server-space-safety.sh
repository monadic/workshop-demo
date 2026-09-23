#!/usr/bin/env bash
# Exercise the server portion without contacting a ConfigHub server.
set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin"
cp -R "$repo_dir/2-my-fixes-survive" "$test_dir/demo"
cp -R "$repo_dir/lib" "$test_dir/lib"
demo_dir="$test_dir/demo"

cat > "$test_dir/bin/cub" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$CUB_LOG"
case "${1:-} ${2:-}" in
  "context get")
    printf '%s\n' "${CUB_CONTEXT_ID:-https://server-a.example|org-a}"
    ;;
  "space list")
    if [ "${CUB_LIST_FAIL:-0}" = 1 ]; then
      echo "stub lookup failure" >&2
      exit 42
    fi
    exit 0
    ;;
  "space create")
    name=${3:?}
    if grep -Fxq "$name" "$CUB_SPACES"; then
      echo "space already exists: $name" >&2
      exit 1
    fi
    printf '%s\n' "$name" >> "$CUB_SPACES"
    ;;
  "space get")
    name=${3:?}
    printf '%s\n' "${CUB_SPACE_IDENTITY:-org-a|space-$name}"
    ;;
esac
EOF
chmod +x "$test_dir/bin/cub"

run_demo() {
  PATH="$test_dir/bin:$PATH" CUB_LOG="$test_dir/cub.log" CUB_SPACES="$test_dir/spaces" \
    DEMO_AUTO=1 "$@"
}
assert_not_called() {
  if grep -Fq "$1" "$test_dir/cub.log"; then
    echo "unexpected cub call: $1" >&2
    exit 1
  fi
}

# A default server step does not touch a pre-existing Space.
printf 'existing-space\n' > "$test_dir/spaces"
: > "$test_dir/cub.log"
run_demo "$demo_dir/run.sh" 6 > /dev/null
grep -Fxq 'existing-space' "$test_dir/spaces"
test "$(wc -l < "$test_dir/spaces")" -eq 1
test ! -s "$test_dir/cub.log"

# A selected existing Space fails at creation and is left as it was.
: > "$test_dir/cub.log"
if DEMO_SPACE=existing-space run_demo "$demo_dir/run.sh" 6 > /dev/null 2>&1; then
  echo "step 6 accepted an existing Space" >&2
  exit 1
fi
grep -Fxq 'existing-space' "$test_dir/spaces"
test "$(wc -l < "$test_dir/spaces")" -eq 1
assert_not_called 'space delete'

# Reset never sends a delete, even when a caller names an existing Space.
: > "$test_dir/cub.log"
DEMO_SPACE=existing-space run_demo "$demo_dir/run.sh" --reset > /dev/null
grep -Fxq 'existing-space' "$test_dir/spaces"
test ! -s "$test_dir/cub.log"

# A lookup failure is shown and does not become an "absent" Space.
: > "$test_dir/cub.log"
if CUB_LIST_FAIL=1 DEMO_SPACE=unreachable-space run_demo "$demo_dir/run.sh" 6 > "$test_dir/failure.txt" 2>&1; then
  echo "step 6 accepted a failed Space lookup" >&2
  exit 1
fi
grep -Fq 'stub lookup failure' "$test_dir/failure.txt"
grep -Fq 'could not list Spaces' "$test_dir/failure.txt"
assert_not_called 'space create'

# A malformed server identity stops after creation, before any Unit is created.
: > "$test_dir/cub.log"
if CUB_CONTEXT_ID='|' DEMO_SPACE=bad-identity-space run_demo "$demo_dir/run.sh" 6 > /dev/null 2>&1; then
  echo "step 6 accepted an incomplete server identity" >&2
  exit 1
fi
grep -Fq 'space create bad-identity-space' "$test_dir/cub.log"
assert_not_called 'unit create'

# A fresh caller-selected Space can complete step 6 without a delete.
: > "$test_dir/cub.log"
DEMO_SPACE=owned-demo-space run_demo "$demo_dir/run.sh" 6 > /dev/null
grep -Fxq 'owned-demo-space' "$test_dir/spaces"
grep -Fq 'space create owned-demo-space' "$test_dir/cub.log"
grep -Fq 'unit create --space owned-demo-space shop-web-generated app-generated.yaml' "$test_dir/cub.log"
assert_not_called 'space delete'

grep -Fq 'unit update --space owned-demo-space shop-web app-committed.yaml --protect' "$test_dir/cub.log"

# The same bound server and fresh Space can continue through step 7.
: > "$test_dir/cub.log"
DEMO_SPACE=owned-demo-space run_demo "$demo_dir/run.sh" 7 > /dev/null
grep -Fq 'unit update --space owned-demo-space shop-web-generated app-regenerated.yaml' "$test_dir/cub.log"
grep -Fq 'unit update --space owned-demo-space shop-web --upgrade' "$test_dir/cub.log"

# The marker is rejected when the selected context resolves to another server.
: > "$test_dir/cub.log"
CUB_CONTEXT_ID='https://server-b.example|org-b' DEMO_SPACE=owned-demo-space \
  run_demo "$demo_dir/run.sh" 7 > /dev/null 2>&1 && {
    echo "step 7 accepted a different server identity" >&2
    exit 1
  }
grep -Fq 'context get' "$test_dir/cub.log"
assert_not_called 'unit update'

echo "server space safety: PASS"
