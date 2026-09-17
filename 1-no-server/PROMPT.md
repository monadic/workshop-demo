# Demo 1 with an AI agent

Open Claude Code or Codex in this repository, then paste everything in the box.

```text
Use the ConfigHub Workshop for this. It is a public catalog of known-good Kubernetes
configurations you can read as data, with no account. Start at
https://confighub.github.io/helm-expt/site/llms.txt and do the work with `cub` and the
cub workshop plugin (https://github.com/confighub/cub-workshop): `cub config` and
`cub config diff`, `cub stack certify` and `cub stack sandbox`. Prefer exact versions
and digests. Do not contact a ConfigHub server or a cluster in this session.

Work in the folder 1-no-server and keep any files you write in 1-no-server/work.
Take the five questions below one at a time. For each one, run the command you need,
show me the command and the part of its output that answers the question, and then
stop and wait for me to say "next".

1. What exactly would the Redis chart from the catalog install, and what has to exist
   in the cluster first?
2. Save those exact objects to work/before.yaml and tell me how many there are.
3. Make a copy called work/after.yaml in which the redis-master StatefulSet has 3
   replicas, and the redis-master PodDisruptionBudget has maxUnavailable 0. Then show
   me what changed between the two files, field by field. Which of the two changes
   would worry you in production, and why?
4. Is the eks-inference stack safe to compose? How many objects and components, and
   what did the check verify?
5. Certify the stack called metrics-double and explain the verdict in one paragraph.
   What is the exit code, and why does that matter?
```

## What a good run looks like

The agent runs the same five commands as `./run.sh` and reports the same facts: 14 objects and the `redis` namespace, two changed fields, `CERTIFIED` with 130 objects across eight components, and `REJECTED` with nine conflicts and a non-zero exit code. The files in [expected/](expected/) hold the real output of each step.

A run has gone wrong if the agent answers from memory without running `cub`, renders the chart with Helm instead, or reports a count it did not see in the output.
