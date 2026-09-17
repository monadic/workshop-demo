# Demo 2. With a ConfigHub account

**The point.** Demo 1 told you what you have. An account lets you keep it, place it on a target, make a rule that nothing ships unapproved, and release it as a digest that never changes.

**Time.** About seven minutes. **Needs.** `cub`, the workshop plugin, and a ConfigHub account. Sign up at [hub.confighub.com](https://hub.confighub.com), then run `cub auth login`.

```sh
../check.sh --hub     # confirms the login and that no earlier run is left over
./run.sh
```

Everything this demo creates lives in three Spaces named `wsdemo-redis-base`, `wsdemo-staging` and `wsdemo-redis-staging`. Set `DEMO_PREFIX` to use another prefix, and `CUB_CONTEXT` to run in a named cub context.

## The steps

**1. Confirm where you are logged in.** `cub context get` shows the organization. Everything below happens there.

**2. Start from the file you reviewed for free.**

```sh
cub config check redis --out work/redis.yaml
```

**3. Upload it as a base.**

```sh
cub variant upload --component wsdemo-redis --variant base work/redis.yaml
cub unit list --space wsdemo-redis-base
```

ConfigHub splits the file into one Unit per object and keeps every revision. The upload also prints the one command that would undo it.

**4. Add a delivery target.** A Space, a worker and an OCI target stand in for a cluster. Your Argo CD or Flux pulls from a target like this one.

**5. Require an approval before anything from this base can ship.**

```sh
cub trigger create require-approval Mutation Kubernetes/YAML vet-approvedby 1 --space wsdemo-redis-base
```

One rule, set once on the base. Every copy placed from this base inherits it.

**6. Place the base on the target.**

```sh
cub variant create staging wsdemo-redis-base --target wsdemo-staging/target
```

Look for 13 Units created in `wsdemo-redis-staging`, and all 13 listed as gated.

**7. Try to release it, and get refused.**

```sh
cub release publish wsdemo-redis-staging
```

Look for the refusal that names the gate: `Validation Errors: wsdemo-redis-base/require-approval/vet-approvedby`. This is the moment of the demo. The rule held, and it said why.

**8. Approve, then release by digest.**

```sh
cub unit approve --space wsdemo-redis-staging --where "LEN(ApplyGates) > 0"
cub release publish wsdemo-redis-staging
cub release list --space wsdemo-redis-staging
```

Look for the `sha256:` manifest digest. That exact image is what a reconciler pulls.

**9. If there is time, change the base and promote the change.** The script scales the master in the base, previews the promotion with `--dry-run`, promotes it, approves again, and releases a second digest. The release list then shows both.

## The AI track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md).

## Reset

```sh
./run.sh --reset
```

This deletes the three `wsdemo-` Spaces and the `work/` folder, and nothing else.
