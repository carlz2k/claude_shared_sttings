# Tool choice

- Read a file once with `Read`. Do not call any retrieve tool to recover its content.
- Output containing "compressed ... hash=" is lossy and the hash may have expired: re-read from disk with `cat` or `Read` offset/limit.
- Use sandbox tools (`ctx_execute_file`, `ctx_batch_execute`) only for large files or multi-file scans.
- `WebFetch` is hook-redirected: use `ctx_fetch_and_index` then `ctx_search`. `ctx_search` is throttled (about 8 calls per window), so batch all questions into one `queries` array.
- Delegate to a subagent only for multi-file scans, log reads or broad greps. Always pass `model` explicitly on each call: `haiku` for lookup, `sonnet` for analysis (`opus` only when a wrong answer is costly). Never omit it: an omitted `model` falls back to `CLAUDE_CODE_SUBAGENT_MODEL=haiku` from settings.json.
