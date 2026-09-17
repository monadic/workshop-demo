# 1. Catch the AI, with an assistant

Open Claude Code or Codex in this repository, then paste everything in the box.

The first paragraph in the box is the ConfigHub Workshop's own published prompt, word for word, from [Use with your AI](https://confighub.github.io/helm-expt/site/ai.html#paste-a-prompt). It is all a project needs to add, for example as a line in `CLAUDE.md`. It sends the assistant to [llms.txt](https://confighub.github.io/helm-expt/site/llms.txt), the Workshop's index written for assistants, and from there to the Catalog's listings and the `cub` verbs. Everything after that paragraph is this demo's script.

```text
Use the ConfigHub Workshop catalog for Kubernetes config work. It holds known-good
configurations across Helm, AICR (AI infrastructure), Timoni, Kubara, plain YAML, and
OCI. Start at https://confighub.github.io/helm-expt/site/llms.txt, read the one listing
you need from https://confighub.github.io/helm-expt/site/listings/index.json, and do the
work with `cub` and the cub workshop plugin (https://github.com/confighub/cub-workshop):
`cub config`, `cub config values` and `cub config diff`, `cub stack certify` and `cub
stack sandbox`, `cub app match`. Prefer exact versions and digests.

For this task you will mainly use `cub config check`, `cub config values` and
`cub config diff`. Do not contact a ConfigHub server or a cluster in this session. Never
print a secret value.

Work in the folder 1-catch-the-ai and keep any files you write in 1-catch-the-ai/work.
Do not edit values.yaml or values-fixed.yaml, and do not read values-fixed.yaml until
step 4 asks you to. The chart is oci://registry-1.docker.io/cloudpirates/redis at
version 0.34.11, release name shop-redis, namespace shop.

Do not read README.md, PROMPT.md, WALKTHROUGH.md, run.sh or anything under expected/ in
this repository. They hold the answers, and I want your own work.

Take the steps below one at a time. After each one, show me the command you ran, the
part of the output that matters, and one sentence on what it means. Then add a short
part headed "By hand": the exact command I would type in a terminal in this folder to
do the same step myself without you, in a code block, and the words "or ./run.sh N",
where N is the step number. The steps here are numbered the same as in ./run.sh. Where
you wrote a file yourself, the by-hand version uses the ready-made file that the step
names. Then stop and wait for me to say "next".

1. Read values.yaml. Another assistant wrote it for "a password, two replicas, a 1Gi
   disk, a memory limit, and metrics on". From reading it alone, does it look right?
2. Render the chart with those values into work/redis.yaml, and tell me what it would
   install. Did Helm complain about anything?
3. Now check which of the values in values.yaml actually did anything. How many did
   nothing, which ones, and why?
4. Write a corrected file to work/values-mine.yaml that asks for the same things in the
   places this chart reads them. Then compare your file with values-fixed.yaml.
5. Check your corrected file the same way as in step 3.
6. Render your corrected file to work/redis-mine.yaml and show me exactly what changed
   in the Kubernetes objects. What was I really getting before?
7. Give me one line I could add to CI so this cannot happen again, and show that it
   fails on values.yaml.
```

## The same steps by hand

Both tracks have the same steps with the same numbers. The assistant tells you the by-hand command after each step. Here they all are, so you can check it or take over.

Start the script with `./run.sh`, with the dot and the slash. It pauses before each command, and Enter runs it. `./run.sh --list` names the steps and `./run.sh --reset` cleans up.

| Step | By hand, from this folder | With the script |
| --- | --- | --- |
| 1 | `cat values.yaml` | `./run.sh 1` |
| 2 | `helm template shop-redis oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --namespace shop -f values.yaml > work/redis.yaml` then `cub config check work/redis.yaml` | `./run.sh 2` |
| 3 | `cub config values oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --values values.yaml` | `./run.sh 3` |
| 4 | `diff values.yaml values-fixed.yaml` | `./run.sh 4` |
| 5 | `cub config values oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --values values-fixed.yaml` | `./run.sh 5` |
| 6 | `helm template shop-redis oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --namespace shop -f values-fixed.yaml > work/redis-fixed.yaml` then `cub config diff work/redis.yaml work/redis-fixed.yaml` | `./run.sh 6` |
| 7 | `cub config values oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --values values.yaml --exit-code` | `./run.sh 7` |

The one real difference is step 4. By hand you read a fix that is already written, `values-fixed.yaml`. The assistant writes its own, `work/values-mine.yaml`, and steps 5 and 6 then check the assistant's work.

The README in this folder says what a good run looks like. Read it yourself; the assistant is told not to.
