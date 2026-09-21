# Presenter notes

One story in five steps, about twenty-five minutes in all. You are building a small shop app with an AI assistant. Each step has a single moment the audience should remember. Get to that moment, say the line, and move on.

Nothing here needs an account, a server or a cluster until the last two steps of part 2, and you should say so once at the start. Those two steps are optional, and they are where ConfigHub itself comes in.

## Before you start

Run these an hour before, not five minutes before.

```sh
./check.sh
(cd 1-catch-the-ai       && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
(cd 2-my-fixes-survive   && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
(cd 3-what-my-app-needs  && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
(cd 4-before-argo-takes-over && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
(cd 5-it-installs-and-never-starts && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
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

Steps 6 and 7 need `cub auth login` beforehand. Choose a new Space you own with `DEMO_SPACE=my-workshop-space ./run.sh 6`, then use the same value for step 7. The script refuses an existing Space, records its server and Space identities before it creates Units, and checks them before step 7. `./run.sh --reset` removes local work only. Without `DEMO_SPACE`, the script says so and skips them; a named Space with a ConfigHub lookup error stops and shows that error.

## 3. What my app needs (6 minutes)

| Step | Say | Moment |
| --- | --- | --- |
| 1 | "My app has an Ingress, a Certificate and a ServiceMonitor. What does that assume?" | Three needs, named |
| 2 | "Here is the platform I picked from the Catalog." | |
| 3 | "Will my app run on it?" | **REFUSED**, for two reasons that would have failed quietly on a cluster |
| 4 | "Fix both sides. The app changes one line. The platform gains the Prometheus operator the app asked for." | |
| 5 | "Same command." | **CHECKED**, 215 objects, all three needs from step 1 met by name |
| 6–7 | "Every object in apply order, for kubectl, Argo CD or Flux, and a workspace I can keep editing." | |

Close with this line. *Nothing was applied, and I already know it fits.*

## 4. Before Argo CD takes over (6 minutes)

| Step | Say | Moment |
| --- | --- | --- |
| 1 | "Three lines of values. This Redis has run fine from helm install for a month. Next week Argo CD takes over." | |
| 2 | "What does it really install?" | The image is tagged **latest** |
| 3 | "Argo CD renders the chart on every sync. So render it twice." | **The password changes.** Same chart, same values. helm install hid it, because it reads the Secret back from the cluster |
| 4 | "What else is the chart deciding for me?" | **A 192Mi memory preset** nobody chose, and the password again, named |
| 5 | "Fine, pin the image to a version." | **Refused.** Versioned Bitnami images are behind a paid tier. Only an unpatched legacy copy remains |
| 6 | "Ask the Workshop Catalog. It is data, with no account." | A reviewed Redis, pinned by digest, with a base that keeps the password in your own Secret |
| 7 | "Same checks." | No latest image, no preset, nothing that changes on every render |
| 8 | "And the Argo CD test." | **0 changed** |

Close with this line. *helm install looked fine for a month. Two renders showed what Argo CD would have done on day one.*

If someone asks whether Claude would catch this, the honest answer is sometimes. In our trial an assistant without the Workshop found the image and the preset by reading the chart for eight commands, and did not tell the developer about the Argo CD case. The Workshop gives the same answer in one command, and the same command works in CI.

## 5. It installs and never starts (5 minutes, 8 with the live proof)

| Step | Say | Moment |
| --- | --- | --- |
| 1–2 | "I asked for MySQL, this came back, and every check passes. The image is even pinned to a version." | Everything green |
| 3 | "One thing my laptop cannot know: does that image still exist?" | **NOT FOUND**, before the install |
| 4 | "The Workshop measured this and kept the receipt." | mysql and rabbitmq, with only unpatched legacy copies left |
| 5 | "What did the Catalog review instead?" | A successor whose images pull |
| 6 | "If you don't believe me." | **ImagePullBackOff** on the same image, and helm install said nothing |

Close with this line. *The chart was fine. The values were fine. The image was gone, and only the registry could tell me.*

Step 6 is optional and off by default. Run it with `DEMO_CLUSTER=1 ./run.sh 6`, and have the cluster already built before you present, because building it takes about two minutes. `./run.sh --reset` deletes it.

## If something goes wrong

- **A step fails.** The script stops and says which command failed. Run `./run.sh --reset`, then `./run.sh N` to pick up at step N once the cause is fixed.
- **`cub config values` is not found.** The workshop plugin is older than 0.6.22. Run `cub plugin upgrade workshop`.
- **The network is down.** Every step still runs, as long as the rehearsal above ran on this machine since it last restarted. Step 1 keeps a copy of the chart after its first run with a network, and says so when it falls back to that copy. Step 2 reads only files. Step 3 reads Catalog bundles from a temporary cache that a restart clears, so rehearse again after a restart. `DEMO_OFFLINE=1 ./run.sh` uses the kept chart without looking for the registry.
- **The assistant wanders off.** Say "stop, run only step N from PROMPT.md". If it keeps wandering, switch to `./run.sh N`. Both tracks run the same commands, so nothing is lost.
