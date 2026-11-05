# States

The state file is `/tmp/opencode-mascot.json`.

```json
{
  "state": "reading",
  "detail": "main.py",
  "ts": 1793869420662,
  "sessionID": "ses_e584..."
}
```

If `ts` is missing, the overlay treats the write as "just now". If `ts` is older
than 60 seconds, the overlay shows `sleeping` even if the state still says
`coding`. This is the crash fallback.

## Mapping

| State | Empo | Bubble |
| --- | --- | --- |
| `idle` | blinking, gentle bob | hidden |
| `thinking` | looks up, floating `?` | `thinking...` or `thinking after reading main.py` |
| `reading` | wide eyes, scanning page | `reading main.py` |
| `coding` | looks down, tiny keyboard | `coding test.py` |
| `running` | tilted, speed lines, bounce | `running pytest -q` |
| `browsing` | rotating globe ring | `browsing docs.opencode.ai` |
| `happy` | jump, closed happy eyes, sparkles | `done!` |
| `sad` | droop, tear, frown | `error: ...` |
| `sleeping` | closed eyes, `zZ`, glow dimmed | hidden |

## Tool mapping

| Tool | State |
| --- | --- |
| `read`, `glob`, `grep`, `list` | `reading` |
| `edit`, `write`, `patch`, `apply_patch`, `multiedit` | `coding` |
| `bash`, `shell` | `running` |
| `webfetch`, `websearch`, `fetch` | `browsing` |
| anything else | `thinking` |
| `tool.execute.after` | `thinking` |
| `session.created` | `idle` |
| `session.idle` | `happy` |
| `session.execution.failed`, `session.step.failed` | `sad` |
| 60s with no event | `sleeping` |

## Manual test

```bash
echo '{"state":"coding","detail":"test.py"}' > /tmp/opencode-mascot.json
```

Or use the helper:

```bash
./scripts/test-states.sh coding "test.py"
./scripts/test-states.sh reading "main.py"
./scripts/test-states.sh sad "tool failed"
```

Watch it:

```bash
watch -n 0.5 cat /tmp/opencode-mascot.json
```
