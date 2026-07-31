# CLAUDE.md

## Structure

Multi-plugin layout: one marketplace at root `.claude-plugin/marketplace.json`, each plugin self-contained under `plugins/<name>/.claude-plugin/plugin.json`. No `.github/plugin/` — that duplicate-manifest approach was dropped; `.claude-plugin/` alone is discovered by both Claude Code (natively) and Copilot CLI/VS Code Agent Plugins (as a documented fallback location).

Each plugin's skills/hooks/instructions must live *inside* that plugin's own directory tree. Installation only copies a plugin's declared root subtree.

## Validating config changes

To test either plugin end-to-end from a local checkout before pushing:

```
/plugin marketplace add <local-path>              # Claude Code
copilot plugin marketplace add <local-path>        # Copilot CLI
```

To verify what Copilot CLI *actually* resolves at runtime (not just what docs claim): `copilot plugin marketplace add .`, `copilot plugin install <plugin>@<marketplace-name>`, then re-run with `--log-level debug --log-dir <dir>` and grep the log for `hook stdout` / `Executing hook`. Inspect `~/.copilot/installed-plugins/<marketplace>/<plugin>/` to see exactly what got copied. Clean up with `copilot plugin marketplace remove <name> --force`.

Schema gotcha: Copilot's plugin.json requires `mcpServers`/`lspServers` as an object (Claude's schema also allows array) — omit these fields entirely when unused rather than `[]`/`{}`.

Copilot CLI sets Claude-compatible env vars (`CLAUDE_PLUGIN_ROOT`, `CLAUDE_PLUGIN_DATA`) alongside its own when spawning plugin hooks, undocumented but confirmed by direct testing — this is why a single Claude-format `hooks.json` works for both tools without a Copilot-specific twin.