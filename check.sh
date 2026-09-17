#!/usr/bin/env bash
# Preflight for the demos. It reads and reports, and changes nothing.
#   ./check.sh          check what demos 1 and 3 need
#   ./check.sh --hub    also check the ConfigHub login demo 2 needs
set -u
ok=0; bad=0
pass() { ok=$((ok+1));  printf '  \033[32mok\033[0m    %s\n' "$*"; }
fail() { bad=$((bad+1)); printf '  \033[31mFIX\033[0m   %s\n' "$1"; [ -n "${2:-}" ] && printf '        %s\n' "$2"; }

echo "Demos 1 and 3"
if command -v cub >/dev/null 2>&1; then
  version=$(cub version 2>/dev/null | awk '/^ +Version:/{print $2; exit}')
  pass "cub is installed (${version:-unknown version})"
  case "$version" in
    v0.[0-4].*) fail "cub is older than v0.5" "run: cub upgrade" ;;
  esac
else
  fail "cub is not installed" "run: curl -fsSL https://hub.confighub.com/cub/install.sh | bash"
fi

if cub config list >/dev/null 2>&1; then pass "the workshop plugin answers (cub config)"
else fail "the workshop plugin is missing" "run: cub plugin install confighub/cub-workshop"; fi

# An older build of the plugin has cub config check but not cub config diff.
if cub config --help 2>&1 | grep -q "config diff"; then pass "cub config diff is available"
else fail "this workshop plugin is too old for demo 1" "run: cub plugin upgrade workshop"; fi

if cub stack list >/dev/null 2>&1; then pass "cub stack answers"
else fail "cub stack does not answer" "run: cub plugin upgrade workshop"; fi

for tool in node oras; do
  if command -v "$tool" >/dev/null 2>&1; then pass "$tool is installed (the workshop plugin needs it)"
  else fail "$tool is not installed" "install $tool; the workshop plugin needs it on your PATH"; fi
done

if command -v python3 >/dev/null 2>&1; then pass "python3 is installed (demo 1 uses it to make one edit)"
else fail "python3 is not installed" "install Python 3"; fi

if [ "${1:-}" = "--hub" ]; then
  echo
  echo "Demo 2"
  if org=$(cub context get 2>/dev/null | awk -F'  +' '/Organization Name/{print $2}'); [ -n "$org" ] && cub space list >/dev/null 2>&1; then
    server=$(cub context get 2>/dev/null | awk -F'  +' '/Server URL|Server/{print $2; exit}')
    pass "logged in to organization \"$org\"${server:+ at $server}"
    left=$(cub space list -o name 2>/dev/null | grep -c '^wsdemo-')
    if [ "$left" = "0" ]; then pass "no wsdemo- Spaces are left over from an earlier run"
    else fail "$left wsdemo- Space(s) are left over from an earlier run" "run: (cd 2-with-confighub && ./run.sh --reset)"; fi
  else
    fail "not logged in to ConfigHub" "run: cub auth login"
  fi
fi

echo
if [ "$bad" = "0" ]; then echo "Ready. $ok checks passed."; else echo "$bad thing(s) to fix, $ok fine."; exit 1; fi
