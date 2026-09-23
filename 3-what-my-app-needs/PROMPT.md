# 3. What my app needs, with an assistant

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

For this task you will mainly use `cub app check`, `cub stack check` and
`cub stack sandbox`. Do not contact a ConfigHub server or a cluster in this session.

Work in the folder 3-what-my-app-needs and keep any files you write in
3-what-my-app-needs/work. Do not edit the four YAML files in the folder. Do not read
shop-web-adapted.yaml or platform.yaml until step 4 says you may.

Do not read README.md, PROMPT.md, WALKTHROUGH.md, run.sh or anything under expected/ in
this repository. They hold the answers, and I want your own work.

Take the steps below one at a time. After each one, show me the command you ran, the
part of the output that matters, and one sentence on what it means. Then add a short
part headed "By hand": the exact command I would type in a terminal in this folder to
do the same step myself without you, in a code block, and the words "or ./run.sh N",
where N is the step number. The steps here are numbered the same as in ./run.sh. Where
you wrote a file yourself, the by-hand version uses the ready-made file that the step
names. Then stop and wait for me to say "next".

1. shop-web.yaml is my app. What does it need from a platform before it can run?
2. platform-first-try.yaml is the platform I picked. In plain words, what is in it and
   where does each part come from?
3. Certify my app on that platform. What is the verdict, and what exactly is wrong?
4. Propose the smallest fix. You may change the app, the platform, or both. Write your
   versions to work/shop-web-mine.yaml and work/platform-mine.yaml, with the platform
   file pointing at your app file (an `authored:` path is read relative to the platform
   file). If your fix costs the app something it asked for, say so. If you add a
   platform part, you may now read platform.yaml and take that part's bundle and
   receipt lines from it; never invent a digest. Tell me what you changed and why.
5. Check your fix. If it is refused, read the reason, fix it, and check again.
6. Render the checked platform to work/platform-rendered.yaml. How many objects, from
   which parts, and in what order?
7. Save it as an editable workspace in work/shop-platform and tell me how I would
   check it again after an edit.
```

## The same steps by hand

Both tracks have the same steps with the same numbers. The assistant tells you the by-hand command after each step. Here they all are, so you can check it or take over.

Start the script with `./run.sh`, with the dot and the slash. It pauses before each command, and Enter runs it. `./run.sh --list` names the steps and `./run.sh --reset` cleans up.

| Step | By hand, from this folder | With the script |
| --- | --- | --- |
| 1 | `cub app check shop-web.yaml` | `./run.sh 1` |
| 2 | `cat platform-first-try.yaml` | `./run.sh 2` |
| 3 | `cub stack check platform-first-try.yaml` | `./run.sh 3` |
| 4 | `diff shop-web.yaml shop-web-adapted.yaml` then `diff platform-first-try.yaml platform.yaml` | `./run.sh 4` |
| 5 | `cub stack check platform.yaml` | `./run.sh 5` |
| 6 | `cub stack sandbox platform.yaml --out work/platform.yaml` | `./run.sh 6` |
| 7 | `cub stack sandbox platform.yaml --workspace work/shop-platform` | `./run.sh 7` |

The one real difference is step 4. By hand you read a fix that is already written, `shop-web-adapted.yaml` and `platform.yaml`. The assistant proposes its own, and the check decides at step 5 whether it holds.

The README in this folder says what a good run looks like. Read it yourself; the assistant is told not to.

## Own-app mission

Paste this as a separate request after the seven steps.

```text
Work only in 3-what-my-app-needs/work/own-app. I will give you rendered Kubernetes
YAML for my app. Copy it to a fresh app.yaml, run `cub app check`, and show every
reported platform need. For each, run `cub config list --role ROLE` and inspect the
real candidates and evidence. Never invent a listing ID or digest, delete a reported
requirement, or substitute an unrelated service just to obtain CHECKED.

Use `cub stack compose` only with exact IDs you selected. `born-flat` and
`safe-to-flatten` entries may compose from retained objects. A `flatten-with-routes`
entry may compose only when its listing supplies a published digest-pinned
literal-config bundle and a hash-verified CertifiedBundleReceipt with declared route
companions. Let the command verify that evidence; record its route companions as
`declared-unexecuted`, and never say a route ran. An `unsafe-to-flatten`, unpublished,
or mismatched route-bundle refusal is the correct stopping point: report it and
preserve the requirement. Do not claim a complete platform in that case.

If composition is allowed, copy app.yaml into its new components directory. For a
route-backed selection, use only a fresh workspace made by workshop 0.6.44, then append
one new uniquely named `authored` component at the end of stack.yaml; never reorder or
edit its existing components. Run `cub stack check`, then save a fresh workspace with
`cub stack sandbox --workspace`. Show each command and the material output. This is a
static check only: do not contact ConfigHub or a cluster, and do not claim readiness or
application health. Keep the original composition and its provenance.json alongside the
saved workspace. Stop after any compose or check failure. If `stack compose` is missing,
say that workshop 0.6.44 is required and ask me to install it before continuing.
```
