# 1. Catch the AI, with an assistant

Open Claude Code or Codex in this repository, then paste everything in the box.

```text
Use the ConfigHub Workshop for this. It is a public catalog of known-good Kubernetes
configurations you can read as data, with no account. Start at
https://confighub.github.io/helm-expt/site/llms.txt and do the work with `cub` and the
cub workshop plugin (https://github.com/confighub/cub-workshop): `cub config check`,
`cub config values` and `cub config diff`. Do not contact a ConfigHub server or a
cluster in this session. Never print a secret value.

Work in the folder 1-catch-the-ai and keep any files you write in 1-catch-the-ai/work.
Do not edit values.yaml or values-fixed.yaml, and do not read values-fixed.yaml until
step 4 asks you to. The chart is oci://registry-1.docker.io/cloudpirates/redis at
version 0.34.11, release name shop-redis, namespace shop.

Do not read README.md, PROMPT.md, WALKTHROUGH.md, run.sh or anything under expected/ in
this repository. They hold the answers, and I want your own work.

Take the steps below one at a time. After each one, show me the command, the part of
the output that matters, and one sentence on what it means. Then stop and wait for me
to say "next".

1. Read values.yaml. Another assistant wrote it for "a password, two replicas, a 1Gi
   disk, a memory limit, and metrics on". From reading it alone, does it look right?
2. Render the chart with those values into work/redis.yaml, and tell me what it would
   install. Did Helm complain about anything?
3. Now check which of the values in values.yaml actually did anything. How many did
   nothing, which ones, and why?
4. Write a corrected file to work/values-mine.yaml that asks for the same things in the
   places this chart reads them. Then compare your file with values-fixed.yaml.
5. Check your corrected file the same way as in step 3.
6. Render your corrected file to work/redis-mine.yaml and show me exactly what changed
   in the Kubernetes objects. What was I really getting before?
7. Give me one line I could add to CI so this cannot happen again, and show that it
   fails on values.yaml.
```

The README in this folder says what a good run looks like. Read it yourself; the assistant is told not to.
