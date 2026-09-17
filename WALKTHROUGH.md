# Presenter notes

Three demos, about twenty minutes in all. Each one has a single moment the audience should remember. Get to that moment, say the line, and move on.

## Before you start

Run these an hour before, not five minutes before.

```sh
./check.sh --hub
(cd 1-no-server    && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
(cd 3-diy-platform && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
(cd 2-with-confighub && DEMO_AUTO=1 ./run.sh && ./run.sh --reset)
```

The first run pulls Catalog bundles, so it is slower than the ones after it. Make the terminal font large, and keep a second tab open in the repository root.

Decide now which track you will show for each demo. A good mix is demo 1 from the command line, demo 3 with an agent, and demo 2 from the command line, because the refusal in demo 2 lands best when nothing stands between the audience and the command.

## Demo 1. No server, no account (5 minutes)

| Step | Say | Moment |
| --- | --- | --- |
| 1 | "What will this chart put in my cluster? One command, no cluster, no account." | 14 objects, named by kind |
| 2 | "And now it is a file. Config as data." | |
| 3 | "I meant to scale it. Did I change anything else?" | **The second change.** The disruption budget went to zero, and the diff names the exact field |
| 4 | "A whole platform goes through the same check." | CERTIFIED, 130 objects, 8 components |
| 5 | "And when two parts claim the same objects, it says no." | REJECTED, exit code 1 |

Close with this line. *You knew all of this before anything ran.*

## Demo 3. Build your own platform (6 minutes)

| Step | Say | Moment |
| --- | --- | --- |
| 1–2 | "A platform is a list of parts. Here is ours, nineteen lines." | |
| 3 | "Two teams both added metrics. Nobody noticed." | **REJECTED**, nine conflicts, both components named |
| 4 | "The fix is three lines." | |
| 5 | "Same command." | **CERTIFIED** |
| 6–7 | "Thirty objects in apply order, and a workspace I can keep editing." | |

Close with this line. *Certify is the contract you build against.*

If you show this one with an agent, stop after step 4 and compare the agent's fix with `stack-v2.yaml` on screen. It should be the same three lines.

## Demo 2. With a ConfigHub account (7 minutes)

Open with the question: "So why would I get an account?"

| Step | Say | Moment |
| --- | --- | --- |
| 1 | "This is my organization. Everything I make starts with wsdemo." | |
| 2–3 | "The same file from demo 1, now kept. One Unit per object, every revision recorded." | 13 Units |
| 4 | "A target is where a release goes. Argo CD or Flux pulls from it." | |
| 5 | "One rule on the base. Nothing ships unapproved." | |
| 6 | "Place it on staging. The copy inherits the rule." | 13 Units gated |
| 7 | "Let's ship it." | **Refused**, and the refusal names the rule |
| 8 | "Approve. Ship." | The `sha256:` digest |
| 9 | Only if there is time. "Change the base, preview, promote, approve, release." | Two digests in the list |

Close with this line. *The rule held, it said why, and the release is a digest that never changes.*

## If something goes wrong

- **A step fails.** The script stops and says which command failed. Run `./run.sh --reset`, then `./run.sh N` to pick up at step N once the cause is fixed.
- **Demo 2 says a Space already exists.** An earlier run was not reset. Run `./run.sh --reset`.
- **Demo 2 cannot log in.** Run `cub auth login` again. Tokens expire after a few hours.
- **The network is down.** Demos 1 and 3 run from the local cache once they have run once on this machine. Skip demo 2 and show its `expected/` files instead.
- **The agent wanders off.** Say "stop, run only step N from PROMPT.md". If it keeps wandering, switch to `./run.sh N`. Both tracks run the same commands, so nothing is lost.

## After the session

```sh
(cd 2-with-confighub && ./run.sh --reset)
```
