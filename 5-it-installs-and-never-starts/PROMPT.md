# 5. It installs and never starts, with an assistant

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

For this task you will mainly use `cub config check`, with `helm template` and `curl`.
Do not contact a ConfigHub server or a cluster in this session, and do not install
anything.

Work in the folder 5-it-installs-and-never-starts and keep any files you write in
5-it-installs-and-never-starts/work. Do not edit values.yaml.

The story: I asked you for MySQL for my shop and values.yaml is what came back, for the
chart oci://registry-1.docker.io/bitnamicharts/mysql at version 14.0.3. I am about to
install it.

Do not read README.md, PROMPT.md, WALKTHROUGH.md, run.sh or anything under expected/ in
this repository. They hold the answers, and I want your own work.

Take the steps below one at a time. After each one, show me the command you ran, the
part of the output that matters, and one sentence on what it means. Then add a short
part headed "By hand": the exact command I would type in a terminal in this folder to
do the same step myself without you, in a code block, and the words "or ./run.sh N",
where N is the step number. The steps here are numbered the same as in ./run.sh. Where
you wrote a file yourself, the by-hand version uses the ready-made file that the step
names. Then stop and wait for me to say "next".

1. Read values.yaml. What does it ask for, and does anything look wrong?
2. Render the chart with it into work/mysql.yaml and check what it would install,
   without asking any registry anything. Would you tell me to go ahead?
3. Now check what a render cannot know on its own: whether the images this chart runs
   can still be pulled. What do you find, and is the chart, the version or the values
   to blame?
4. The Workshop keeps a re-measured record of exactly this, at
   https://raw.githubusercontent.com/confighub/helm-expt/main/runs/bitnami-source-fetch/all-originals-receipt.json
   Read it. Which charts are affected, and what does it say about the images that are
   still there?
5. Find what the Workshop Catalog reviewed for MySQL instead, render it, and run the
   same check. Remember that helm leaves a chart's CRDs out of a template render unless
   you ask for them. What would the move cost me?
```

## The same steps by hand

Both tracks have the same steps with the same numbers. The assistant tells you the by-hand command after each step. Here they all are, so you can check it or take over.

Start the script with `./run.sh`, with the dot and the slash. It pauses before each command, and Enter runs it. `./run.sh --list` names the steps and `./run.sh --reset` cleans up.

| Step | By hand, from this folder | With the script |
| --- | --- | --- |
| 1 | `cat values.yaml` | `./run.sh 1` |
| 2 | `helm template shop-db oci://registry-1.docker.io/bitnamicharts/mysql --version 14.0.3 --namespace shop -f values.yaml > work/mysql.yaml` then `cub config check work/mysql.yaml` | `./run.sh 2` |
| 3 | `cub config check work/mysql.yaml --images` | `./run.sh 3` |
| 4 | the `curl` and `grep` commands under step 4 of the [README](README.md) | `./run.sh 4` |
| 5 | `helm template shop-db mysql-operator --repo https://mysql.github.io/mysql-operator/ --version 2.3.0 --namespace shop --include-crds > work/successor.yaml` then `cub config check work/successor.yaml --images` | `./run.sh 5` |
| 6 | `DEMO_CLUSTER=1 ./run.sh 6`, which is the only way to run it | `./run.sh 6` |

Step 6 is the command line only. It installs the broken chart on a throwaway cluster, and the assistant is told not to install anything.

The README in this folder says what a good run looks like. Read it yourself; the assistant is told not to.
