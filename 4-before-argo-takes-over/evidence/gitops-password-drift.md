# What happens on a real cluster

Step 3 of this demo shows that two renders of the same chart with the same values
produce different passwords. This is what that does to a running Redis. It was run
on a throwaway `kind` cluster on 2026-09-17, with Bitnami Redis 25.5.3 and the
`values.yaml` in this folder. The demo itself needs no cluster; this is here so a
presenter can answer "does it really break?" with a record rather than a claim.

Passwords are never printed. Each one is shown as the first twelve characters of its
SHA-256.

## Install it the way the developer did

```sh
helm install shop-redis oci://registry-1.docker.io/bitnamicharts/redis \
  --version 25.5.3 -n shop -f values.yaml --wait
```

```
shop-redis-master-0   1/1   Running
password in the cluster now: sha 9ed0a104a57e
```

## One GitOps sync: render the chart again, and apply it

```sh
helm template shop-redis oci://registry-1.docker.io/bitnamicharts/redis \
  --version 25.5.3 -n shop -f values.yaml > sync.yaml
kubectl apply -n shop -f sync.yaml
```

```
secret/shop-redis configured
password in the cluster after the sync: sha 2e1065563f1a
CHANGED by the sync
```

## Who is broken, and when

Straight after the sync, the Secret holds the new password and the running Redis still
has the old one. Anything that reads the Secret now fails.

```
an app using the Secret as it now stands:
  NOAUTH Authentication required.
  AUTH failed: WRONGPASS invalid username-password pair or user is disabled.

what the running Redis still expects:
  PONG
```

Then the pod restarts, as any node drain, upgrade or rollout would restart it. Redis
reads the new Secret, and the app that has held the password since install time fails.

```
the app that still holds the password from install time:
  AUTH failed: WRONGPASS invalid username-password pair or user is disabled.
a client reading the Secret now:
  PONG
```

Either way, someone is holding a password that no longer works. Nothing failed at
sync time, and `helm install` had hidden this for as long as it was in charge, because
this chart reads the existing Secret back from the cluster and a client-side render
cannot.

## What the demo checks instead

`cub config diff` between two renders names the field before any of this reaches a
cluster, and `cub config values` names it as a field that changes on every render.
The Catalog's reviewed `reuse-existing-secret` base keeps the password in a Secret you
create, so there is nothing for a sync to change.
