import type { Plugin } from "@opencode/plugin/gui"
import { watchFile, unwatchFile } from "node:fs"
import { mkdir, readFile, rename, writeFile } from "node:fs/promises"
import { homedir } from "node:os"
import { dirname, join } from "node:path"
import { MascotSelection } from "./contract"

type MascotId = "empo" | "claude"

function normalizeCharacter(value: unknown): MascotId | undefined {
  const text = String(value ?? "").toLowerCase()
  if (text === "clawd" || text === "claude") return "claude"
  if (text === "empo") return "empo"
  return undefined
}

// Keep every `process` read inside main. The GUI bundle is evaluated in the
// window process too, where the global does not exist.
function configHome(): string {
  return process.env.XDG_CONFIG_HOME || join(process.env.HOME || homedir(), ".config")
}

async function readCurrentSelection(selectionFile: string, inirConfig: string): Promise<MascotId> {
  try {
    const data = JSON.parse(await readFile(selectionFile, "utf8")) as { character?: unknown }
    const selected = normalizeCharacter(data.character)
    if (selected) return selected
  } catch {
    // No shared selection yet.
  }

  try {
    const data = JSON.parse(await readFile(inirConfig, "utf8")) as {
      mascot?: { codingCompanion?: { character?: unknown } }
    }
    const selected = normalizeCharacter(data.mascot?.codingCompanion?.character)
    if (selected) return selected
  } catch {
    // iNiR is not installed, or its config is not readable.
  }

  return normalizeCharacter(process.env.MASCOT_CHARACTER) ?? "empo"
}

async function writeSelection(selectionFile: string, character: MascotId): Promise<void> {
  await mkdir(dirname(selectionFile), { recursive: true })
  const temp = `${selectionFile}.${process.pid}.tmp`
  await writeFile(temp, JSON.stringify({ character, updated: Date.now() }, null, 2) + "\n", "utf8")
  await rename(temp, selectionFile)
}

export const main: Plugin.MainSetup = async (ctx) => {
  const home = configHome()
  const selectionFile = join(home, "mascot-code", "character.json")
  const inirConfig = join(home, "inir", "config.json")
  let current = await readCurrentSelection(selectionFile, inirConfig)

  const provider = ctx.provide(MascotSelection, {
    state: () => ({ character: current }),
    set: async (value) => {
      current = normalizeCharacter(value) ?? "empo"
      await writeSelection(selectionFile, current)
      provider.changed()
      return current
    },
  })

  watchFile(selectionFile, { interval: 1000 }, async () => {
    const next = await readCurrentSelection(selectionFile, inirConfig)
    if (next === current) return
    current = next
    provider.changed()
  })

  return () => unwatchFile(selectionFile)
}
