[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

# Mechanically enforces the "before each phase of a multi-step workflow, check whether any
# available skill has become newly relevant" half of the "Eagerly Loading Skills" rule in
# general.instructions.md. That rule alone doesn't reliably survive a long, task-specific workflow
# (e.g. a multi-phase feature-dev skill) dominating the model's attention for many turns after the
# initial skill scan; confirmed directly: a full C#/.NET feature implementation ran through
# several feature-dev phases without ever loading a directly-on-point convention skill, despite
# that skill's own description saying "Use whenever writing, reviewing or modifying any C#/.NET
# code." A generic, content-agnostic nudge (rather than hard-blocking on any specific skill or file
# type) keeps this reusable across every task domain instead of only the one that prompted it.
#
# Fired from two hook events, registered separately in hooks.json against this same script:
#   - UserPromptSubmit: covers a "turn" from the human's side, once per submitted message.
#   - PostToolUse (matcher: TaskUpdate): covers a "phase/step" from the model's side, fired only
#     when a task transitions to in_progress, i.e. the model itself just declared it's starting
#     a new chunk of work. This is the harness's own built-in phase/step marker, so it's a much
#     lower-noise proxy than firing after every single tool call.
#
# Both events support hookSpecificOutput.additionalContext (unlike PreToolUse, which only supports
# a UI-only systemMessage that the model never sees), confirmed via the official hooks
# reference (https://code.claude.com/docs/en/hooks.md).
#
# Claude Code-only, opt-in rather than opt-out: see guard-em-dash.ps1 for the $env:CLAUDECODE
# rationale (same applies here verbatim).
if (-not $env:CLAUDECODE) {
    exit 0
}

$stdin = [Console]::In.ReadToEnd().TrimStart([char]0xFEFF)
try {
    $payload = $stdin | ConvertFrom-Json -ErrorAction Stop
} catch {
    exit 0
}

$eventName = $payload.hook_event_name
if ($eventName -ne 'UserPromptSubmit' -and $eventName -ne 'PostToolUse') {
    exit 0
}

# Reads the transcript into an array of lines, or $null if it doesn't exist yet / is unreadable
# (distinct from an empty-but-readable transcript, which is a real, meaningful "no prior lines"
# state; callers must be able to tell "couldn't check" apart from "checked, found nothing").
# The leading comma on the return is required: PowerShell unrolls an array written to the output
# stream into its bare element when writing a 1-element array (confirmed directly: a one-line
# transcript came back as a plain [string], and indexing that with [0] silently returned a
# [char] instead of throwing, corrupting every .Contains() call downstream). The comma operator
# wraps the array one level deeper so the unroll consumes that wrapper instead of the real array.
function Get-TranscriptLines($transcriptPath) {
    if ([string]::IsNullOrEmpty($transcriptPath) -or -not (Test-Path $transcriptPath)) {
        return $null
    }
    $lines = @(Get-Content -Path $transcriptPath -ErrorAction SilentlyContinue)
    return ,$lines
}

# Index of the most recent line in $lines that is a genuine submitted prompt rather than a
# tool-result relay; both are logged as top-level "type":"user" in the transcript, so the
# presence of a "tool_result" content block is what distinguishes a relay from a real prompt.
# Returns -1 if no such line exists.
function Find-LastPromptLineIndex($lines) {
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        if ($lines[$i].Contains('"type":"user"') -and -not $lines[$i].Contains('"tool_result"')) {
            return $i
        }
    }
    return -1
}

if ($eventName -eq 'UserPromptSubmit') {
    # Skip on the very first prompt of a session: SessionStart just injected the full
    # general.instructions.md content moments earlier (including this exact "Eagerly Loading
    # Skills" text verbatim), so reminding again here would be immediate duplication of something
    # still fresh. From the second prompt onward, enough could have happened since SessionStart
    # (or since the last reminder) that it's no longer redundant. If the transcript can't be read
    # at all, we can't tell whether this is the first prompt, so default to firing rather than
    # silently suppressing on uncertainty.
    $lines = Get-TranscriptLines $payload.transcript_path
    if ($null -ne $lines -and (Find-LastPromptLineIndex $lines) -eq -1) {
        exit 0
    }
}

if ($eventName -eq 'PostToolUse') {
    if ($payload.tool_name -ne 'TaskUpdate') {
        exit 0
    }

    # Only an actual pending/completed -> in_progress transition counts as a "phase/step
    # beginning", not every TaskUpdate call (subject/description edits, owner claims, etc.
    # aren't phase boundaries), and not a redundant call that just re-states an already-
    # in_progress status (no real transition happened, so nothing new is "beginning").
    # tool_response.statusChange only appears when status was actually among the fields that
    # changed (confirmed by direct inspection of a live PostToolUse payload for this tool), which
    # is a more precise signal than tool_input.status: the latter reflects what was requested, not
    # whether it actually changed anything.
    if ($payload.tool_response.statusChange.to -ne 'in_progress') {
        exit 0
    }

    # Skip if this TaskUpdate is (as far as the transcript shows) the first tool call since the
    # last real user prompt; that means it's essentially the model's first move in response to
    # the prompt, and the UserPromptSubmit branch above already reminded for this exact turn (or
    # skipped it, if this is also the first prompt of the session; either way, nothing new to
    # add here yet). Firing again here would just be immediate duplication. A TaskUpdate reached
    # only after other tool calls already happened this turn is a genuine deeper phase transition
    # and still fires. If the transcript can't be read, fall through and fire rather than
    # silently suppressing on uncertainty.
    $lines = Get-TranscriptLines $payload.transcript_path
    if ($null -ne $lines) {
        $lastPromptIndex = Find-LastPromptLineIndex $lines

        $toolCallsSincePrompt = 0
        for ($i = $lastPromptIndex + 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Contains('"type":"tool_use"')) {
                $toolCallsSincePrompt++
            }
        }

        if ($toolCallsSincePrompt -eq 0) {
            exit 0
        }
    }
}

$reason = 'Before continuing: reconsider whether any available skill has become newly relevant to this turn/phase, even partially. Multiple skills may apply; load all that haven''t already been loaded earlier in this session, rather than relying on general knowledge (see the "Eagerly Loading Skills" instruction).'

$output = @{
    hookSpecificOutput = @{
        hookEventName     = $eventName
        additionalContext = $reason
    }
}
$output | ConvertTo-Json -Depth 5 -Compress
exit 0
