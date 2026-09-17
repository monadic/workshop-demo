# 2. My fixes survive the AI

**The point.** When you ask an assistant for one change, it often writes the whole file again. The change you asked for is there. The fixes you made by hand last week may not be. A diff against the version you are running names every field that moved.

**Time.** About four minutes. **Needs.** `cub` and the workshop plugin. No server, no account, no cluster.

```sh
./run.sh
```

## The files

[app-committed.yaml](app-committed.yaml) is the shop app you are running today. Over two weeks you fixed three things by hand: three replicas, the real database host, and a 512Mi memory limit.

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

## The assistant track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md). In that track the assistant does the restoring itself, and you check its work with the same diff.

### What a good run looks like

At step 1 the assistant says the file is valid and would deploy, which is the point. At step 2 it reports four changed fields and separates the probe from the three undone fixes: replicas 3 to 1, `DATABASE_HOST` back to `localhost`, and the memory limit from 512Mi to 128Mi. At step 3 it names the consequences: lost capacity, an app that cannot reach its database, and out-of-memory restarts. At step 5 the diff shows one change, the probe.

A run has gone wrong if the assistant eyeballs the two files in place of running the diff, restores the fixes by copying `app-committed.yaml` and losing the probe, or claims success without the step 5 comparison.

## Reset

```sh
./run.sh --reset
```
