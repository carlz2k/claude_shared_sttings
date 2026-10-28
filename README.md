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
| `examples/settings.example.json` | Keys to merge into `~/.claude/settings.json`: `CLAUDE_CODE_SUBAGENT_MODEL=haiku`, default model, and the caveman and context-mode plugins. |
| `examples/zshrc-headroom.sh` | Shell snippet: route `claude` through the Headroom proxy and protect `Read` results from lossy compression. |
| `examples/CLAUDE.local.md.example` | Template for a per-project, untracked `CLAUDE.local.md` with the model-delegation rule. |
| `scripts/restart-headroom-proxy.sh` | Restart the shared Headroom proxy so a changed `HEADROOM_*` variable takes effect. Has `--dry-run`. |
| `scripts/verify.sh` | Checks that the setup below is active on this machine. Exit code is the number of failed checks. |

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

## Optimized stack (RTK, Headroom, context-mode, caveman)

Do these after the Install section, in order. `scripts/verify.sh` checks the result.

1. **Real ripgrep binary.** `brew install ripgrep` (or your package manager). Claude Code only defines `rg` as a shell function, so without a real binary on `PATH` the RTK hook rewrites `rg ...` to `rtk rg ...` and every call fails with `rtk: search failed: Failed to execute command: No such file or directory`. Plain `grep` is unaffected.
2. **RTK.** Install RTK, then run `rtk init -g`. It adds the Bash `PreToolUse` and `SessionStart` hooks. The hook fires only on Bash: the built-in `Read`, `Grep` and `Glob` tools bypass it.
3. **Headroom.** Install Headroom, add `examples/zshrc-headroom.sh` to `~/.zshrc`, and start a new shell. `HEADROOM_PROTECT_TOOL_RESULTS=Read` stops `Read` output being compressed into `[N words compressed to M ...]` with garbled headings. Headroom reads it only when the proxy starts, and `headroom wrap claude` reuses an already-running proxy, so after changing it run `scripts/restart-headroom-proxy.sh`. The restart drops the connection of every other session on that proxy for a few seconds.
4. **Settings.** Merge `examples/settings.example.json` into `~/.claude/settings.json`. Do not overwrite the file: it also holds your hooks and permissions. Then install the `caveman` and `context-mode` plugins through `/plugin`.
5. **Verify.** Run `scripts/verify.sh`. Then `Read` a file of 100+ lines and confirm there is no `words compressed` marker.

Notes:

- `CLAUDE_CODE_SUBAGENT_MODEL=haiku` makes any subagent call that omits `model` run on Haiku. The rule in `rules/tool-choice.md` therefore says to always pass `model` explicitly, and to use `sonnet` for analysis.
- With context-mode installed, `WebFetch` is hook-redirected to `ctx_fetch_and_index` plus `ctx_search`, and `ctx_search` is throttled. Batch questions into one `queries` array.
- Caveman is stated in `CLAUDE.md` and also injected by the plugin's hooks. This is redundant but harmless.
- `HEADROOM_PROTECT_TOOL_RESULTS` is not a live-syncable Headroom knob, so a proxy restart is the only way to apply it.
- Versions this was verified on: RTK 1.0.1, Headroom 0.41.0, Claude Code 2.1.312, ripgrep 15.2.0, macOS.

## Model choice

- Subagent model order: the per-call `model` parameter, then the agent's `model` frontmatter, then `CLAUDE_CODE_SUBAGENT_MODEL`, then the main conversation's model. Verified: a `general-purpose` subagent with `model` omitted ran on Haiku when `CLAUDE_CODE_SUBAGENT_MODEL=haiku` was set, and on Sonnet when `model: "sonnet"` was passed.
- Cheap, context-flooding work such as searches goes to Haiku through `Explore`. Single reads and small edits stay in the main session, because a subagent starts with a cold prompt cache.
- Avoid switching the main session model mid-task. Each model has its own prompt cache.

See the official docs: <https://code.claude.com/docs/en/sub-agents.md> and <https://code.claude.com/docs/en/costs.md>.

## Not included

Project-specific rules, settings and memory notes stay private.
