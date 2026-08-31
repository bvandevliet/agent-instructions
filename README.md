# agent-instructions
Bob Vandevliet's library/collection of agent engineering instructions and skills.

## Install

Powershell 7+ is required for the plugin hooks to work. Make sure it's installed and available in your PATH.

**Claude Code**: install the plugin; general instructions and skills load automatically every session:

```
/plugin marketplace add bvandevliet/agent-instructions
/plugin install agent-instructions
```

**GitHub Copilot CLI**: install the plugin for skills (conditionally loaded, e.g. `dotnet-conventions`):

```
copilot plugin marketplace add bvandevliet/agent-instructions
copilot plugin install agent-instructions
```