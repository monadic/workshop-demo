# 3. What my app needs

**The point.** An app assumes things about the cluster it lands on: an ingress controller of a certain class, something that issues certificates, something that scrapes metrics. You can find out whether the platform you picked provides them before anything is applied, and fix whichever side is wrong.

**Time.** About six minutes. **Needs.** `cub` and the workshop plugin. No server, no account, no cluster.

```sh
./run.sh
```

Type it with the dot and the slash. It pauses before each command, and Enter runs it. `./run.sh 3` runs step 3 alone, `./run.sh --list` names the steps, and `./run.sh --reset` cleans up. The assistant track in [PROMPT.md](PROMPT.md) has the same steps with the same numbers, and the assistant shows the by-hand command after each one.

## The files

[shop-web.yaml](shop-web.yaml) is the shop app as the assistant wrote it: a Deployment, a Service, an Ingress of class `nginx`, a Certificate and a ServiceMonitor.

[platform-first-try.yaml](platform-first-try.yaml) is the platform you picked first from the Workshop Catalog: cert-manager, Traefik and metrics-server, each pinned by digest, with the app placed on it.

[shop-web-adapted.yaml](shop-web-adapted.yaml) and [platform.yaml](platform.yaml) are the two after the fix.

## The steps

**1. Ask what the app needs from a platform.**

```sh
cub app check shop-web.yaml
```

Look for three `NEEDS` lines: an ingress controller, cert-manager, and a Prometheus operator.

**2. Look at the platform you picked first.** Three Catalog parts and the app.

**3. Certify the app on that platform, and get refused.**

```sh
cub stack certify platform-first-try.yaml
```

Look for `=> REJECTED` and the two reasons. The Ingress asks for class `nginx` and this platform's controller is Traefik. The ServiceMonitor needs a Prometheus operator and nothing here provides one. Both would have failed quietly on a real cluster.

**4. Fix both sides.** The app changes one line and moves to the `traefik` ingress class, because the platform already has that controller. The platform gains one part from the Catalog, kube-prometheus-stack, because the app asked for a Prometheus operator and should keep its monitoring. Two diffs show every line.

**5. Certify again.**

```sh
cub stack certify platform.yaml
```

Look for `=> CERTIFIED`: no conflicts across 215 objects, CRDs ordered before the resources that need them, and `app needs met` naming all three needs from step 1. Look at the warnings too. Certify says what it cannot see from here: five namespaces and a ClusterIssuer that must already exist on the cluster you deliver to.

**6. Render the platform with the app on it.**

```sh
cub stack sandbox platform.yaml --out work/platform.yaml
```

Every object, in the order it has to be applied. kubectl, Argo CD and Flux all take that file as it is.

**7. Save it as a workspace you can edit and re-certify.** The workspace holds the editable parts, the manifest, the render and the verdict.

## The assistant track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md). In that track the assistant proposes the fix itself, and certify decides whether it holds.

### What a good run looks like

At step 1 the assistant reports three needs: an ingress controller, cert-manager and a Prometheus operator. At step 3 it reports `REJECTED` for two reasons: the Ingress asks for class `nginx` on a Traefik platform, and nothing provides a Prometheus operator for the ServiceMonitor. At step 4 there is more than one fix that certifies. The one in this folder moves the Ingress to the `traefik` class and adds kube-prometheus-stack to the platform, so the app keeps its monitoring. A smaller one moves the class and deletes the ServiceMonitor, and it certifies with 90 objects. A good assistant that takes the smaller one says plainly that the app loses its monitoring. At step 5 certify, not the assistant, decides whether the fix holds.

In our own trials the assistant took the smaller fix and did say what it cost. An earlier version of this folder fixed the app by swapping the ServiceMonitor for something unrelated, and a trial assistant pointed out that this removed the problem without solving it. The fix here now solves it.

A run has gone wrong if the assistant invents a bundle digest, edits the files it was told to leave alone, or declares the platform certified without running `cub stack certify` on its own files.

## Reset

```sh
./run.sh --reset
```
