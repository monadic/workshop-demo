# 1. Catch the AI

**The point.** Helm accepts a values file without checking it against the chart. When an assistant writes values from memory, some of them are for a different chart, and they do nothing. The install still succeeds. One command tells you which values those are.

**Time.** About five minutes. **Needs.** `cub`, the workshop plugin and `helm`. No server, no account, no cluster.

```sh
./run.sh
```

## The files

[values.yaml](values.yaml) is what an assistant wrote for the shop's Redis when asked for "a password, two replicas, a 1Gi disk, a memory limit, and metrics on". It looks right. [values-fixed.yaml](values-fixed.yaml) is the same request with each setting where this chart reads it.

The chart is `cloudpirates/redis` 0.34.11, which is in the Workshop Catalog.

## The steps

**1. Read what the assistant wrote.** `cat values.yaml`. Nothing looks wrong.

**2. Let Helm render it, and see what it would install.**

```sh
helm template shop-redis oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --namespace shop -f values.yaml > work/redis.yaml
cub config check work/redis.yaml
```

Helm exits 0 and the objects look healthy. This is the trap.

**3. Ask which of those values did anything.**

```sh
cub config values oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --values values.yaml
```

Look for `3 of 7 values did nothing.` The disk size, the memory limit and the replica count are all `IGNORED`, because this chart has no `master` or `replica` section. For two of them the report says where the chart does read that setting.

**4. Put each setting where this chart reads it.** `diff values.yaml values-fixed.yaml` shows the three settings moved. One of them also changes its number. The assistant wrote `replicaCount: 2` in another chart's meaning, two replicas beside a master. This chart counts every pod, so two replicas is `replicaCount: 3`. The right place is not enough when the same word means something else.

**5. Ask again.** The same command on `values-fixed.yaml` ends with `Every value you set changed the result or matches the default.` The replica count reads `DEFAULT`: three pods is what this chart does anyway.

**6. See what the fix changes in the objects.**

```sh
cub config diff work/redis.yaml work/redis-fixed.yaml
```

Look at what you were really getting. You asked for a 1Gi disk and had 8Gi. You asked for a memory limit and had none. Your two replicas were there, and only because the chart's default happens to be three pods. Nothing you wrote put them there.

**7. Make it a gate.** With `--exit-code` the check fails a build when a value did nothing.

## How it knows

The chart is rendered with your values, then once more for each value with that one value taken out. If the objects are the same either way, the value did nothing. Charts generate passwords and checksums, so the fields that move between two renders of the same input are found first and left out of every comparison. No value is ever printed.

## The assistant track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md). Compare its answers with the files in [expected/](expected/).

### What a good run looks like

At step 1 an honest assistant says the file looks plausible. At step 3 it runs `cub config values` and reports that 3 of 7 values did nothing: the disk size, the memory limit and the replica count, because this chart has no `master` or `replica` section. At step 4 it moves the three settings, and a careful one also notices that this chart counts every pod, so two replicas is `replicaCount: 3`. At step 6 it reports that you had an 8Gi disk and no memory limit. At step 7 it shows `--exit-code` returning 1.

In our own trial the assistant read the chart's template, worked out the replica count, and corrected an earlier version of `values-fixed.yaml` in this folder that had it wrong.

A run has gone wrong if the assistant declares the values wrong from memory without running the check, prints the password, or "fixes" the file without verifying it afterwards.

## Reset

```sh
./run.sh --reset
```
