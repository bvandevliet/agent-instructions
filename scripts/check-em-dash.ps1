# Mechanical enforcement of the "Never use em dashes" rule from
# plugins/soul/instructions/general.instructions.md, for contexts the PreToolUse hook
# (plugins/soul/hooks/guard-em-dash.ps1) can't reach: pre-commit and CI, where changes may not
# have gone through Claude Code at all (Copilot CLI has no working PreToolUse dispatch as of
# 2026-08-05, see CLAUDE.md), or through neither agent.
#
# Usage: check-em-dash.ps1 [-Files <path[]>]
#   -Files   Paths to check. Defaults to all git-tracked .md/.mdx/.txt files.

param(
    [string[]]$Files
)

[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

# Files that intentionally show the em dash character itself as a documentation example
# (the style guide's "don't do this" samples, and the rule's own self-reference) rather than
# using it as punctuation. Keep this list short and each entry justified; anything else with
# an em dash is a real violation.
$excludePaths = @(
    'plugins/documentation/skills/write-technical-docs/references/style-guide.md'
    'plugins/soul/instructions/general.instructions.md'
)

if (-not $Files) {
    $Files = git ls-files -- '*.md' '*.mdx' '*.txt'
}

$emDash = [char]0x2014
$violations = @()

foreach ($file in $Files) {
    if ([string]::IsNullOrWhiteSpace($file)) { continue }
    $normalized = $file -replace '\\', '/'
    if ($excludePaths -contains $normalized) { continue }
    if (-not (Test-Path $file)) { continue }

    $content = Get-Content -Raw -Encoding UTF8 -Path $file -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content) -or ($content -notmatch $emDash)) { continue }

    $lines = $content -split "\r?\n"
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        $col = $line.IndexOf($emDash)
        while ($col -ge 0) {
            $violations += [pscustomobject]@{
                File   = $normalized
                Line   = $i + 1
                Column = $col + 1
                Text   = $line
            }
            $col = $line.IndexOf($emDash, $col + 1)
        }
    }
}

if ($violations.Count -eq 0) {
    Write-Output "No em dashes found in checked files."
    exit 0
}

$inGitHubActions = $env:GITHUB_ACTIONS -eq 'true'
$noun = if ($violations.Count -eq 1) { 'em dash' } else { 'em dashes' }
$fileNoun = if (($violations.File | Select-Object -Unique).Count -eq 1) { 'file' } else { 'files' }
$fileCount = ($violations.File | Select-Object -Unique).Count

Write-Output "Found $($violations.Count) $noun in $fileCount $fileNoun."
Write-Output "---"

foreach ($v in $violations) {
    $reason = "Em dash (U+2014): rewrite using a colon, semicolon, or comma instead."
    if ($inGitHubActions) {
        Write-Output "::error file=$($v.File),line=$($v.Line),col=$($v.Column)::$reason"
    }
    Write-Output "$($v.File):$($v.Line):$($v.Column)"
}

exit 1
