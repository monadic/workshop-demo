# ConfigHub Workshop demos

You are building a small shop app with an AI assistant. These three demos follow that app from one chart, to the app itself, to the platform it runs on. Each takes about five minutes and ends on one result you would not have seen otherwise.

| Step | The question | What you see |
| --- | --- | --- |
| [1. Catch the AI](1-catch-the-ai/) | The assistant wrote my Helm values. Did they do anything? | Three of seven values did nothing, and Helm never said so |
| [2. My fixes survive the AI](2-my-fixes-survive/) | The assistant rewrote my app. Are my fixes still there? | One change you asked for, and three of your fixes undone |
| [3. What my app needs](3-what-my-app-needs/) | Will my app run on the platform I picked? | Refused for two real reasons, fixed on both sides, then certified |

Nothing here needs an account, a server or a cluster. Everything runs on your machine and writes only to a `work/` folder inside each demo.

You can run every demo two ways, and the steps are the same either way.

- **From the command line.** Run `./run.sh` in the demo's folder. It shows each command, waits for Enter, runs it, and moves on.
- **With an AI assistant.** Open Claude Code or Codex in this repository and paste the demo's `PROMPT.md`. The assistant walks the same steps and runs the same commands, and you compare what it says with `expected/`.

## Set up once

```sh
# 1. cub, the ConfigHub command line
curl -fsSL https://hub.confighub.com/cub/install.sh | bash

# 2. the workshop plugin: cub config, cub app, cub stack, cub fleet
#    it needs node, oras and helm on your PATH
cub plugin install confighub/cub-workshop
#    already installed? cub plugin upgrade workshop

# 3. check this machine is ready
./check.sh
```

## Run a demo

```sh
cd 1-catch-the-ai
./run.sh            # every step, pausing before each command
./run.sh 3          # only step 3
./run.sh --list     # the steps
./run.sh --reset    # remove what the demo created
```

Set `DEMO_AUTO=1` to run without pauses, which is useful for a rehearsal.

Every demo folder holds the same things. `README.md` tells the story with each command and what to look for. `run.sh` is the command-line track. `PROMPT.md` is the assistant track. `expected/` holds the output of each step from a real run. The input files sit beside them, and you are meant to read and edit them.

[WALKTHROUGH.md](WALKTHROUGH.md) has presenter notes: what to say at each step, how long it takes, and what to do if something goes wrong.

## Keep it working for you

Each demo leaves you with something that keeps paying off in your own repository.

- **Ground your assistant.** Add the prompt from [the Workshop's agent page](https://confighub.github.io/helm-expt/site/ai.html#paste-a-prompt) to your `CLAUDE.md` or `AGENTS.md`. Every later session then checks its work with `cub` and stops guessing.
- **Add one line to CI.** `cub config values <chart> --values values.yaml --exit-code` fails a build when a value did nothing. `cub config diff old.yaml new.yaml --exit-code` stops any change for a review. `cub stack certify platform.yaml` refuses a platform that does not hold together.
- **Commit what you reviewed.** The rendered objects, the review record and the platform workspace are plain files.

## When you want this remembered

Everything above works from files. At some point you will want more than files: the fixes you made kept as recorded edits and carried through the next rewrite or chart upgrade, a history you can roll back, an approval before anything ships, and a release your Argo CD or Flux pulls by digest. That is what a ConfigHub server does. You can run one yourself with `cub server install`, or use [hub.confighub.com](https://hub.confighub.com). The Workshop is useful before that day and after it.
