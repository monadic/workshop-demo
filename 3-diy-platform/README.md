# Demo 3. Build your own platform

**The point.** A platform is a list of parts. You write the list, certify it, and find out that it does not hold together before anything renders. You fix one thing and certify again.

**Time.** About six minutes. **Needs.** `cub` and the workshop plugin. No server, no account, no cluster.

```sh
./run.sh
```

## The files

[stack-v1.yaml](stack-v1.yaml) is a data platform two teams wrote together: a cache, a database and metrics. Every part is a Catalog bundle pinned by digest, with a receipt. Team B added metrics too, under another name. [stack-v2.yaml](stack-v2.yaml) is the same manifest with that duplicate taken out.

## The steps

**1. See the parts you can build with.** `cub stack list` shows the stacks that ship, from a full inference platform down to three services.

**2. Read the platform.** `cat stack-v1.yaml`. It is 19 lines. Four components, each a bundle by digest.

**3. Certify it, and get refused.**

```sh
cub stack certify stack-v1.yaml
```

Look for `=> REJECTED` and the nine objects that `metrics-server` and `team-b-metrics` both claim. Nothing was rendered and nothing was applied. The command exits non-zero.

**4. Fix the manifest.** `diff stack-v1.yaml stack-v2.yaml` shows the only three lines that change.

**5. Certify it again.**

```sh
cub stack certify stack-v2.yaml
```

Look for `=> CERTIFIED`: no conflicts across 30 objects, and the three namespaces that must already exist named as a warning, not a failure.

**6. Render the whole platform to one file.**

```sh
cub stack sandbox stack-v2.yaml --out work/platform.yaml
```

Thirty objects, in the order they have to be applied. That file works with `kubectl`, Argo CD or Flux as it is.

**7. Save it as a workspace you can edit and re-certify.**

```sh
cub stack sandbox stack-v2.yaml --workspace work/my-platform
```

The workspace holds the editable components, the manifest, the render and the verdict. Edit a component, certify again, and you have the loop a platform team lives in.

With a ConfigHub account the same stack uploads as governed Spaces, and a fleet manifest places it on many clusters as data. Demo 2 shows that side with one component.

## The AI track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md).

## Reset

```sh
./run.sh --reset
```

This removes the `work/` folder. Nothing else was created.
