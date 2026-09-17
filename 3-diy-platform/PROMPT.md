# Demo 3 with an AI agent

Open Claude Code or Codex in this repository, then paste everything in the box.

```text
Use the ConfigHub Workshop for this: `cub` and the cub workshop plugin
(https://github.com/confighub/cub-workshop), mainly `cub stack certify` and
`cub stack sandbox`. Do not contact a ConfigHub server or a cluster in this session.

Work in the folder 3-diy-platform and keep any files you write in
3-diy-platform/work. Do not edit stack-v1.yaml or stack-v2.yaml. Take the steps below
one at a time. After each one, show me the command, the part of the output that
matters, and one sentence on what it means. Then stop and wait for me to say "next".

1. Show me which stacks ship with the workshop plugin.
2. Read stack-v1.yaml and tell me, in plain words, what platform it describes and
   where each part comes from.
3. Certify stack-v1.yaml. What is the verdict, and what exactly is wrong?
4. Propose the smallest change to the manifest that would fix it. Write your fixed
   version to work/my-stack.yaml, and tell me how it differs from stack-v2.yaml.
5. Certify your fixed manifest. What did the check verify, and what does the warning mean?
6. Render the certified platform to work/platform.yaml. How many objects, from which
   components, and in what order are they written?
7. Save the platform as an editable workspace in work/my-platform and tell me what is
   in it and how I would re-certify after an edit.
```

## What a good run looks like

At step 3 the agent reports `REJECTED` with nine conflicts between `metrics-server` and `team-b-metrics`. At step 4 it removes the duplicate component and lands on the same manifest as `stack-v2.yaml`. At step 5 it reports `CERTIFIED` with 30 objects, and explains that the warning lists namespaces the cluster must already have.

A run has gone wrong if the agent fixes the conflict by renaming Kubernetes objects inside a bundle, or claims the platform is certified without running `cub stack certify` on its own file.
