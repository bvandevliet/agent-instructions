# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal instruction/skill library distributed as **two separate, self-hosted plugins from the same repo** — one for Claude Code, one for GitHub Copilot CLI. There's no build, lint, or test suite; it's markdown content plus a handful of plugin manifests and one PowerShell script. `source: "./"` in both marketplaces means the plugin root *is* the repo root.

Note there are two files named `CLAUDE.md` in this repo, with unrelated purposes: **this one** (repo root) is meta — guidance for editing the library itself. `instructions/general/CLAUDE.md` is *content* — the general instructions this library ships to consumers of the plugin. Don't confuse edits to one for the other.

```
.claude-plugin/{plugin.json, marketplace.json}   # Claude Code plugin + its marketplace
.github/plugin/{plugin.json, marketplace.json}   # Copilot CLI plugin + its marketplace
hooks/hooks.json + scripts/claude-general-instructions.ps1   # Claude-only delivery mechanism, see below
instructions/general/{CLAUDE.md, bvandevliet-general.instructions.md}   # hand-tailored per tool, not synced
skills/{dotnet-conventions, recover}/SKILL.md    # shared by both plugins' "skills" field
```

## The constraint that shapes everything here

Neither Claude Code nor GitHub Copilot's plugin system has a component for "always-on instructions." Both only support `skills`/`agents`/`hooks`/`mcpServers` (Claude Code adds `lspServers`); a plugin cannot ship a loadable `CLAUDE.md`, and there's no `rules` field either (tracked, unshipped: `anthropics/claude-code#21163`). Every design choice below exists to work around that gap, asymmetrically per tool:

- **Claude Code** gets `instructions/general/CLAUDE.md` injected every session via `hooks/hooks.json`'s `SessionStart` hook, which shells out to `scripts/claude-general-instructions.ps1`. That script reads the file, strips the maintainer HTML comment, and emits `{"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": ...}}`.
- **GitHub Copilot** has no equivalent plugin mechanism at all. `instructions/general/bvandevliet-general.instructions.md` only reaches a session via manual copy or the README's one-click VS Code install badge (`vscode:chat-instructions/install?url=...`), landing in `~/.copilot/instructions/` or a project's `.github/instructions/`.

Because of this, **`CLAUDE.md` and `bvandevliet-general.instructions.md` are deliberately not kept identical** — no import/symlink links them, and they shouldn't be re-merged. Each is hand-tailored to what its tool already does natively (e.g. `CLAUDE.md` skips telling Claude to "read CLAUDE.md files" since it auto-loads those; the Copilot file has its own commit-attribution bullet referencing `git.addAICoAuthor` / `Co-authored-by: Copilot`, since Claude's and Copilot's actual attribution mechanisms differ). When editing one for a substantive rule change, decide deliberately whether the other needs the same change in tool-appropriate language — don't diff-and-copy.

Conditionally-scoped content (currently just `.NET` conventions) is the one thing that *doesn't* need this per-tool split: it lives solely as `skills/dotnet-conventions/SKILL.md`, referenced by both plugins' `skills` field, because Agent Skills (the `SKILL.md` standard) auto-invoke based on relevance on Claude Code, Copilot CLI, and Copilot's VS Code agent mode alike.

## Non-obvious structural gotchas

- **`.github/plugin/plugin.json` is nested**, not a bare root-level `plugin.json`. This matches the convention in the real `github/awesome-copilot` marketplace (verified directly against it, not just the docs) for a plugin whose root coincides with its marketplace's root.
- **`version` is duplicated** in each `plugin.json` and its corresponding `marketplace.json` entry, by convention — keep them in sync by hand. Claude Code documents that `plugin.json` wins if they differ; Copilot CLI documents no such precedence, so don't let them drift there.
- Any `.instructions.md` meant to land in a shared personal folder (`~/.copilot/instructions/`) gets a `bvandevliet-` prefix (hyphenated, matching the kebab-case convention observed across `github/awesome-copilot`'s own instructions files) — that folder can accumulate files from unrelated sources, so a generic name like `general.instructions.md` risks colliding.

## Editing `scripts/claude-general-instructions.ps1`

This script has failed silently twice in ways that only surfaced when tested through an actual redirected stdout (not an in-memory PowerShell pipeline capture, which hides both bugs):

1. `Get-Content` **must** use `-Encoding UTF8`. The source file is BOM-less UTF-8; Windows PowerShell 5.1's default encoding detection misreads it, turning em-dashes into mojibake (`â€”`).
2. `[Console]::OutputEncoding` **must** be set to UTF8 before any output is written. Without it, a piped/redirected stdout (exactly how Claude Code captures a hook's output) silently downgrades non-ASCII characters — e.g. em-dash becomes a plain hyphen — with no error at all.

To test a change, don't just capture `$out = & powershell ...` in-memory — redirect to a real file and inspect the raw bytes, since that's what actually exposes both issues:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\claude-general-instructions.ps1 > out.json
Get-Content out.json | ConvertFrom-Json   # sanity-check the JSON shape
# then check raw bytes for the UTF-8 em-dash sequence (E2 80 94) rather than trusting a terminal's rendering
```

## Validating config changes

No formal lint step; validate JSON manually after editing any manifest:

```bash
python3 -c "import json; json.load(open('hooks/hooks.json'))"
```

To test either plugin end-to-end from a local checkout before pushing:

```
/plugin marketplace add <local-path>              # Claude Code
copilot plugin marketplace add <local-path>        # Copilot CLI
```
