#!/usr/bin/env bash
# Started as "zsh run.sh" or "sh run.sh"? Carry on under bash, which this needs.
[ -n "${BASH_VERSION:-}" ] && case ":${SHELLOPTS:-}:" in *:posix:*) false ;; esac || exec bash "$0" "$@"
# Preflight for the demos. It reads and reports, and changes nothing.
set -u
ok=0; bad=0
pass() { ok=$((ok+1));  printf '  \033[32mok\033[0m    %s\n' "$*"; }
fail() { bad=$((bad+1)); printf '  \033[31mFIX\033[0m   %s\n' "$1"; [ -n "${2:-}" ] && printf '        %s\n' "$2"; }

if command -v cub >/dev/null 2>&1; then
  version=$(cub version 2>/dev/null | awk '/^ +Version:/{print $2; exit}')
  pass "cub is installed (${version:-unknown version})"
else
  fail "cub is not installed" "run: curl -fsSL https://hub.confighub.com/cub/install.sh | bash"
fi

if cub config list >/dev/null 2>&1; then pass "the workshop plugin answers (cub config)"
else fail "the workshop plugin is missing" "run: cub plugin install confighub/cub-workshop"; fi

if cub config 2>&1 | grep -q "config values"; then pass "cub config values is available (step 1)"
else fail "this workshop plugin is older than 0.6.22, and step 1 needs cub config values" "run: cub plugin upgrade workshop"; fi

if cub config 2>&1 | grep -q "config diff"; then pass "cub config diff is available (steps 1 and 2)"
else fail "this workshop plugin has no cub config diff" "run: cub plugin upgrade workshop"; fi

probe="$(mktemp -d)"; printf 'apiVersion: v1\nkind: Pod\nmetadata: {name: probe, namespace: demo}\nspec: {containers: [{name: c, image: probe}]}\n' > "$probe/pod.yaml"
if cub config check "$probe/pod.yaml" 2>&1 | grep -q "images tagged latest"; then pass "cub config check names unpinned images (step 4)"
else fail "this workshop plugin is older than 0.6.26, and step 4 needs its image and preset notes" "run: cub plugin upgrade workshop"; fi
rm -rf "$probe"

if cub stack list >/dev/null 2>&1; then pass "cub stack answers (step 3)"
else fail "cub stack does not answer" "run: cub plugin upgrade workshop"; fi

for tool in node oras; do
  if command -v "$tool" >/dev/null 2>&1; then pass "$tool is installed (the workshop plugin needs it)"
  else fail "$tool is not installed" "install $tool; the workshop plugin needs it on your PATH"; fi
done

if command -v helm >/dev/null 2>&1; then pass "helm is installed (steps 1 and 4 render a chart)"
else fail "helm is not installed" "install Helm; steps 1 and 4 render a chart with it"; fi

if command -v curl >/dev/null 2>&1; then pass "curl is installed (step 4 reads the Workshop Catalog)"
else fail "curl is not installed" "install curl; step 4 reads the Workshop Catalog with it"; fi

echo
if [ "$bad" = "0" ]; then echo "Ready. $ok checks passed."; else echo "$bad thing(s) to fix, $ok fine."; exit 1; fi
