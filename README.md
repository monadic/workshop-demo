# ConfigHub Workshop demos

Three short demos of the [ConfigHub Workshop](https://confighub.github.io/helm-expt/site/). Each one takes five to seven minutes and ends on one clear result.

| Demo | What you see | Needs |
| --- | --- | --- |
| [1. No server](1-no-server/) | What a chart installs, whether your change is the change you meant, and a bad platform refused before anything runs | `cub` and the workshop plugin |
| [2. With ConfigHub](2-with-confighub/) | The reviewed config kept, placed on a target, held by an approval gate, then released by digest | The same, plus a ConfigHub account |
| [3. Build your own platform](3-diy-platform/) | Your own stack from Catalog parts, refused, fixed, certified and rendered | `cub` and the workshop plugin |

You can run every demo two ways, and the steps are the same either way.

- **From the command line, with no AI.** Run `./run.sh` in the demo's folder. It shows each command, waits for Enter, runs it, and moves on.
- **With an AI agent.** Open Claude Code or Codex in this repository and paste the demo's `PROMPT.md`. The agent walks the same steps and runs the same commands, and you compare what it says with `expected/`.

## Set up once

```sh
# 1. cub, the ConfigHub command line
curl -fsSL https://hub.confighub.com/cub/install.sh | bash

# 2. the workshop plugin: cub config, cub app, cub stack, cub fleet
#    it needs node and oras on your PATH
cub plugin install confighub/cub-workshop
#    already installed? cub plugin upgrade workshop

# 3. check this machine is ready
./check.sh
```

Demos 1 and 3 need nothing else. Demo 2 needs a ConfigHub account. Sign up at [hub.confighub.com](https://hub.confighub.com), then run `cub auth login`.

## Run a demo

```sh
cd 1-no-server
./run.sh            # every step, pausing before each command
./run.sh 3          # only step 3
./run.sh --list     # the steps
./run.sh --reset    # remove what the demo created
```

Set `DEMO_AUTO=1` to run without pauses, which is useful for a rehearsal.

Every demo folder holds the same five things. `README.md` tells the story with each command and what to look for. `run.sh` is the command-line track. `PROMPT.md` is the AI track. `expected/` holds the output of each step from a real run, so you can check yours. Any input files sit beside them.

[WALKTHROUGH.md](WALKTHROUGH.md) has presenter notes: what to say at each step, how long it takes, and what to do if something goes wrong.

## What these demos do not touch

Demos 1 and 3 read the public Catalog and write only to a `work/` folder inside the demo. They do not contact a ConfigHub server or a cluster.

Demo 2 creates three Spaces in the organization you are logged in to, all named with the prefix `wsdemo-`. `./run.sh --reset` deletes those three Spaces and nothing else. Step 1 shows which organization you are in before anything is created.
