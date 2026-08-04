---
name: sba-developer
description: This skill will read the story from jira i.e sba-10 or sba-123 or sba-<any number>, it will summerize the requirement, then it will look for git branch, ask if need to create new branch and then it will make changes to the code, code commit and push. update the jira status. anf finally it will update comment in jira with the
arguments : sba-1234 develop
compatibility: Requires JDK 21 or above, springboot 4, postgresqlq Database
allowed-tools: Bash(git:*) Bash(jq:*) Read
---

# Feature development (Jira driven)

This skill is accepting jira id in form of argument and optionally a git branch, if the 2nd argument git branch is not provided then `develop` will be used as base branch.
check the story is in `TODO` state, if any other state is identified then notify the user. read the jira story or task and prepare a summery. never start implementing the story before asking for confirmation, if the story is big multiple features are clubbed, prepare suggestion to break it down to subtask under the main story.
summerize and ask for permission to break it to multiple sub-tasks.

## Input

The user gives a Jira issue key $SBA# (`SBA-<number>` — any number, this isn't limited to a specific
issue) or a full issue URL (`https://sandeep12biswas.atlassian.net/browse/SBA-<number>`). If
neither is present in the request, ask for it before doing anything else — don't guess an issue
key, and don't assume it's always the same one from a previous run of this skill.

Extract the key from a URL with the pattern `/browse/([A-Z]+-\d+)`; otherwise the input is
already the key. This pattern matches any project prefix, not just SCRUM, in case the site ever
has more than one project.

Optionally, the user may also supply a git branch name to build on (e.g. "implement SCRUM-23 off
feature/working-app-V2"). If given, that's the **base branch** the new feature branch gets created
from in Step 4. If not given, the base branch defaults to `develop` — don't ask unless the request is
genuinely ambiguous about which existing branch it relates to.

## Step 1 — Fetch the issue

1. Resolve `cloudId`: try the site hostname (`sandeep12biswas.atlassian.net`) directly as
   `cloudId` first. If that fails, call `mcp__atlassian__getAccessibleAtlassianResources` and use
   the returned `id`.
2. Call `mcp__atlassian__getJiraIssue` with the resolved `cloudId`, the issue key, and
   `fields: ["summary","description","status","issuetype","priority","labels","components","assignee","reporter"]`.
3. If the issue has linked sub-tasks or an epic that materially changes scope, it's fine to
   fetch those too, but don't go spelunking through the whole project — one issue is the unit of
   work here.
4. Change the jira status from 'TODO' to 'In Progress'

If the issue can't be found (bad key, no access), say so plainly and stop — don't fall back to
inventing requirements.

## Step 2 — Summarize

Present a short, plain-language summary before anything else — no code, no file exploration
beyond what's needed to sanity-check feasibility. Cover:

- **What's being asked**, in your own words (don't just paste the Jira description back).
- **Where it likely lands** in this codebase's layers (`app/ui`, `app/controllers`,
  `app/repositories`, `app/models`, `app/db`, etc.) — see the architecture section of
  `CLAUDE.md`. This is a quick read of the ticket against the layering, not a full design doc.
- **Anything ambiguous or underspecified** in the story — acceptance criteria that seem to
  contradict `requirements.md`, missing detail on edge cases, or scope that seems bigger than a
  single story. Ask about these now, before the confirmation step, if they'd change what "done"
  means.
- Check `requirements.md` and `PROGRESS.md`'s "Key design decisions already made" section for
  anything relevant to the feature (autosave, theming, filtering, DB-path, PyInstaller bundling
  are the areas explicitly called out there) — flag it if the story looks like it conflicts with
  an existing decision, rather than silently overriding it.

## Step 3 — Confirm before starting (hard gate)

Use `AskUserQuestion` to get an explicit go-ahead. Something like:

- **Question**: "Ready to start implementing `<the resolved issue key>` as summarized above?"
  (use the actual key from step 1, e.g. `SCRUM-23` — never a hardcoded example key)
- **Options**: proceed as scoped / hold off (I want to change something first) / narrow or
  adjust the scope

Do not write, edit, or run anything beyond read-only exploration until the user confirms. If
they want changes to scope, update the summary and ask again — don't silently reinterpret.

## Step 4 — Branch setup

Once confirmed, before touching any files, set up an isolated branch for this story — never
implement directly on top of whatever branch happened to be checked out when the skill started.

Run the branch setup script before touching any files:

```bash
bash scripts/git-branch-setup.sh <issue-key> [base-branch] [short-slug]
```


