[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

$contentPath = Join-Path $PSScriptRoot '..\instructions\general\CLAUDE.md'
$content = Get-Content -Raw -Encoding UTF8 -Path $contentPath

# Strip maintainer HTML comments — mirrors Claude Code's own CLAUDE.md handling,
# so notes meant for humans don't spend tokens on the model.
$content = ($content -replace '(?s)<!--.*?-->', '').TrimStart()

$output = @{
  hookSpecificOutput = @{
    hookEventName     = 'SessionStart'
    additionalContext = $content
  }
}

$output | ConvertTo-Json -Depth 5 -Compress