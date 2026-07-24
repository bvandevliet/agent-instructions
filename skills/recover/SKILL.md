---
name: recover
description: Resumes work after an unintentional interruption (dropped connection, crashed session, accidental stop, session/usage limit reached mid-task). Trigger this whenever the user invokes /recover, or says things like "pick up where you left off", "we got cut off", "continue where we stopped", or "resume the task" after an apparent interruption.
---

Treat this exactly as if the user said:

"You were interrupted mid-process unintentionally — possibly because the session/usage limit was reached. Pick up and proceed/continue the task(s) you were doing from where you left off."

Before resuming, reconcile any dangling state left by the interruption:
- Your own todo list (e.g. TaskList): if the interrupted session was tracking a multi-step plan, check it first — it's the most direct record of what was left, more reliable than re-deriving it from conversation text alone.
- Background agents/tasks: don't trust status alone — a task shown as "running" may actually be orphaned and stalled forever if the session died mid-task. Check for real recent progress (e.g. TaskOutput/TaskGet), and check for tasks that finished but whose results were never read. If a task is stalled with no progress, treat it as dead: resume it with whatever partial work it left, or restart that piece of work.
- Background shell commands: any Bash/PowerShell command launched with run_in_background may still be running or may have finished unnoticed — check it (e.g. BashOutput) rather than re-running the same command.
- Uncommitted changes: check git status and any files left mid-edit so you don't overwrite unsaved work.

Then look back at the conversation to figure out what was in progress (the last task, plan, or tool call before the interruption) and continue from there. Do not ask the user to re-explain what they wanted — reconstruct it from context and proceed.