# 2. My fixes survive the AI, with an assistant

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

For this task you will mainly use `cub config check` and `cub config diff`. Do not
contact a cluster in this session, and do not contact a ConfigHub server before step 6.

Work in the folder 2-my-fixes-survive and keep any files you write in
2-my-fixes-survive/work. Do not edit the three app-*.yaml files, and do not read
app-restored.yaml until step 4 asks you to.

The story: app-committed.yaml is the shop app I am running today. Over the last two
weeks I fixed three things in it by hand. Today I asked an assistant to add a readiness
probe, and it gave me app-regenerated.yaml.

Do not read README.md, PROMPT.md, WALKTHROUGH.md, run.sh or anything under expected/ in
this repository. They hold the answers, and I want your own work.

Take the steps below one at a time. After each one, show me the command you ran, the
part of the output that matters, and one sentence on what it means. Then add a short
part headed "By hand": the exact command I would type in a terminal in this folder to
do the same step myself without you, in a code block, and the words "or ./run.sh N",
where N is the step number. The steps here are numbered the same as in ./run.sh. Where
you wrote a file yourself, the by-hand version uses the ready-made file that the step
names. Then stop and wait for me to say "next".

1. My three hand fixes in app-committed.yaml are the replica count, the database host
   and the memory limit. Show me those three lines.
2. Check app-regenerated.yaml on its own. Would it deploy? Does anything look wrong?
3. Compare it with app-committed.yaml. List every field that changed. Which one did I
   ask for, and which did I not? For each change I did not ask for, tell me what would
   happen in production if I applied the file as it is.
4. Write work/app-mine.yaml: the regenerated file with my three fixes restored and the
   readiness probe kept. Prove it is right by comparing it with app-committed.yaml and
   showing that the only change left is the one I asked for. Then compare your file
   with app-restored.yaml.
5. Save a review record of the comparison in step 3 to work/review.json, and tell me
   what it holds and how I would use the same command as a gate in CI.

Stop there unless I say "go on to ConfigHub". If I do, steps 6 and 7 may contact the
ConfigHub server my current cub context points at, and nothing else. Write only to one
Space named workshop-demo-shop, and tell me before you create it.

6. app-generated.yaml is what the assistant wrote two weeks ago, before I touched it.
   Create the Space. Store app-generated.yaml as a Unit named shop-web-generated. Create
   my own Unit, shop-web, cloned from it with --upstream-unit and --upstream-space. Then
   update shop-web with app-committed.yaml using --protect, described as "my three hand fixes", and
   show me its revisions.
7. Today's rewrite arrives: update shop-web-generated with app-regenerated.yaml. Then
   bring that into my copy with cub unit update --upgrade. Save my copy's data to
   work/from-confighub.yaml and compare it with app-committed.yaml. What changed, and
   what happened to my three fixes?
```

## The same steps by hand

Both tracks have the same steps with the same numbers. The assistant tells you the by-hand command after each step. Here they all are, so you can check it or take over.

Start the script with `./run.sh`, with the dot and the slash. It pauses before each command, and Enter runs it. `./run.sh --list` names the steps and `./run.sh --reset` cleans up.

| Step | By hand, from this folder | With the script |
| --- | --- | --- |
| 1 | `grep -n -E "replicas:\|db.shop.internal\|memory: 512Mi" app-committed.yaml` | `./run.sh 1` |
| 2 | `cub config check app-regenerated.yaml` | `./run.sh 2` |
| 3 | `cub config diff app-committed.yaml app-regenerated.yaml` | `./run.sh 3` |
| 4 | `cub config diff app-committed.yaml app-restored.yaml` | `./run.sh 4` |
| 5 | `cub config diff app-committed.yaml app-regenerated.yaml --exit-code --out work/review.json` | `./run.sh 5` |
| 6 | the five `cub space`, `cub unit` and `cub revision` commands under step 6 of the [README](README.md) | `./run.sh 6` |
| 7 | the four commands under step 7 of the [README](README.md) | `./run.sh 7` |

The one real difference is step 4. By hand you compare a restored file that is already written, `app-restored.yaml`. The assistant does the restoring itself, in `work/app-mine.yaml`, and the same diff checks its work.

The README in this folder says what a good run looks like. Read it yourself; the assistant is told not to.

## Independent mission: bring your own inputs

Add your real problem and file paths, then paste this prompt:

```text
Help me make the change I describe without losing my existing fixes. I will provide
the original, current, and candidate configuration files. Identify which requested
intent and existing user edits must survive; do not invent missing input. Compare
requested versus incidental changes, preserve my edits, and name semantic choices I
must decide. You may read public Catalog or registry information when needed, but
keep source inputs and external systems read-only. You may write a candidate and
evidence record only in a fresh local work directory. Separate static configuration
and registry observations from runtime proofs; a file comparison does not prove
deployment or health. Do not contact a cluster or ConfigHub server, create
resources, or publish anything. Show me the evidence, unresolved decisions, and the
exact candidate artifact or review record produced from my supplied files.
```

For the Server continuation, a plain update does not newly protect changed paths.
Use `--protect` when recording the reviewed local edits. A later upstream change
to a protected field keeps the local choice; review that choice deliberately
rather than treating protection as a conflict-resolution decision made for you.
