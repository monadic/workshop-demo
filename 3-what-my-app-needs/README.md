# 3. What my app needs

**The point.** An app assumes things about the cluster it lands on: an ingress controller of a certain class, something that issues certificates, something that scrapes metrics. You can find out whether the platform you picked provides them before anything is applied, and fix whichever side is wrong.

**Time.** About six minutes. **Needs.** `cub` and the workshop plugin. No server, no account, no cluster.

```sh
./run.sh
```

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

**4. Fix both sides.** The app moves to the Traefik class and takes its database secret from the platform. The platform gains external-secrets. Two diffs show every line.

**5. Certify again.**

```sh
cub stack certify platform.yaml
```

Look for `=> CERTIFIED`: no conflicts across 135 objects, CRDs ordered before the resources that need them, and `app needs met`. Look at the warnings too. Certify says what it cannot see from here: a ClusterIssuer and a ClusterSecretStore that must already exist on the cluster you deliver to.

**6. Render the platform with the app on it.**

```sh
cub stack sandbox platform.yaml --out work/platform.yaml
```

Every object, in the order it has to be applied. kubectl, Argo CD and Flux all take that file as it is.

**7. Save it as a workspace you can edit and re-certify.** The workspace holds the editable parts, the manifest, the render and the verdict.

## The assistant track

Open Claude Code or Codex in this repository and paste [PROMPT.md](PROMPT.md). In that track the assistant proposes the fix itself, and certify decides whether it holds.

### What a good run looks like

At step 1 the assistant reports three needs: an ingress controller, cert-manager and a Prometheus operator. At step 3 it reports `REJECTED` for two reasons: the Ingress asks for class `nginx` on a Traefik platform, and nothing provides a Prometheus operator for the ServiceMonitor. At step 4 there is more than one honest fix. It can move the Ingress to the `traefik` class and drop or replace the ServiceMonitor, or it can grow the platform. At step 5 certify, not the assistant, decides whether the fix holds. In our own trial the assistant left the platform alone, moved the Ingress to the `traefik` class and removed the ServiceMonitor, and that smaller fix certified with 90 objects. It was not the fix in this folder, and it was still right.

A run has gone wrong if the assistant invents a bundle digest, edits the files it was told to leave alone, or declares the platform certified without running `cub stack certify` on its own files.

## Reset

```sh
./run.sh --reset
```
