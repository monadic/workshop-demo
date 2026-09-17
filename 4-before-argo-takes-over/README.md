# 4. Before Argo CD takes over

**The point.** A chart can decide things you never wrote, and `helm install` hides some of them. This Redis has run for a month from three lines of values. Under Argo CD or Flux its password changes on every sync, its image is tagged `latest`, and a preset you never chose sets its memory. You can see all three before the move, and the Workshop Catalog has a reviewed alternative with none of them.

**Time.** About six minutes. **Needs.** `cub`, the workshop plugin (0.6.26 or later), `helm`, `oras`, `curl`, and a network. No server, no account, no cluster.

```sh
./run.sh
```

Type it with the dot and the slash. It pauses before each command, and Enter runs it. `./run.sh 3` runs step 3 alone, `./run.sh --list` names the steps, and `./run.sh --reset` cleans up. The assistant track in [PROMPT.md](PROMPT.md) has the same steps with the same numbers, and the assistant shows the by-hand command after each one.

## The files

[values.yaml](values.yaml) is what an assistant wrote a month ago for "a Redis cache with a password, standalone is fine", for the Bitnami Redis chart 25.5.3. It has run from `helm install` ever since.

[values-successor.yaml](values-successor.yaml) is the Workshop Catalog's reviewed base for `cloudpirates/redis` 0.34.11, `reuse-existing-secret`, with a 512Mi memory limit added.

## The steps

**1. Read what has been running.** Three lines, and nothing looks wrong.

**2. See what it installs.**

```sh
helm template shop-redis oci://registry-1.docker.io/bitnamicharts/redis --version 25.5.3 --namespace shop -f values.yaml > work/bitnami.yaml
cub config check work/bitnami.yaml
```

Look for the `NOTE` line. The Redis image is `bitnami/redis:latest`, so the same name can pull a different Redis next week.

**3. Render it twice, the way Argo CD will.** Argo CD renders the chart on every sync, without reading anything back from your cluster.

```sh
helm template shop-redis oci://registry-1.docker.io/bitnamicharts/redis --version 25.5.3 --namespace shop -f values.yaml > work/bitnami-again.yaml
cub config diff work/bitnami.yaml work/bitnami-again.yaml
```

Look for one changed field, `/data/redis-password`. Same chart, same values, a different password. The diff shows a short hash of each value, never the value. Under Argo CD every sync writes a new password while the shop app holds the old one. `helm install` and `helm upgrade` hid this, because this chart reads the Secret back from the cluster.

**4. Ask what the chart does that you did not write.**

```sh
cub config values oci://registry-1.docker.io/bitnamicharts/redis --version 25.5.3 --release shop-redis --namespace shop --values values.yaml
```

Look under *What the chart does that you did not write*. `master.resourcesPreset is "nano"` sets Redis's CPU and memory, a 192Mi memory limit, and you never chose it. The password field changes on every render.

**5. Try to pin the image to a version.**

```sh
oras manifest fetch docker.io/bitnami/redis:7.4.1-debian-12-r2
oras manifest fetch --descriptor docker.io/bitnamilegacy/redis:7.4.1-debian-12-r2
```

That tag is the one an older release of this chart, 20.6.0, pinned. The first is refused and the second is found. Versioned Bitnami images now sit behind a paid tier, the `bitnamilegacy` copies get no updates, and the free chart runs `latest`. The Workshop's [Did your Bitnami chart stop pulling?](https://confighub.github.io/helm-expt/site/did-your-bitnami-chart-stop-pulling.html) page records which pinned charts are affected, with its receipt.

**6. Ask the Workshop Catalog for a reviewed alternative.** The Catalog is public data, with no account.

```sh
curl -s -o work/index.json https://confighub.github.io/helm-expt/site/listings/index.json
grep -o '"id": "cloudpirates-redis[^"]*"' work/index.json
curl -s -o work/listing.json https://confighub.github.io/helm-expt/site/listings/cloudpirates-redis-0-34-11-reuse-existing-secret.json
grep -m 3 -o -E '"(name|version|base)": "[^"]*"' work/listing.json
grep -m 1 -o '"sourcePackageRef": "[^"]*"' work/listing.json
```

Look for `cloudpirates/redis` 0.34.11 with the base `reuse-existing-secret`, which keeps the password in a Secret you create, and the reviewed package pinned by digest.

**7. Check the alternative, with your memory limit.**

```sh
helm template shop-redis oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --namespace shop -f values-successor.yaml > work/successor.yaml
cub config check work/successor.yaml
cub config values oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --release shop-redis --namespace shop --values values-successor.yaml
```

Look for `images tagged latest or not tagged: 0`, because the image is pinned by digest. Every value applies, and there is no preset and no field that changes on every render.

**8. Render the alternative twice.**

```sh
helm template shop-redis oci://registry-1.docker.io/cloudpirates/redis --version 0.34.11 --namespace shop -f values-successor.yaml > work/successor-again.yaml
cub config diff work/successor.yaml work/successor-again.yaml
```

Look for `0 changed`. Argo CD would find nothing to change.

## How it knows

`cub config check` reads every container image in the rendered objects. `cub config values` renders the chart twice with the same values and names every field that differs. It then sets each `resourcesPreset` it finds to `none` and renders again, so it reports only a preset that is really in force. Nothing is applied and no value is printed.

## The assistant track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md). Compare its answers with the files in [expected/](expected/).

### What a good run looks like

At step 2 the assistant names the `latest` image. At step 3 it reports that the password differs between two renders and explains what Argo CD does with that. It also explains why `helm upgrade` did not show it: the chart reads the Secret back from the cluster. At step 4 it names the `nano` preset and its 192Mi memory limit. At step 5 it shows that the versioned Bitnami tag is refused and exists only under `bitnamilegacy`. At step 6 it finds `cloudpirates-redis-0-34-11-reuse-existing-secret` in the Catalog listings by reading them as data. At steps 7 and 8 it shows no `latest` image, no preset, no field that changes on every render, and a second render with `0 changed`.

A run has gone wrong if the assistant prints the password, recommends pinning `bitnami/redis` to a version tag without checking that the tag exists, invents a Catalog entry or digest, or declares the move safe without the step 8 comparison.

In our own trial, an assistant without the Workshop read this chart by hand for eight commands. It found the `latest` image and the preset, suspected the password, then found the chart keeps it on `helm upgrade`. It did not tell the developer about the Argo CD case.

## Reset

```sh
./run.sh --reset
```
