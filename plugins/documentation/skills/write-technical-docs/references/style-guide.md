# Tone and Style Guide

Rules for voice, tone, grammar, and anti-patterns in technical end-user documentation.

---

## Voice

Use **mixed voice** based on section type:

| Section type | Voice | Example |
|---|---|---|
| Procedures, steps, instructions | **Imperative** (no subject) | "Run the migration script." |
| Conceptual, overview, rationale | **Third person** | "The service validates the token before routing the request." |
| Configuration reference, tables | **Third person / noun phrases** | "Specifies the timeout in milliseconds." |

**Never** use first person ("we", "our") in documentation. It implies a relationship that may not apply to all readers, and ages poorly when teams change.

---

## Tone

**Professional and direct.** Every sentence earns its place. Cut filler; state the fact.

- Say what the system does, not what you hope it does.
- Don't editorialize: no praise, no apology.
- One idea per sentence; one purpose per paragraph

---

## Tense

**Present tense** for all system behavior:

| Wrong (future) | Right (present) |
|---|---|
| "The service will return a 200 response." | "The service returns a 200 response." |
| "This will configure the timeout." | "This configures the timeout." |

Exception: roadmap or planned behavior. Future tense is acceptable there, but mark it explicitly:
> **Planned (v3.0):** The service will support batch endpoints.

---

## Oxford Comma

**Always use it.**

> "The endpoint accepts JSON, XML, and form data." ✓  
> "The endpoint accepts JSON, XML and form data." ✗

---

## Em Dashes

**Never use em dashes (—).** Replace with whatever construction the sentence actually needs: a colon to introduce an elaboration, a semicolon to join two independent clauses, or a comma (pair) for a parenthetical aside. Don't default to a colon or semicolon everywhere just to avoid the dash; pick the one that fits the grammar.

> "The service caches responses — this reduces latency." ✗  
> "The service caches responses; this reduces latency." ✓
>
> "Set the timeout carefully — a value that's too low causes false failures." ✗  
> "Set the timeout carefully: a value that's too low causes false failures." ✓

---

## Full Stops

**Complete sentences end with a period; fragments do not.** A bullet is a complete sentence if it has (or implies) a subject and a verb. This includes a `**Label**: elaboration` bullet, which implies "is" or "means" and takes a period. Checklist criteria and parallel noun-phrase lists with no elaboration are fragments and stay bare.

> "Run the migration script before restarting the service." ✓ (complete sentence)  
> "**Prerequisites**: what the reader needs before starting." ✓ (label bullet, implies "is"; takes a period)  
> "Config keys, file paths, commands" ✓ (fragment, no verb; no period)

---

## Heading Capitalization

**Title Case** for all headings at every level.

> "Configure the Service" ✓  
> "Configure the service" ✗  
> "CONFIGURE THE SERVICE" ✗

Prepositions and articles (of, the, a, in, to, for) are lowercase unless they start the heading.

---

## Numbers

**Spell out one through nine; use digits for 10 and above.**

> "Set the value to 3 retries." ✗  
> "Set the value to three retries." ✓  
> "Set the value to 15 retries." ✓

Exception: always use digits for: version numbers, measurements with units, config values, percentages, and code/command contexts.

> "Requires 3 GB of memory." ✓ (measurement)  
> "Set `MaxRetries` to `3`." ✓ (config value in code context)

When a number opens a sentence, rewrite to avoid it rather than spelling it out.

> "3 endpoints are affected." → "The affected endpoints number 3." or restructure.

---

## Jargon and Acronyms

- In **TL;DR, Overview, and Summary sections**: spell out every acronym and technical term on first use; add a plain-English gloss for non-obvious concepts.
- In **technical sections** (procedures, config reference, troubleshooting): abbreviate freely after first use per document.

First-use pattern:
> "The API Gateway uses mutual TLS (mTLS) for service-to-service authentication."

Do **not** re-expand the same acronym after it has been introduced in the same document.

---

## Anti-Patterns

### Weasel Words

Words that soften a claim without adding information. **Banned.**

| Banned | Replacement |
|---|---|
| "simply", "just", "easily" | Remove entirely: the step either is or isn't described |
| "obviously", "clearly", "of course" | Remove: if it's obvious, don't say it |
| "basically", "essentially" | Remove or restate precisely |
| "straightforward" | Remove: if it were, you wouldn't need to document it |

**BAD:** "Simply run the migration script to update the schema."  
**GOOD:** "Run the migration script to update the schema."

### Passive Voice in Procedures

Procedures must use imperative voice. Passive constructions hide the actor and make steps ambiguous.

**BAD:** "The file is created in the output directory."  
**GOOD:** "The command creates `output/result.json` in the output directory." or "Create the file in the output directory."

Passive is acceptable in conceptual/rationale prose when the actor is genuinely unknown or irrelevant:
> "Requests are load-balanced across the available nodes."

### Marketing Language

**Banned.** Documentation is not advertising.

| Banned | Replacement |
|---|---|
| "powerful", "robust", "flexible" | Describe the specific capability instead |
| "seamless", "frictionless" | Describe what the integration actually does |
| "world-class", "best-in-class" | Remove: unverifiable and irrelevant |
| "innovative", "cutting-edge" | Remove |
| "easy to use" | Remove: show it by making the steps clear |

**BAD:** "Our powerful authentication system provides seamless, secure access."  
**GOOD:** "The authentication service issues JWTs with a 15-minute TTL and supports refresh token rotation."

### Unearned Modal Hedges

Modal verbs that introduce unwarranted uncertainty about deterministic behavior. **Banned.**

| Banned pattern | Replacement |
|---|---|
| "should work" | "works", or document the condition under which it does not |
| "might fail" | "fails when [condition]": state the condition exactly |
| "could trigger" | "triggers when [condition]" or "may trigger [condition]" only if genuinely non-deterministic |
| "probably" | Remove: state what you know; escalate what you don't |
| "seems to" | Remove: verify and state definitively |

**BAD:** "This configuration should prevent the timeout errors."  
**GOOD:** "This configuration prevents timeout errors when the upstream latency is under 500 ms."

Acceptable hedges (genuinely non-deterministic or environment-dependent):
- "may": acceptable for behavior that is conditionally non-deterministic.
- "depending on [specific condition]": acceptable when condition is named.

---

## Sentence and Paragraph Patterns

### One Sentence, One Claim

Don't stack clauses. Break compound sentences into shorter, serial ones.

**BAD:** "The service reads the config on startup and if the config is missing it will fall back to defaults, which might not be correct for production."  
**GOOD:** "The service reads `appsettings.json` on startup. If the file is missing, the service falls back to built-in defaults. Review the defaults before deploying to production. See [Configuration Reference](#configuration-reference)."

### Lead with the Action or the Subject

Don't bury the key fact at the end.

**BAD:** "In order to avoid connection pool exhaustion, set `MaxConnections` to a value appropriate for your load."  
**GOOD:** "Set `MaxConnections` to limit connection pool growth under high load."

### Avoid Filler Openers

**Banned openers:**
- "In order to..."  → "To..."
- "Please note that..."  → State the note directly
- "It is important to..."  → Use a `> **Important**` callout if it's genuinely important
- "As mentioned above..."  → Use a cross-link or restate
- "Note that..."  → Use a `> **Note**` callout if needed, or just state the fact inline

---

## Code and Literal Values

- Use backtick inline code for: config keys, file paths, commands, env vars, flags, class/method names, UI labels.
- Use fenced code blocks with explicit language hints for all multi-line examples.
- Quote literal values exactly as they appear in the system; never paraphrase a command or config value.
- Placeholders in commands use `<angle-brackets>`: `kubectl get pods -n <namespace>`

---

## Quick Checklist

Before finalizing, scan for:

- [ ] No weasel words ("simply", "just", "easily", "obviously")
- [ ] No passive voice in procedure steps
- [ ] No marketing language ("powerful", "seamless", "world-class")
- [ ] No unearned hedges ("should work", "might fail", "probably")
- [ ] All procedure steps use imperative voice
- [ ] All conceptual sections use third person
- [ ] Present tense throughout (except explicitly marked future roadmap items)
- [ ] Oxford comma in all lists with 3+ items
- [ ] All headings in Title Case
- [ ] All numbers: one through nine spelled out, 10+ as digits (digits always for measurements, versions, config values)
- [ ] All acronyms spelled out in TL;DR / Overview on first use
- [ ] No em dashes (—); replaced with a colon, semicolon, or comma pair as the grammar requires
