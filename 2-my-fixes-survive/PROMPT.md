# 2. My fixes survive the AI, with an assistant

Open Claude Code or Codex in this repository, then paste everything in the box.

```text
Use the ConfigHub Workshop for this: `cub` and the cub workshop plugin
(https://github.com/confighub/cub-workshop), mainly `cub config check` and
`cub config diff`. Do not contact a ConfigHub server or a cluster in this session.

Work in the folder 2-my-fixes-survive and keep any files you write in
2-my-fixes-survive/work. Do not edit the three app-*.yaml files, and do not read
app-restored.yaml until step 4 asks you to.

The story: app-committed.yaml is the shop app I am running today. Over the last two
weeks I fixed a few things in it by hand. Today I asked an assistant to add a readiness
probe, and it gave me app-regenerated.yaml.

Do not read README.md, PROMPT.md, WALKTHROUGH.md, run.sh or anything under expected/ in
this repository. They hold the answers, and I want your own work.

Take the steps below one at a time. After each one, show me the command, the part of
the output that matters, and one sentence on what it means. Then stop and wait for me
to say "next".

1. Check app-regenerated.yaml on its own. Would it deploy? Does anything look wrong?
2. Compare it with app-committed.yaml. List every field that changed. Which one did I
   ask for, and which did I not?
3. For each change I did not ask for, tell me what would happen in production if I
   applied the file as it is.
4. Write work/app-mine.yaml: the regenerated file with my earlier fixes restored and
   the readiness probe kept. Then compare your file with app-restored.yaml.
5. Prove your file is right: compare it with app-committed.yaml and show that the only
   change left is the one I asked for.
6. Save a review record of the comparison in step 2 to work/review.json, and tell me
   what it holds and how I would use the same command as a gate in CI.
```

The README in this folder says what a good run looks like. Read it yourself; the assistant is told not to.
