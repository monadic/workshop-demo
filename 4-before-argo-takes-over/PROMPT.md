# 4. Before Argo CD takes over, with an assistant

Open Claude Code or Codex in this repository, then paste everything in the box.

The first paragraph in the box is the ConfigHub Workshop's own published prompt, word for word, from [Use with your AI](https://confighub.github.io/helm-expt/site/ai.html#paste-a-prompt). It is all a project needs to add, for example as a line in `CLAUDE.md`. It sends the assistant to [llms.txt](https://confighub.github.io/helm-expt/site/llms.txt), the Workshop's index written for assistants, and from there to the Catalog's listings and the `cub` verbs. Everything after that paragraph is this demo's script.

```text
Use the ConfigHub Workshop catalog for Kubernetes config work. It holds known-good
configurations across Helm, AICR (AI infrastructure), Timoni, Kubara, plain YAML, and
OCI. Start at https://confighub.github.io/helm-expt/site/llms.txt, read the one listing
you need from https://confighub.github.io/helm-expt/site/listings/index.json, and do the
work with `cub` and the cub workshop plugin (https://github.com/confighub/cub-workshop):
`cub config`, `cub config values` and `cub config diff`, `cub stack check` and `cub
stack sandbox`, `cub app match`. Prefer exact versions and digests.

For this task you will mainly use `cub config check`, `cub config values` and
`cub config diff`, with `helm template`, `oras` and `curl`. Do not contact a ConfigHub
server or a cluster in this session. Never print a secret value.

Work in the folder 4-before-argo-takes-over and keep any files you write in
4-before-argo-takes-over/work. Do not edit values.yaml or values-successor.yaml, and do
not read values-successor.yaml until step 7 says you may.

The story: values.yaml has run my shop's Redis for a month, installed with
helm install shop-redis oci://registry-1.docker.io/bitnamicharts/redis --version 25.5.3
-n shop -f values.yaml. Next week Argo CD takes over deploying it.

Do not read README.md, PROMPT.md, WALKTHROUGH.md, run.sh or anything under expected/ in
this repository. They hold the answers, and I want your own work.

Take the steps below one at a time. After each one, show me the command you ran, the
part of the output that matters, and one sentence on what it means. Then add a short
part headed "By hand": the exact command I would type in a terminal in this folder to
do the same step myself without you, in a code block, and the words "or ./run.sh N",
where N is the step number. The steps here are numbered the same as in ./run.sh. Where
you wrote a file yourself, the by-hand version uses the ready-made file that the step
names. Then stop and wait for me to say "next".

1. Read values.yaml. What does it ask for, and what does it leave to the chart?
2. Render the chart with it into work/bitnami.yaml. What would it install, and is
   anything in it not pinned?
3. Render it a second time, into work/bitnami-again.yaml, and compare the two renders.
   What differs? What will Argo CD do with that, and why did helm install not show it?
4. What does this chart decide that values.yaml never wrote?
5. Could I pin the Redis image this chart runs to a version? Check on Docker Hub
   rather than from memory, for example with the tag 7.4.1-debian-12-r2, which an older
   release of this chart pinned, under bitnami and under bitnamilegacy.
6. Find a reviewed alternative for Redis in the Workshop Catalog, by reading its
   listings as data. Tell me which entry and base you would use, and why.
7. values-successor.yaml is that base's values with a 512Mi memory limit; you may read
   it now. Render the alternative with it into work/successor.yaml, then run the same
   checks as in steps 2 and 4. What is left of the problems you found?
8. Render the alternative a second time and compare the two renders, as in step 3. Is
   it safe to hand to Argo CD?
```

## The same steps by hand

Both tracks have the same steps with the same numbers. The assistant tells you the by-hand command after each step. Here they all are, so you can check it or take over.

Start the script with `./run.sh`, with the dot and the slash. It pauses before each command, and Enter runs it. `./run.sh --list` names the steps and `./run.sh --reset` cleans up.

| Step | By hand, from this folder | With the script |
| --- | --- | --- |
| 1 | `cat values.yaml` | `./run.sh 1` |
| 2 | `helm template shop-redis oci://registry-1.docker.io/bitnamicharts/redis --version 25.5.3 --namespace shop -f values.yaml > work/bitnami.yaml` then `cub config check work/bitnami.yaml` | `./run.sh 2` |
| 3 | `helm template shop-redis oci://registry-1.docker.io/bitnamicharts/redis --version 25.5.3 --namespace shop -f values.yaml > work/bitnami-again.yaml` then `cub config diff work/bitnami.yaml work/bitnami-again.yaml` | `./run.sh 3` |
| 4 | `cub config values oci://registry-1.docker.io/bitnamicharts/redis --version 25.5.3 --release shop-redis --namespace shop --values values.yaml` | `./run.sh 4` |
| 5 | `oras manifest fetch docker.io/bitnami/redis:7.4.1-debian-12-r2` then `oras manifest fetch --descriptor docker.io/bitnamilegacy/redis:7.4.1-debian-12-r2` | `./run.sh 5` |
| 6 | the five `curl` and `grep` commands under step 6 of the [README](README.md) | `./run.sh 6` |
| 7 | `helm template shop-redis oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --namespace shop -f values-successor.yaml > work/successor.yaml`, `cub config check work/successor.yaml`, then `cub config values oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --release shop-redis --namespace shop --values values-successor.yaml` | `./run.sh 7` |
| 8 | `helm template shop-redis oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --namespace shop -f values-successor.yaml > work/successor-again.yaml` then `cub config diff work/successor.yaml work/successor-again.yaml` | `./run.sh 8` |

The one real difference is step 6. By hand you read the entry named in this folder. The assistant finds it in the Catalog listings on its own, and steps 7 and 8 check what it chose.

The README in this folder says what a good run looks like. Read it yourself; the assistant is told not to.

## Independent mission: bring your own inputs

Add your real migration problem and file paths, then paste this prompt:

```text
Help me prepare my configuration for Flux or Argo CD. I will provide the current
manifests, values, candidate files, and controller sources I have. Preserve the
existing deployment intent and my edits; do not invent absent input, chart behavior,
or ownership. Determine whether Flux or Argo currently has authority from the
supplied sources, name semantic choices for me, and refuse an unapproved handoff or
takeover. You may read public Catalog or registry information, but keep source
inputs and external systems read-only. You may write a candidate and evidence record
only in a fresh local work directory. Separate static render and registry
observations from runtime proofs about reconciliation, drift, or health. Do not
contact a cluster or server, change controller ownership, apply resources, or
publish anything. Show me evidence, unresolved decisions, and the proposed handoff
boundary.
```
