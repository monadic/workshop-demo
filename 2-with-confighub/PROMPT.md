# Demo 2 with an AI agent

Log in first with `cub auth login`. Then open Claude Code or Codex in this repository and paste everything in the box.

```text
Use the ConfigHub Workshop for this: `cub` and the cub workshop plugin
(https://github.com/confighub/cub-workshop). I am logged in to ConfigHub with
`cub auth login`.

Rules for this session. Create and change only Spaces whose names start with
"wsdemo-". Do not delete anything unless I ask. Show me each command before you run
it. If a command is refused, do not work around it; show me the refusal and explain it.

Work in the folder 2-with-confighub and keep files in 2-with-confighub/work. Take the
steps below one at a time. After each one, show me the command, the part of the output
that matters, and one sentence on what it means. Then stop and wait for me to say "next".

1. Tell me which ConfigHub organization and server I am logged in to.
2. Render the Redis chart from the catalog to work/redis.yaml.
3. Upload that file into ConfigHub as the base variant of a component called
   wsdemo-redis, then list the Units it created.
4. Create a Space called wsdemo-staging with a server worker called "worker" and an
   OCI target called "target" (provider OCI, toolchain Any, empty parameters).
5. On the base Space, add a rule that every Unit must be approved by one person
   before it can ship: a Mutation trigger called require-approval that uses the
   vet-approvedby function with the argument 1.
6. Place the base on that target as a variant called staging, and tell me how many
   Units are waiting for approval.
7. Try to publish a release of the placed Space. Tell me exactly what happened and why.
8. Approve the waiting Units, publish the release, and show me its manifest digest.
9. Scale the redis-master Unit in the base to 3 replicas. Preview the promotion to the
   placed Space with a dry run, then promote it, approve it, and publish again. Show me
   both release digests.
```

## What a good run looks like

The agent runs the same commands as `./run.sh`. At step 7 it reports a refusal that names `wsdemo-redis-base/require-approval/vet-approvedby`, and it does not try to get around it. At step 8 it shows a `sha256:` manifest digest, and at step 9 a second one.

A run has gone wrong if the agent creates Spaces without the `wsdemo-` prefix, deletes something unasked, or "fixes" the refusal at step 7 by removing the rule.

## Afterwards

Ask the agent to run `./run.sh --reset` in `2-with-confighub`, or run it yourself.
