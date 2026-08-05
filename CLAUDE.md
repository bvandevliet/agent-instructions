# CLAUDE.md

## Structure

Multi-plugin layout: one marketplace at root `.claude-plugin/marketplace.json`, each plugin self-contained under `plugins/<name>/.claude-plugin/plugin.json`. No `.github/plugin/`: that duplicate-manifest approach was dropped, since `.claude-plugin/` alone is discovered by both Claude Code (natively) and Copilot CLI/VS Code Agent Plugins (as a documented fallback location).

Each plugin's skills/hooks/instructions must live *inside* that plugin's own directory tree. Installation only copies a plugin's declared root subtree.

## Validating config changes

To test either plugin end-to-end from a local checkout before pushing:

```
/plugin marketplace add <local-path>              # Claude Code
copilot plugin marketplace add <local-path>        # Copilot CLI
```

To verify what Copilot CLI *actually* resolves at runtime (not just what docs claim): `copilot plugin marketplace add .`, `copilot plugin install <plugin>@<marketplace-name>`, then re-run with `--log-level debug --log-dir <dir>` and grep the log for `hook stdout` / `Executing hook`. Inspect `~/.copilot/installed-plugins/<marketplace>/<plugin>/` to see exactly what got copied. Clean up with `copilot plugin marketplace remove <name> --force`.

Schema gotcha: Copilot's plugin.json requires `mcpServers`/`lspServers` as an object (Claude's schema also allows array); omit these fields entirely when unused rather than `[]`/`{}`.

Copilot CLI sets Claude-compatible env vars (`CLAUDE_PLUGIN_ROOT`, `CLAUDE_PLUGIN_DATA`) alongside its own when spawning plugin hooks, undocumented but confirmed by direct testing: this is why a single Claude-format `hooks.json` works for both tools without a Copilot-specific twin.

Confirmed by direct testing (2026-08-05, Copilot CLI 1.0.78, latest per `copilot update`): only `SessionStart` hooks actually fire. GitHub's own docs (docs.github.com/en/copilot/reference/hooks-reference) describe a `preToolUse`/`PreToolUse` event with Claude-format matcher support, a documented Claude-tool-name mapping, and multiple config sources treated as equivalent (plugin `hooks.json`, `.github/hooks/*.json`, `~/.copilot/hooks/`, inline `settings.json`); none of that is implemented in this build. Tested and ruled out: plugin-provided `PreToolUse` with the documented matcher, plugin-provided `PreToolUse` widened to Copilot's real tool names (`create`, `edit`), and a from-scratch `.github/hooks/*.json` file using the exact camelCase native schema from the docs with an unconditional `"permissionDecision":"deny"` (i.e. not a matcher or tool-name problem: the hard-coded deny never even ran). `--log-level all` shows zero mentions of `preToolUse`/`PreToolUse` or the `.github/hooks` file anywhere: the event isn't being discovered, let alone dispatched. The CLI's own built-in help (`copilot help <topic>`) has no `hooks` topic at all. Treat GitHub's hooks-reference docs for `preToolUse` as aspirational/not-yet-shipped-to-this-channel until re-verified against a newer build; don't trust matcher or config-location changes to fix it without first confirming the event fires at all. Re-run this same test on any future CLI upgrade to check if it's landed. Unrecognized event keys are silently skipped either way (no error, plugin still installs and loads fine), so a shared `hooks.json` is still safe to ship, but any `PreToolUse`-based enforcement (e.g. `plugins/soul/hooks/guard-em-dash.ps1`) is Claude Code-only for now.

For hooks that fire under both tools but need to branch on vendor, prefer an opt-in check for Claude Code (`$env:CLAUDECODE`) over an opt-out check for Copilot (`$env:COPILOT_CLI`): opt-out requires enumerating every non-Claude host in advance to stay safe, opt-in fails closed by default against anything unverified, including hosts that don't exist yet. Don't use `CLAUDE_PLUGIN_ROOT`/`CLAUDE_PLUGIN_DATA` to detect Claude Code specifically: Copilot CLI deliberately mirrors those onto its own value for compatibility, since its `hooks.json` commands reference `${CLAUDE_PLUGIN_ROOT}` too. `CLAUDECODE` has no such reason to be spoofed (no functional need, no `COPILOT_CODE` counterpart observed) and is the more reliable positive signal for "this is genuinely Claude Code," though this couldn't be verified against a fully standalone Copilot CLI process, only inferred: every Copilot CLI invocation tested here was itself spawned as a subprocess of a live Claude Code session (via the Bash tool), which inherits `CLAUDECODE` from that parent regardless of what Copilot sets, so its presence in that one test dump is explainable by ordinary process inheritance rather than Copilot setting it itself. Re-verify with a truly standalone Copilot CLI session (no Claude Code parent process) before fully trusting this in a security-sensitive context.