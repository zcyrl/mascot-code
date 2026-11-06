# States

Both characters read the same state file: `/tmp/opencode-mascot.json`.

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

| State | Empo | Clawd | Bubble |
| --- | --- | --- | --- |
| `idle` | blinking, gentle bob | blinking, little body bob | hidden |
| `thinking` | looks up, floating `?` | eyes up, floating `?` | `thinking...` or `thinking after reading main.py` |
| `reading` | wide eyes, scanning page | holds a page, scans it with his eyes | `reading main.py` |
| `coding` | looks down, tiny keyboard | leans onto a pixel keyboard | `coding test.py` |
| `running` | tilted, speed lines, bounce | scuttles, legs swinging, speed lines | `running pytest -q` |
| `browsing` | rotating globe ring | a little browser window with a globe icon | `browsing docs.opencode.ai` |
| `happy` | jump, closed happy eyes, sparkles | jump, arched eyes, sparkles | `done!` |
| `sad` | droop, tear, frown | droops, squints, a tear | `error: ...` |
| `sleeping` | closed eyes, `zZ`, glow dimmed | closed eyes, `zZ`, settled down | hidden |

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
