---
name: sba-developer
description: This skill reads a Jira story or task (e.g. sba-10, sba-123, or any sba-<number>), summarizes the requirement, checks for an existing git branch (asking to create one if needed), implements the changes, writes tests, commits and pushes the code, updates the Jira status, and finally adds a comment to the Jira issue summarizing what changed, the test results, and the feature branch pushed.
arguments: sba-1234 develop
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
  (use the actual key from step 1, e.g. `SBA-23` — never a hardcoded example key)
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

## Step 5 - Plan the implementation steps

You are experienced developer, break down the problem statement develop layered design approach and modularize the code. follow the following convention

- search and read API yaml file file if present for API specification.
- When exposing endpoint, create/update the specification yaml file under project root directory for client use. 
- use Camel case for variables.
- use sufficient logger message for info, debug and error messages.
- explain the plan and ask if any modification or change in design is required or good to proceed

# Step 6 — Unit testing

Once the change is implemented:

1. Write or extend tests under `tests/` matching the existing conventions for the layer touched
   (plain `conn`-fixture tests for repositories, `qtbot`-driven tests under `tests/ui/` for
   widgets — see the "Testing conventions" section of `CLAUDE.md`, including the notes on
   `QTest.qWait` for debounce/polling timers and driving real widgets instead of calling
   controller methods directly).
2. Run the full suite: `QT_QPA_PLATFORM=offscreen pytest`. Don't stop at "the new test passes" —
   a layering or autosave change can break unrelated tests.
3. If anything fails, fix it and rerun until the suite is green. Report the actual pass/fail
   counts — don't claim success without having run it.

## Step 7 — Code commit, push the code to git hub

Only after Step 6's test suite is green:

1. Review scope before staging: `git status` / `git diff` to confirm everything staged actually
   belongs to this story. `git add` the touched files (or `git add -A` only if the whole diff is
   in-scope) — don't sweep in unrelated stray changes.
2. Commit with a message following this repo's existing convention (see `git log`, e.g.
   `Added feature # SCRUM-8 - font family to the text editor`):
   `<Verb> feature # <issue-key> - <short plain-language description>`, using the real issue key
   from Step 1. End the commit message with:
   `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`
3. Push the feature branch created in Step 4 to `origin`, never `main` directly:
   `git push -u origin <feature-branch>` on the first push (plain `git push` after that, since
   `-u` already set the upstream).
4. If the push is rejected (e.g. the remote has diverged), stop and ask the user how to proceed —
   don't force-push without being explicitly told to.
5. Report the branch name pushed and confirm success from the actual `git push` output — don't
   claim it pushed without having run it. Opening a pull request is optional and belongs in Step 9
   (wrap-up) as something to offer, not do unasked.

## Step 8 — Update the Jira ticket

Once the feature branch is pushed, close the loop on the ticket itself — do this automatically as
part of finishing the story, not as something to offer/ask permission for (unlike opening a PR in
Step 9):

1. Post a summary comment on the issue via `mcp__atlassian__addCommentToJiraIssue` covering what
   changed (files touched), how it maps back to the story's acceptance criteria, the test result
   (counts, not just "tests pass"), and the feature branch name — the same level of detail you'd
   give the user in Step 9's wrap-up.
2. Transition the issue via `mcp__atlassian__getTransitionsForJiraIssue` +
   `mcp__atlassian__transitionJiraIssue` to whichever returned transition's target status is named
   **"In Review"** — look it up rather than hardcoding a transition ID, since IDs can differ across
   projects/workflows.

## Step 9 — Wrap up

- Summarize what changed: files touched, and a one-line mapping back to the story's acceptance
  criteria (does each point from the ticket have a corresponding change?).
- Report the final test run result verbatim (counts, not just "tests pass").
- `PROGRESS.md`/`tasklist.md` and `README` get updated per *phase*, not per individual task/story — don't
  update them reflexively here. If this story completes a phase of work, ask the user whether
  they want those docs updated now.
- Optionally offer (don't do it unasked) to open a pull request from the pushed feature branch
  (e.g. via `gh pr create`) targeting the base branch resolved in Step 4. 