# Presenter notes

One story in three steps, about fifteen minutes in all. You are building a small shop app with an AI assistant. Each step has a single moment the audience should remember. Get to that moment, say the line, and move on.

Nothing here needs an account, a server or a cluster until the last two steps of part 2, and you should say so once at the start. Those two steps are optional, and they are where ConfigHub itself comes in.

## Before you start

Run these an hour before, not five minutes before.

```sh
./check.sh
(cd 1-catch-the-ai       && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
(cd 2-my-fixes-survive   && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
(cd 3-what-my-app-needs  && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
```

The first run pulls the Redis chart and the Catalog bundles, so it is slower than the ones after it. Make the terminal font large, and keep a second tab open in the repository root.

Decide which track you will show for each step. A good mix is step 1 from the command line, because the moment lands best with nothing between the audience and the command, then step 2 or step 3 with an assistant, where it does the repair and the tool checks its work.

## 1. Catch the AI (5 minutes)

| Step | Say | Moment |
| --- | --- | --- |
| 1 | "I asked my assistant for Redis with a password, two replicas, a 1Gi disk and a memory limit. This is what it wrote. Looks fine." | |
| 2 | "Helm is happy. Exit code zero." | The render looks healthy |
| 3 | "So which of these values did anything?" | **3 of 7 values did nothing.** Disk, memory limit and replicas, all ignored |
| 4 | "The assistant used another chart's names. Same settings, different places. And one of them means something else here: this chart counts every pod." | |
| 5 | "Ask again." | Every value applied |
| 6 | "And here is what I was really getting." | **An 8Gi disk and no memory limit.** The replicas were right only because of the chart's default |
| 7 | "One line in CI and it cannot happen again." | Exit code 1 |

Close with this line. *Helm said nothing. The assistant said nothing. This took two seconds.*

## 2. My fixes survive the AI (4 minutes)

| Step | Say | Moment |
| --- | --- | --- |
| 1 | "This is the app I am running. Over two weeks I fixed three things by hand." | |
| 2 | "Today I asked for a readiness probe. It rewrote the file. It checks out." | Nothing looks wrong |
| 3 | "Compare it with what I am running." | **Four changes.** One I asked for, and my three fixes undone |
| 4 | "Put them back, compare again." | One change, the probe |
| 5 | "And that review is a file I keep, and a gate I can put in CI." | |
| 6 | "Step 4 was me, by hand, and I will be doing it again next week. So I log in, and ConfigHub keeps the assistant's file and my copy as two linked Units." | My three fixes, as a recorded revision |
| 7 | "The assistant rewrites again. One upgrade. Same diff as before." | **One change, the probe.** Nobody put the fixes back |

Close with this line. *I did not need a second environment. I needed to remember what worked yesterday.*

If you stop at step 5, close with the line above. If you go on to steps 6 and 7, close with this one. *The diff told me what broke. ConfigHub stopped it breaking.*

Steps 6 and 7 need `cub auth login` beforehand, and they write one Space, `workshop-demo-shop`, which `./run.sh --reset` deletes. Without a login the script says so and skips them.

## 3. What my app needs (6 minutes)

| Step | Say | Moment |
| --- | --- | --- |
| 1 | "My app has an Ingress, a Certificate and a ServiceMonitor. What does that assume?" | Three needs, named |
| 2 | "Here is the platform I picked from the Catalog." | |
| 3 | "Will my app run on it?" | **REJECTED**, for two reasons that would have failed quietly on a cluster |
| 4 | "Fix both sides. The app changes one line. The platform gains the Prometheus operator the app asked for." | |
| 5 | "Same command." | **CERTIFIED**, 215 objects, all three needs from step 1 met by name |
| 6–7 | "Every object in apply order, for kubectl, Argo CD or Flux, and a workspace I can keep editing." | |

Close with this line. *Nothing was applied, and I already know it fits.*

## If something goes wrong

- **A step fails.** The script stops and says which command failed. Run `./run.sh --reset`, then `./run.sh N` to pick up at step N once the cause is fixed.
- **`cub config values` is not found.** The workshop plugin is older than 0.6.22. Run `cub plugin upgrade workshop`.
- **The network is down.** Every step still runs, as long as the rehearsal above ran on this machine since it last restarted. Step 1 keeps a copy of the chart after its first run with a network, and says so when it falls back to that copy. Step 2 reads only files. Step 3 reads Catalog bundles from a temporary cache that a restart clears, so rehearse again after a restart. `DEMO_OFFLINE=1 ./run.sh` uses the kept chart without looking for the registry.
- **The assistant wanders off.** Say "stop, run only step N from PROMPT.md". If it keeps wandering, switch to `./run.sh N`. Both tracks run the same commands, so nothing is lost.
