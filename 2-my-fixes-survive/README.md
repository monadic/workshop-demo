# 2. My fixes survive the AI

**The point.** When you ask an assistant for one change, it often writes the whole file again. The change you asked for is there. The fixes you made by hand last week may not be. A diff against the version you are running names every field that moved.

**Time.** About four minutes, or six with ConfigHub. **Needs.** `cub` and the workshop plugin. Steps 1 to 5 need no server, no account and no cluster. Steps 6 and 7 use a ConfigHub login, and the script skips them when there is none.

```sh
./run.sh
```

Type it with the dot and the slash. It pauses before each command, and Enter runs it. `./run.sh 3` runs step 3 alone, `./run.sh --list` names the steps, and `./run.sh --reset` cleans up. The assistant track in [PROMPT.md](PROMPT.md) has the same steps with the same numbers, and the assistant shows the by-hand command after each one.

## The files

[app-committed.yaml](app-committed.yaml) is the shop app you are running today. Over two weeks you fixed three things by hand: three replicas, the real database host, and a 512Mi memory limit.

[app-generated.yaml](app-generated.yaml) is what the assistant wrote two weeks ago, before you touched it. Only steps 6 and 7 use it.

[app-regenerated.yaml](app-regenerated.yaml) is what came back when you asked the assistant to add a readiness probe. [app-restored.yaml](app-restored.yaml) is that file with your three fixes put back.

You did not create an environment for this. The other copy is the version that worked yesterday, and you already have it in git or on your cluster.

## The steps

**1. Look at the three fixes you made by hand.** `grep` shows the three lines in `app-committed.yaml`.

**2. Look at the file the assistant wrote today.**

```sh
cub config check app-regenerated.yaml
```

Two objects, nothing to worry about. It would deploy.

**3. Compare it with what you are running.**

```sh
cub config diff app-committed.yaml app-regenerated.yaml
```

Look for four changed fields in the Deployment. One is the readiness probe you asked for. The other three are your fixes undone: replicas 3 to 1, the database host back to `localhost`, the memory limit from 512Mi to 128Mi. Each is named by its exact path inside the container.

**4. Put your fixes back, and compare again.**

```sh
cub config diff app-committed.yaml app-restored.yaml
```

Look for one changed field, the probe. That is the change you asked for, and nothing else.

**5. Keep a record of the review, and make it a gate.** With `--exit-code` any change stops for a review, and `--out` writes both file hashes and every changed field to `work/review.json`.

**6. With ConfigHub, let it remember your fixes.** Step 4 was you, putting your fixes back by hand, and it will happen again next week. Log in with `cub auth login` first.

```sh
cub space create workshop-demo-shop
cub unit create --space workshop-demo-shop shop-web-generated app-generated.yaml
cub unit create --space workshop-demo-shop shop-web --upstream-unit shop-web-generated --upstream-space workshop-demo-shop
cub unit update --space workshop-demo-shop shop-web app-committed.yaml --change-desc "my three hand fixes"
cub revision list --space workshop-demo-shop shop-web
```

The assistant's output lives in one Unit and your copy is cloned from it. Your three fixes are now a recorded revision on your side of that link.

**7. Let the assistant rewrite it again.** Today's rewrite lands in the assistant's Unit, and one command brings it into yours.

```sh
cub unit update --space workshop-demo-shop shop-web-generated app-regenerated.yaml --change-desc "add a readiness probe"
cub unit update --space workshop-demo-shop shop-web --upgrade
cub unit data --space workshop-demo-shop shop-web > work/from-confighub.yaml
cub config diff app-committed.yaml work/from-confighub.yaml
```

Look for one changed field, the probe. Your three fixes are still there, and nobody put them back by hand. ConfigHub did step 4 for you. The local diff from step 3 is what proves it.

These two steps write to one Space, `workshop-demo-shop`, in the organization your current `cub` context points at. `DEMO_CONTEXT=name ./run.sh` picks another context. `./run.sh --reset` deletes the Space.

## The assistant track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md). In that track the assistant does the restoring itself, and you check its work with the same diff.

### What a good run looks like

At step 2 the assistant says the file is valid and would deploy, which is the point. At step 3 it reports four changed fields and separates the probe from the three undone fixes: replicas 3 to 1, `DATABASE_HOST` back to `localhost`, and the memory limit from 512Mi to 128Mi. It names the consequences: lost capacity, an app that cannot reach its database, and out-of-memory restarts. At step 4 its own diff shows one change, the probe. If you go on to ConfigHub, step 7 ends with the same one-change diff, and this time the file came out of ConfigHub with nobody restoring anything. After every step it shows the by-hand command.

A run has gone wrong if the assistant eyeballs the two files in place of running the diff, restores the fixes by copying `app-committed.yaml` and losing the probe, or claims success without the step 4 comparison.

## Reset

```sh
./run.sh --reset
```
