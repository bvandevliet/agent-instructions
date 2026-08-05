[Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

# Enforces the "Never use em dashes" rule from general.instructions.md mechanically, since the
# instruction alone doesn't reliably survive quick/conversational generation. Scoped to prose file
# types (.md/.mdx/.txt) rather than every Write/Edit/NotebookEdit call: the rule targets writing
# style, and blanket-checking source files would false-positive on legitimate em dashes in string
# literals, fixtures, or third-party quoted text.
#
# Claude Code-only, opt-in rather than opt-out: only proceed once the environment positively
# identifies Claude Code via $env:CLAUDECODE (the flag Claude Code sets on every process it
# spawns, including hooks). An opt-out list would need every non-Claude host enumerated in
# advance to stay safe; this fails closed by default against anything unverified, including
# hosts that don't exist yet. Confirmed by direct testing (2026-08-05, Copilot CLI 1.0.78) that
# Copilot CLI never invokes plugin PreToolUse hooks at all -- not a tool-name mismatch (its
# file-write tools are named "create"/"edit", not "Write"/"Edit") but the event itself goes
# unfired even when the matcher is widened to those names or the event key is renamed to
# Copilot's internal "preToolsExecution" processor name -- and that it doesn't set CLAUDECODE
# itself (unlike CLAUDE_PLUGIN_ROOT/CLAUDE_PLUGIN_DATA, which it deliberately mirrors onto its
# own value for compatibility, since its hooks.json commands reference ${CLAUDE_PLUGIN_ROOT}).
if (-not $env:CLAUDECODE) {
    exit 0
}

# Built from a code point rather than a literal character: this file has no BOM, and Windows
# PowerShell 5.1 (unlike pwsh) falls back to the system codepage for BOM-less scripts, which
# garbles a literal em dash in source and breaks parsing entirely.
$emDash = [char]0x2014

$stdin = [Console]::In.ReadToEnd().TrimStart([char]0xFEFF)
try {
    $payload = $stdin | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

$toolName = $payload.tool_name
$filePath = switch ($toolName) {
    'Write'        { $payload.tool_input.file_path }
    'Edit'         { $payload.tool_input.file_path }
    'NotebookEdit' { $payload.tool_input.notebook_path }
    default        { $null }
}
if ([string]::IsNullOrEmpty($filePath)) {
    exit 0
}

if ($toolName -eq 'NotebookEdit') {
    # notebook_path is always .ipynb, never .md/.mdx/.txt, so the extension check below can
    # never apply here: markdown-ness lives at the cell level, not the file level. cell_type is
    # only required by the tool schema for edit_mode=insert; for replace/delete it "defaults to
    # the current cell type" when omitted, so a plain replace edit often won't state it at all.
    # In that case the only way to know is to read the notebook and look up the existing cell.
    if ($payload.tool_input.edit_mode -eq 'delete') {
        exit 0
    }
    $cellType = $payload.tool_input.cell_type
    if ([string]::IsNullOrEmpty($cellType)) {
        try {
            $notebook = Get-Content -Raw -Encoding UTF8 -Path $filePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $cellId = $payload.tool_input.cell_id
            $cell = $notebook.cells | Where-Object { $_.id -eq $cellId } | Select-Object -First 1
            $cellType = $cell.cell_type
        } catch {
            exit 0
        }
    }
    if ($cellType -ne 'markdown') {
        exit 0
    }
} elseif ($filePath -notmatch '\.(md|mdx|txt)$') {
    exit 0
}

$content = switch ($toolName) {
    'Write'        { $payload.tool_input.content }
    'Edit'         { $payload.tool_input.new_string }
    'NotebookEdit' { $payload.tool_input.new_source }
    default        { $null }
}
if ([string]::IsNullOrEmpty($content) -or ($content -notmatch $emDash)) {
    exit 0
}

$lines = $content -split "\r?\n"
$hits = @()
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    $col = $line.IndexOf($emDash)
    while ($col -ge 0) {
        $hits += "line $($i + 1), col $($col + 1): `"$($line.Trim())`""
        $col = $line.IndexOf($emDash, $col + 1)
    }
}

$occurrenceNoun = if ($hits.Count -eq 1) { 'occurrence' } else { 'occurrences' }
$pronoun = if ($hits.Count -eq 1) { 'it' } else { 'them' }
$locations = $hits -join "; "
$reason = "Blocked by the 'soul' plugin's Language/Writing rule: 'Never use em dashes ($emDash): use a colon, semicolon, or comma instead, whichever the sentence's grammar calls for.' (general.instructions.md). Found $($hits.Count) $occurrenceNoun; fix $pronoun before retrying: $locations"

$output = @{
    hookSpecificOutput = @{
        hookEventName            = 'PreToolUse'
        permissionDecision       = 'deny'
        permissionDecisionReason = $reason
    }
}
$output | ConvertTo-Json -Depth 5 -Compress
exit 0
