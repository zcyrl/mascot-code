// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Softbrick (zcyrl)
import { Plugin } from "@opencode/plugin"
import { basename } from "node:path"
import { existsSync, readFileSync, renameSync, unlinkSync, writeFileSync } from "node:fs"

const STATE_FILE = "/tmp/opencode-mascot.json"
const IDLE_MS = 60_000
const MAX_DETAIL = 30

type MascotState =
  | "idle"
  | "thinking"
  | "reading"
  | "coding"
  | "running"
  | "browsing"
  | "happy"
  | "sad"
  | "sleeping"

type SessionState = {
  state: MascotState
  detail: string
  ts: number
  lastAction?: string
}

const sessions = new Map<string, SessionState>()
let activeSessionID = ""
let sleepTimer: ReturnType<typeof setTimeout> | undefined

function truncate(value: unknown, max = MAX_DETAIL): string {
  const text = String(value ?? "").replace(/\s+/g, " ").trim()
  if (text.length === 0) return ""
  return text.length > max ? `${text.slice(0, max - 3).trimEnd()}...` : text
}

function actionText(state: MascotState, detail: string): string {
  const value = truncate(detail)
  switch (state) {
    case "reading":
      return value ? `reading ${value}` : "reading"
    case "coding":
      return value ? `coding ${value}` : "coding"
    case "running":
      return value ? `running ${value}` : "running"
    case "browsing":
      return value ? `browsing ${value}` : "browsing"
    default:
      return value
  }
}

function errorMessage(value: unknown): string {
  const error = value as { message?: string; type?: string; name?: string } | undefined
  return truncate(error?.message ?? error?.name ?? error?.type ?? "session error")
}

function writeState(sessionID: string, state: SessionState): number {
  const ts = state.ts
  const payload = JSON.stringify({
    state: state.state,
    detail: truncate(state.detail),
    ts,
    sessionID,
  }) + "\n"
  const temp = `${STATE_FILE}.${process.pid}.tmp`

  // Atomic replace: the QML side reads only complete JSON. The inotify watcher
  // in Quickshell watches /tmp for the rename, so no partial document is read.
  try {
    writeFileSync(temp, payload, "utf8")
    renameSync(temp, STATE_FILE)
  } catch (error) {
    try {
      unlinkSync(temp)
    } catch {
      // Best effort cleanup only.
    }
    console.error("[opencode-mascot] failed to write state:", error)
  }

  return ts
}

function scheduleSleep(sessionID: string, ts: number): void {
  if (sleepTimer) clearTimeout(sleepTimer)
  const wait = Math.max(0, IDLE_MS - (Date.now() - ts))
  sleepTimer = setTimeout(() => {
    if (activeSessionID !== sessionID) return
    const current = sessions.get(sessionID)
    if (!current || current.ts !== ts) return
    current.state = "sleeping"
    current.detail = "zZ"
    current.ts = Date.now()
    writeState(sessionID, current)
    console.log(`[opencode-mascot] sleeping ${sessionID}`)
  }, wait)
}

function emit(sessionID: string, state: MascotState, detail = ""): void {
  if (!sessionID) return
  const previous = sessions.get(sessionID)
  const entry: SessionState = {
    state,
    detail: truncate(detail),
    ts: Date.now(),
    lastAction: previous?.lastAction,
  }
  sessions.set(sessionID, entry)

  if (!activeSessionID) activeSessionID = sessionID
  if (sessionID !== activeSessionID) return

  writeState(sessionID, entry)
  scheduleSleep(sessionID, entry.ts)
  console.log(`[opencode-mascot] ${state}${detail ? `: ${truncate(detail)}` : ""} [${sessionID}]`)
}

function activate(sessionID: string): void {
  const id = String(sessionID ?? "")
  if (!id) return

  activeSessionID = id
  let entry = sessions.get(id)
  if (!entry) {
    entry = { state: "idle", detail: "waiting", ts: Date.now() }
    sessions.set(id, entry)
  }
  writeState(id, entry)
  scheduleSleep(id, entry.ts)
  console.log(`[opencode-mascot] active session: ${id}`)
}

function detailFor(tool: string, input: unknown): string {
  const value = (input ?? {}) as Record<string, unknown>

  if (tool === "bash" || tool === "shell")
    return truncate(value.command ?? value.cmd ?? "")
  if (tool === "webfetch" || tool === "websearch" || tool === "fetch")
    return truncate(value.url ?? value.query ?? "")
  if (tool === "grep" || tool === "glob")
    return truncate(value.pattern ?? value.path ?? "")

  const path = value.filePath ?? value.path ?? value.file ?? value.filename
  if (typeof path === "string" && path.length > 0) return truncate(basename(path))
  return truncate(tool)
}

function stateForTool(tool: string): MascotState {
  switch (tool) {
    case "read":
    case "glob":
    case "grep":
    case "list":
      return "reading"
    case "edit":
    case "write":
    case "patch":
    case "apply_patch":
    case "multiedit":
      return "coding"
    case "bash":
    case "shell":
      return "running"
    case "webfetch":
    case "websearch":
    case "fetch":
      return "browsing"
    default:
      return "thinking"
  }
}

export default Plugin.define({
  id: "opencode.mascot",
  async setup(ctx) {
    // Recover the active session on plugin hot-reload instead of showing
    // an unrelated idle state until the next prompt.
    if (existsSync(STATE_FILE)) {
      try {
        const previous = JSON.parse(readFileSync(STATE_FILE, "utf8")) as {
          sessionID?: string
          state?: MascotState
          detail?: string
          ts?: number
        }
        const id = String(previous?.sessionID ?? "")
        if (id && previous?.state) {
          activeSessionID = id
          sessions.set(id, {
            state: previous.state,
            detail: String(previous.detail ?? ""),
            ts: Number(previous.ts) || Date.now(),
          })
        }
      } catch {
        // A stale/malformed file is replaced by the first real event.
      }
    }

    // Plugin hot-reload can happen while a session is already open, and the
    // TUI does not replay tui.session.select for it. Ask the server for the
    // most recently active top-level session so hooks target the right one.
    try {
      const page = await ctx.session.list({ directory: ctx.location.directory, limit: 50 })
      const newest = (page.data ?? [])
        .filter((session) => !session.parentID)
        .sort((a, b) => (b.time?.updated ?? 0) - (a.time?.updated ?? 0))[0]
      if (newest) {
        const id = String(newest.id)
        if (!sessions.has(id))
          sessions.set(id, { state: "idle", detail: "waiting", ts: Date.now() })
        activeSessionID = id
      }
    } catch (error) {
      console.warn("[opencode-mascot] could not discover the active session:", error)
    }

    if (activeSessionID) activate(activeSessionID)

    await ctx.session.hook("prompt", (event) => {
      activate(String(event.sessionID ?? ""))
    })

    await ctx.tool.hook("execute.before", (event) => {
      const sessionID = String(event.sessionID ?? "")
      const tool = String(event.tool ?? "")
      const state = stateForTool(tool)
      const detail = detailFor(tool, event.input)
      const entry = sessions.get(sessionID)
      if (entry) entry.lastAction = actionText(state, detail)
      else sessions.set(sessionID, {
        state: "idle",
        detail: "",
        ts: Date.now(),
        lastAction: actionText(state, detail),
      })
      emit(sessionID, state, detail)
    })

    await ctx.tool.hook("execute.after", (event) => {
      const sessionID = String(event.sessionID ?? "")
      const lastAction = sessions.get(sessionID)?.lastAction ?? ""
      emit(sessionID, "thinking", lastAction ? `after ${lastAction}` : "thinking")
    })

    const controller = new AbortController()
    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({
          types: [
            "session.created",
            "session.viewed",
            "session.idle",
            "session.deleted",
            "session.execution.failed",
            "session.step.failed",
            "tui.session.select",
          ],
          signal: controller.signal,
        })) {
          const data = (event as { data?: Record<string, unknown> }).data ?? {}
          const sessionID = String(data.sessionID ?? "")

          switch (event.type) {
            case "session.created":
              if (sessionID) {
                if (!sessions.has(sessionID))
                  sessions.set(sessionID, { state: "idle", detail: "waiting", ts: Date.now() })
                if (!activeSessionID && !data.parentID) activate(sessionID)
              }
              break
            case "session.viewed":
            case "tui.session.select":
              activate(sessionID)
              break
            case "session.idle": {
              if (!sessionID) break
              const entry = sessions.get(sessionID)
              if (entry) entry.lastAction = ""
              emit(sessionID, "happy", "done")
              break
            }
            case "session.execution.failed":
            case "session.step.failed":
              emit(sessionID, "sad", errorMessage(data.error))
              break
            case "session.deleted":
              sessions.delete(sessionID)
              if (activeSessionID === sessionID) {
                activeSessionID = ""
                const newest = Array.from(sessions.entries())
                  .sort((a, b) => b[1].ts - a[1].ts)[0]
                if (newest) activate(newest[0])
              }
              break
          }
        }
      } catch (error) {
        if (!controller.signal.aborted)
          console.error("[opencode-mascot] event subscription failed:", error)
      }
    })()

    console.log("[opencode-mascot] plugin loaded")

    return () => {
      controller.abort()
      if (sleepTimer) clearTimeout(sleepTimer)
    }
  },
})
