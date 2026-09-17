# 3. What my app needs, with an assistant

Open Claude Code or Codex in this repository, then paste everything in the box.

```text
Use the ConfigHub Workshop for this: `cub` and the cub workshop plugin
(https://github.com/confighub/cub-workshop), mainly `cub app check`,
`cub stack certify` and `cub stack sandbox`. Do not contact a ConfigHub server or a
cluster in this session.

Work in the folder 3-what-my-app-needs and keep any files you write in
3-what-my-app-needs/work. Do not edit the four YAML files in the folder. Do not read
shop-web-adapted.yaml or platform.yaml until step 4 says you may.

Do not read README.md, PROMPT.md, WALKTHROUGH.md, run.sh or anything under expected/ in
this repository. They hold the answers, and I want your own work.

Take the steps below one at a time. After each one, show me the command, the part of
the output that matters, and one sentence on what it means. Then stop and wait for me
to say "next".

1. shop-web.yaml is my app. What does it need from a platform before it can run?
2. platform-first-try.yaml is the platform I picked. In plain words, what is in it and
   where does each part come from?
3. Certify my app on that platform. What is the verdict, and what exactly is wrong?
4. Propose the smallest fix. You may change the app, the platform, or both. Write your
   versions to work/shop-web-mine.yaml and work/platform-mine.yaml, with the platform
   file pointing at your app file. If you add a platform part, you may now read
   platform.yaml and take that part's bundle and receipt lines from it; never invent a
   digest. Tell me what you changed and why.
5. Certify your fix. If it is refused, read the reason, fix it, and certify again.
6. Render the certified platform to work/platform-rendered.yaml. How many objects, from
   which parts, and in what order?
7. Save it as an editable workspace in work/shop-platform and tell me how I would
   re-certify after an edit.
```

The README in this folder says what a good run looks like. Read it yourself; the assistant is told not to.
