# agent-instructions
My personal agent prompt/skill/instruction library/collection for both GitHub Copilot and Claude Code.

## Install

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

**GitHub Copilot general instructions**: no plugin mechanism exists for always-on instructions on the Copilot side (see `instructions/general/bvandevliet-general.instructions.md`'s maintainer note), so it's a one-click install into your personal `~/.copilot/instructions/` instead. Filename is prefixed with my username since that folder can accumulate `.instructions.md` files from other sources too; a generic name like `general.instructions.md` would risk colliding with someone else's:

[![Install in VS Code](https://img.shields.io/badge/VS_Code-Install_general_instructions-0098FF?style=flat-square&logo=visualstudiocode&logoColor=white)](https://aka.ms/awesome-copilot/install/instructions?url=vscode%3Achat-instructions%2Finstall%3Furl%3Dhttps%3A%2F%2Fraw.githubusercontent.com%2Fbvandevliet%2Fagent-instructions%2Fmaster%2Finstructions%2Fgeneral%2Fbvandevliet-general.instructions.md)
[![Install in VS Code Insiders](https://img.shields.io/badge/VS_Code_Insiders-Install_general_instructions-24bfa5?style=flat-square&logo=visualstudiocode&logoColor=white)](https://aka.ms/awesome-copilot/install/instructions?url=vscode-insiders%3Achat-instructions%2Finstall%3Furl%3Dhttps%3A%2F%2Fraw.githubusercontent.com%2Fbvandevliet%2Fagent-instructions%2Fmaster%2Finstructions%2Fgeneral%2Fbvandevliet-general.instructions.md)
