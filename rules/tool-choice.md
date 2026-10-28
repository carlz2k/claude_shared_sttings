# Tool choice

- Read a file once with `Read`. Do not call any retrieve tool to recover its content.
- Output containing "compressed ... hash=" is lossy and the hash may have expired: re-read from disk with `cat` or `Read` offset/limit.
- Use sandbox tools (`ctx_execute_file`, `ctx_batch_execute`) only for large files or multi-file scans.
- Delegate to a subagent only for multi-file scans, log reads or broad greps. Pass `model` explicitly on each call: `haiku` for lookup, the default model for analysis.
