# claude_shared_sttings

Generic Claude Code preferences and subagent definitions, shared so they can be restored on a new machine.

## Contents

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Global preferences: terse answers that lead with the result, with exact names, commands and code. Imports `RTK.md`. |
| `RTK.md` | Note that command output is condensed and how to recover a truncated result. |
| `agents/Explore.md` | Read-only codebase exploration on Haiku. Overrides the built-in `Explore`, which otherwise runs on Opus with a Claude subscription or Console account. |
| `agents/analyst.md` | Deep analysis and root-cause work. Proposes fixes and does not apply them unless asked. Inherits the main model. |
| `rules/tool-choice.md` | Global rule: read files once, re-read from disk when output is lossy-compressed, delegate to subagents only for context-flooding work. |
| `agents/researcher.md` | Read-only research that must ground every claim in code or commands it ran. Runs on Sonnet. |

## Install

Global preferences go in `~/.claude/`, rules in `~/.claude/rules/`, and subagents in `~/.claude/agents/`:

```sh
git clone https://github.com/carlz2k/claude_shared_sttings.git
cd claude_shared_sttings
cp CLAUDE.md RTK.md ~/.claude/
mkdir -p ~/.claude/agents
cp agents/*.md ~/.claude/agents/
mkdir -p ~/.claude/rules
cp rules/*.md ~/.claude/rules/
```

Back up any existing `~/.claude/CLAUDE.md` first, because `cp` overwrites it. `RTK.md` only makes sense if you use the RTK output filter. Otherwise delete the `@RTK.md` line from `CLAUDE.md`.

## Model choice

- Subagent model order: the per-call `model` parameter, then the agent's `model` frontmatter, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main conversation's model.
- Cheap, context-flooding work such as searches goes to Haiku through `Explore`. Single reads and small edits stay in the main session, because a subagent starts with a cold prompt cache.
- Avoid switching the main session model mid-task. Each model has its own prompt cache.

See the official docs: <https://code.claude.com/docs/en/sub-agents.md> and <https://code.claude.com/docs/en/costs.md>.

## Not included

Project-specific rules, settings and memory notes stay private.
