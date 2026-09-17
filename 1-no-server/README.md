# Demo 1. No server, no account

**The point.** You can know what a chart installs, check that a change is the change you meant, and have a bad platform refused, all before anything runs and without signing up for anything.

**Time.** About five minutes. **Needs.** `cub` and the workshop plugin.

```sh
./run.sh
```

## The steps

**1. See exactly what Redis installs.**

```sh
cub config check redis
```

Look for the object count and the kinds: 14 objects, named by kind. Look for the namespace that must already exist, and the four lifecycle checks that pass. A chart with hooks, CRDs or setup Jobs would say so here.

**2. Keep the reviewed objects as a file.**

```sh
cub config check redis --out work/before.yaml
```

This is config as data. The file is the exact set of Kubernetes objects, and you can read it, diff it and store it.

**3. Make a change, then check it is the change you meant.**

The script edits a copy of the file twice. One edit is the one you intended, scaling the master to three replicas. The other is the kind that slips in unnoticed, a disruption budget set to zero, which would block every node drain.

```sh
cub config diff work/before.yaml work/after.yaml
```

Look for two changed objects, each named with the exact field and the old and new value. In CI the same command with `--exit-code` fails the build when anything changed.

**4. Certify a whole platform the same way.**

```sh
cub stack sandbox eks-inference
```

Look for `=> CERTIFIED` and the totals: 130 objects across eight components, no conflicts, CRDs ordered before the resources that need them.

**5. Watch a bad composition get refused.**

```sh
cub stack certify metrics-double
```

Look for `=> REJECTED` and the nine objects that two components both claim. The command exits non-zero, so it works as a gate.

## The AI track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md). Compare its answers with the files in [expected/](expected/).

## Reset

```sh
./run.sh --reset
```

This removes the `work/` folder. Nothing else was created.
