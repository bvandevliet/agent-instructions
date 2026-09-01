[Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

# Enforces the "Never use em dashes" rule from general.instructions.md mechanically, since the
# instruction alone doesn't reliably survive quick/conversational generation. Scoped to prose file
# types (.md/.mdx/.txt) rather than every file-write call: the rule targets writing style, and
# blanket-checking source files would false-positive on legitimate em dashes in string literals,
# fixtures, or third-party quoted text.
#
# Deliberately NOT gated on tool_name (no "Write|Edit|NotebookEdit" matcher, no per-tool-name
# switch): live-tested against Claude Code, Copilot CLI 1.0.78, and VS Code Copilot Chat
# (2026-08-25), each of which reports a DIFFERENT native tool name for a file write (Claude:
# "Write"/"Edit"; Copilot CLI's PreToolUse remaps its own bash/powershell/create/edit tools to
# "Bash"/"Write"/"Edit" for Claude-schema compatibility; VS Code's are "createFile"/"editFiles",
# unremapped). A fixed matcher or tool-name list silently misses whichever host wasn't tested
# against yet, and the plugin's own hooks.json matcher field was confirmed live to be the exact
# reason this hook never fired on Copilot CLI or VS Code before this fix: hooks.json's PreToolUse
# entry filtered on "Write|Edit|NotebookEdit" (Claude Code's tool names only), so on the other two
# hosts the hook process was never even spawned, while matcher-less events in the same file
# (SessionStart, UserPromptSubmit) fired fine on all three. Instead, this script tries every known
# field-name spelling for "the file path" and "the new content" across all three hosts' schemas,
# and treats "none of them present" as "not a file-write call" and exits quietly, so unknown
# future tool shapes fail safe (silently skipped) rather than failing to enforce the rule.
$emDash = [char]0x2014

$stdin = [Console]::In.ReadToEnd().TrimStart([char]0xFEFF)
try {
    $payload = $stdin | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

$toolInput = $payload.tool_input
if ($null -eq $toolInput) {
    exit 0
}

# NotebookEdit: Claude Code-only tool (no observed Copilot CLI/VS Code Copilot Chat equivalent).
if ($payload.tool_name -eq 'NotebookEdit') {
    $filePath = $toolInput.notebook_path
    if ([string]::IsNullOrEmpty($filePath)) {
        exit 0
    }
    # notebook_path is always .ipynb, never .md/.mdx/.txt, so the extension check below can
    # never apply here: markdown-ness lives at the cell level, not the file level. cell_type is
    # only required by the tool schema for edit_mode=insert; for replace/delete it "defaults to
    # the current cell type" when omitted, so a plain replace edit often won't state it at all.
    # In that case the only way to know is to read the notebook and look up the existing cell.
    if ($toolInput.edit_mode -eq 'delete') {
        exit 0
    }
    $cellType = $toolInput.cell_type
    if ([string]::IsNullOrEmpty($cellType)) {
        try {
            $notebook = Get-Content -Raw -Encoding UTF8 -Path $filePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $cell = $notebook.cells | Where-Object { $_.id -eq $toolInput.cell_id } | Select-Object -First 1
            $cellType = $cell.cell_type
        } catch {
            exit 0
        }
    }
    if ($cellType -ne 'markdown') {
        exit 0
    }
    $content = $toolInput.new_source
} else {
    # File path field name: Claude Code uses file_path; Copilot CLI's Claude-schema remap and
    # VS Code Copilot Chat's native createFile/editFiles tools both use path.
    $filePath = $toolInput.file_path
    if ([string]::IsNullOrEmpty($filePath)) {
        $filePath = $toolInput.path
    }
    if ([string]::IsNullOrEmpty($filePath) -or $filePath -notmatch '\.(md|mdx|txt)$') {
        exit 0
    }

    # New-content field name: Claude Write=content, Claude Edit=new_string, Copilot CLI's
    # remapped Write=file_text, Copilot CLI's remapped Edit=new_str.
    $content = $toolInput.content
    if ($null -eq $content) { $content = $toolInput.new_string }
    if ($null -eq $content) { $content = $toolInput.file_text }
    if ($null -eq $content) { $content = $toolInput.new_str }
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
# Double-quoted (not single-quoted): must interpolate $emDash/$hits/etc, otherwise the agent sees
# the literal PowerShell variable syntax instead of the actual violating text and locations.
$reason = "Blocked by general instructions section ""## Language/Writing Rules"": Never use em dashes ($emDash): use a colon, semicolon, or comma instead, whichever the sentence's grammar calls for. Found $($hits.Count) $occurrenceNoun; fix $pronoun before retrying: $locations"

$output = @{
    hookSpecificOutput = @{
        hookEventName            = 'PreToolUse'
        permissionDecision       = 'deny'
        permissionDecisionReason = $reason
    }
}
$output | ConvertTo-Json -Depth 5 -Compress
exit 0
