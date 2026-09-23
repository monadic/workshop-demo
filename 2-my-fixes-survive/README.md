# 2. My fixes survive the AI

**The point.** When you ask an assistant for one change, it often writes the whole file again. The change you asked for is there. The fixes you made by hand last week may not be. A diff against the version you are running names every field that moved.

**Time.** About four minutes, or six with ConfigHub. **Needs.** `cub` and the workshop plugin. Steps 1 to 5 need no server, no account and no cluster. Steps 6 and 7 start only when you name a new Space with `DEMO_SPACE`; a ConfigHub lookup error stops and shows the error.

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

Use these commands as the manual route, or use `DEMO_SPACE=my-workshop-space ./run.sh 6` and the same value with `./run.sh 7` as the script route. Do not mix them: the manual route does not write the local record that lets script step 7 continue, and script step 6 refuses a Space the manual route already created.

```sh
export DEMO_SPACE=my-workshop-space
cub space create "$DEMO_SPACE"
cub unit create --space "$DEMO_SPACE" shop-web-generated app-generated.yaml
cub unit create --space "$DEMO_SPACE" shop-web --upstream-unit shop-web-generated --upstream-space "$DEMO_SPACE"
cub unit update --space "$DEMO_SPACE" shop-web app-committed.yaml --protect --change-desc "my three hand fixes"
cub revision list --space "$DEMO_SPACE" shop-web
```

The assistant's output lives in one Unit and your copy is cloned from it. `--protect` records the paths changed by your three fixes as local overrides. A plain update records a revision but does not newly protect those paths from a competing upstream edit.

**7. Let the assistant rewrite it again.** Today's rewrite lands in the assistant's Unit, and one command brings it into yours.

```sh
export DEMO_SPACE=my-workshop-space
mkdir -p work
cub unit update --space "$DEMO_SPACE" shop-web-generated app-regenerated.yaml --change-desc "add a readiness probe"
cub unit update --space "$DEMO_SPACE" shop-web --upgrade
cub unit data --space "$DEMO_SPACE" shop-web > work/from-confighub.yaml
cub config diff app-committed.yaml work/from-confighub.yaml
```

Look for one changed field, the probe. Your three fixes are still there, and nobody put them back by hand. ConfigHub did step 4 for you. This step 7 comparison proves that it retained your configuration and added only the probe.

These two steps write to a new Space you choose in the organization your current `cub` context points at. Set a name you own with `DEMO_SPACE=my-workshop-space ./run.sh 6`, then use the same value for step 7. The script creates the Space once and stops if that name already exists; it never deletes or reuses an existing Space. It records the Space ID and server identity locally, and step 7 checks both before changing anything. `DEMO_CONTEXT=name` picks another context. `./run.sh --reset` removes local `work/` only and leaves the Space unchanged.

## The assistant track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md). In that track the assistant does the restoring itself, and you check its work with the same diff.

### What a good run looks like

At step 2 the assistant says the file is valid and would deploy, which is the point. At step 3 it reports four changed fields and separates the probe from the three undone fixes: replicas 3 to 1, `DATABASE_HOST` back to `localhost`, and the memory limit from 512Mi to 128Mi. It names the consequences: lost capacity, an app that cannot reach its database, and out-of-memory restarts. At step 4 its own diff shows one change, the probe. If you go on to ConfigHub, step 7 ends with the same one-change diff, and this time the file came out of ConfigHub with nobody restoring anything. After every step it shows the by-hand command.

A run has gone wrong if the assistant eyeballs the two files in place of running the diff, restores the fixes by copying `app-committed.yaml` and losing the probe, or claims success without the step 4 comparison.

## Reset

```sh
./run.sh --reset
```

This removes the local review files and the record that allows step 7 to continue. It does not delete anything from ConfigHub.

## Recorded independent preservation test

A separate invoice application was tested against a local ConfigHub server on
2026-09-23. Its generated rewrite reverted six reviewed fields while adding a
liveness probe. Linked Units and `cub unit update --upgrade` preserved all six
edits; the exported result differed from the reviewed input only by that probe.
The [receipt and hashed files](expected/invoice-preservation/receipt.json) retain
the exact input and output. The pre-rewrite upstream is a synthetic test baseline,
not recovered historical configuration. This test did not deploy the application
or exercise a same-field conflict.

A [same-field follow-up](expected/invoice-protection/receipt.json) changed upstream
replicas from 2 to 5 while the downstream choice was 4. Without `--protect`, the
upgrade returned success and wrote 5. With `--protect` when recording the local
edits, it kept 4 and added the new probe. The other five edits survived both runs.
Protection means retaining the local choice; this is not a promise of a conflict
dialog or a general-purpose semantic merge. Review intended upstream changes to
protected fields before deciding whether to change the local override.
