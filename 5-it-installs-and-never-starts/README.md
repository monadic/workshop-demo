# 5. It installs and never starts

**The point.** A chart can name an image that no longer exists. The chart downloads, the values are right, every local check passes, and `helm install` reports success. The pods then sit in `ImagePullBackOff`. One command asks the registry first.

**Time.** About five minutes, or eight with the live proof. **Needs.** `cub`, the workshop plugin (0.6.41 or later), `helm`, `curl`, and a network. Steps 1 to 5 need no cluster. Step 6 builds a throwaway one with `kind`, and only if you ask for it.

```sh
./run.sh
```

Type it with the dot and the slash. It pauses before each command, and Enter runs it. `./run.sh 3` runs step 3 alone, `./run.sh --list` names the steps, and `./run.sh --reset` cleans up, including the throwaway cluster.

## The files

[values.yaml](values.yaml) is what an assistant wrote for "add MySQL for the shop, one instance, with a root password". It picked the chart version it knew, `bitnami/mysql` 14.0.3.

## The steps

**1. Read what the assistant wrote.** An ordinary values file for a well-known chart.

**2. Render it and run the usual checks.**

```sh
helm template shop-db oci://registry-1.docker.io/bitnamicharts/mysql --version 14.0.3 --namespace shop -f values.yaml > work/mysql.yaml
cub config check work/mysql.yaml
```

Every line passes, including the image line: the image is pinned to a version, which is what you want. The chart itself still downloads, because the chart was never withdrawn.

**3. Ask whether the images can be pulled at all.**

```sh
cub config check work/mysql.yaml --images
```

Look for `NOT FOUND: docker.io/bitnami/mysql:9.4.0-debian-12-r1`. The chart is fine, the values are fine, and the image this chart runs is gone. This is the one part of `check` that uses the network, which is why it is a flag.

**4. Read the Workshop's own record of that.**

```sh
curl -s -o work/receipt.json https://raw.githubusercontent.com/confighub/helm-expt/main/runs/bitnami-source-fetch/all-originals-receipt.json
grep -E '"(chart|reference|status|legacyStatus)":' work/receipt.json
```

For each pinned Bitnami chart the Workshop keeps, the receipt records the image it runs and whether that image resolves. `mysql` and `rabbitmq` report `not-found`, with the same tag available under `bitnamilegacy`, which receives no updates. The other four run an image tagged `latest`.

**5. Check what the Catalog offers instead.**

```sh
helm template shop-db mysql-operator --repo https://mysql.github.io/mysql-operator/ --version 2.3.0 --namespace shop --include-crds > work/successor.yaml
cub config check work/successor.yaml --images
```

The Catalog's reviewed successor for MySQL is the operator from Oracle's own MySQL team. Its images pull, and the check names the five CRDs it carries.

`--include-crds` matters: `helm template` leaves a chart's CRDs out unless you ask for them, so without it this render is 8 objects and the check reads `CRDs: 0` for a chart that ships five. Say plainly what the move costs. This is an operator, so it installs a controller and not a database, and the shop then needs a custom resource and a Secret you write. None of the old values carry over.

**6. Prove it on a real cluster.** Optional, and off by default.

```sh
DEMO_CLUSTER=1 ./run.sh 6
```

It builds a throwaway cluster with `kind`, installs the chart that passed every local check, and shows the pods. Look for `ImagePullBackOff` on the same image `--images` called `NOT FOUND`, and for the fact that `helm install` said nothing. `./run.sh --reset` deletes the cluster. It touches no other cluster or kubeconfig you have.

## Use the image check in your own CI

The same strict check works on any rendered configuration your repository produces. Once your normal render step has written a file, make the image check the gate:

```sh
cub config check path/to/rendered.yaml --images --exit-code
```

Exit 0 means every discovered image manifest was checked anonymously. Exit 1 means a registry confirmed that at least one image is missing. Exit 2 means the check was incomplete, such as a network or authentication failure, or the command was invalid. The ordinary `cub config check ... --images` command in step 3 remains advisory and does not fail the build. This gate checks images found by the static image extractor at the time it runs; it does not prove startup, scheduling, chart compatibility, or application health.

## How it knows

`cub config check --images` reads every container image in the rendered objects, normalises each name the way a registry expects it, and asks that registry for the image's manifest with no credentials. The answers are `pulls`, `NOT FOUND`, `needs credentials` for a private image your cluster may still be able to pull, and `could not be checked`. Nothing is installed and nothing is downloaded but the manifest.

## The assistant track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md). Compare its answers with the files in [expected/](expected/).

### What a good run looks like

At step 2 the assistant reports that everything passes and says the image is pinned. At step 3 it reports `NOT FOUND` and is clear that the chart and the values are not the problem. At step 4 it reads the receipt and names `mysql` and `rabbitmq`, and says the `bitnamilegacy` copies are unpatched. At step 5 it finds the reviewed successor, renders it with `--include-crds`, and shows that its images pull and that it carries five CRDs. A careful one says what the move costs: the successor is an operator, so it installs a controller and not a database, and none of the old values carry over.

A run has gone wrong if the assistant declares the chart fine after step 2, claims from memory which images are missing instead of asking the registry, or recommends `bitnamilegacy` without saying it receives no updates.

## Reset

```sh
./run.sh --reset
```
