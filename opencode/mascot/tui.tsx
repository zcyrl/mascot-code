/** @jsxImportSource @opentui/solid */
// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Softbrick (zcyrl)
import { Plugin } from "@opencode/plugin/tui"
import type { Context } from "@opencode/plugin/tui/context"
import { RGBA } from "@opentui/core"
import { createEffect, createSignal, For, onCleanup } from "solid-js"
import { homedir } from "node:os"
import { join } from "node:path"
import { mkdir, readFile, writeFile } from "node:fs/promises"
import {
    MASCOT_FRAMES,
    MASCOT_STATES,
    MASCOTS,
    type MascotId,
    type MascotInfo,
} from "./art"

const CONFIG_HOME = process.env.XDG_CONFIG_HOME || join(process.env.HOME || homedir(), ".config")
const SELECTION_FILE = join(CONFIG_HOME, "mascot-code", "character.json")
const INIR_CONFIG = join(CONFIG_HOME, "inir", "config.json")
const TRANSPARENT = RGBA.fromInts(0, 0, 0, 0)
const FRAME_MS = 1400

function normalizeCharacter(value: unknown): MascotId | undefined {
    const text = String(value ?? "").toLowerCase()
    if (text === "clawd" || text === "claude") return "claude"
    if (text === "empo") return "empo"
    return undefined
}

async function readCurrentSelection(): Promise<MascotId> {
    try {
        const data = JSON.parse(await readFile(SELECTION_FILE, "utf8")) as { character?: unknown }
        const selected = normalizeCharacter(data.character)
        if (selected) return selected
    } catch {
        // No shared selection yet.
    }

    try {
        const data = JSON.parse(await readFile(INIR_CONFIG, "utf8")) as {
            mascot?: { codingCompanion?: { character?: unknown } }
        }
        const selected = normalizeCharacter(data.mascot?.codingCompanion?.character)
        if (selected) return selected
    } catch {
        // iNiR is not installed, or its config is not readable.
    }

    return normalizeCharacter(process.env.MASCOT_CHARACTER) ?? "empo"
}

async function writeSelection(character: MascotId): Promise<void> {
    await mkdir(join(CONFIG_HOME, "mascot-code"), { recursive: true })
    await writeFile(
        SELECTION_FILE,
        JSON.stringify({ character, updated: Date.now() }, null, 2) + "\n",
        "utf8",
    )
}

function MascotCard(props: {
    context: Context
    mascot: MascotInfo
    active: boolean
    selected: boolean
    frame: number
    onHover: () => void
    onLeave: () => void
    onPick: () => void
}) {
    const theme = props.context.theme
    const accent = props.mascot.accent
    const state = () => MASCOT_STATES[props.frame % MASCOT_STATES.length]

    return (
        <box
            width={30}
            flexDirection="column"
            alignItems="center"
            border
            borderStyle={props.selected ? "rounded" : "single"}
            borderColor={props.selected ? accent : theme.text.muted}
            backgroundColor={props.selected ? theme.background.raised.high : TRANSPARENT}
            paddingLeft={1}
            paddingRight={1}
            paddingTop={1}
            paddingBottom={1}
        >
            <image
                source={MASCOT_FRAMES[props.mascot.id][state()]}
                width={26}
                height={13}
                onMouseOver={props.onHover}
                onMouseOut={props.onLeave}
                onMouseUp={props.onPick}
            />
            <text fg={props.selected ? accent : theme.text.base} marginTop={1}>
                <b>{props.mascot.name}</b>
            </text>
            <text fg={theme.text.muted} selectable={false}>
                {state()}
            </text>
            <text fg={theme.text.muted} selectable={false}>
                {props.mascot.tagline}
            </text>
            <text fg={props.active ? accent : theme.text.muted} selectable={false}>
                {props.active ? "active" : props.selected ? "enter to choose" : "click to choose"}
            </text>
        </box>
    )
}

function MascotPicker(props: { context: Context; initial: MascotId }) {
    const context = props.context
    const theme = context.theme
    const accent = theme.hue.accent[500] ?? theme.text.base
    let closed = false

    const [panel, setPanel] = createSignal<any>(undefined)
    const [selected, setSelected] = createSignal<MascotId>(props.initial)
    const [hovered, setHovered] = createSignal<MascotId | null>(null)
    const [frames, setFrames] = createSignal<Record<MascotId, number>>({ empo: 0, claude: 0 })
    const [saving, setSaving] = createSignal(false)

    function close() {
        if (closed) return
        closed = true
        context.ui.dialog.clear()
    }

    async function pick(character: MascotId) {
        if (saving()) return
        setSaving(true)
        try {
            await writeSelection(character)
            const info = MASCOTS.find((item) => item.id === character)
            context.ui.toast.show({
                variant: "success",
                title: "Mascot selected",
                message: `${info?.name ?? character} is now the coding companion.`,
                duration: 3500,
            })
            close()
        } catch (error) {
            setSaving(false)
            context.ui.toast.show({
                variant: "error",
                title: "Could not select mascot",
                message: `${SELECTION_FILE}: ${error instanceof Error ? error.message : String(error)}`,
                duration: 6000,
            })
        }
    }

    function move(delta: number) {
        const index = MASCOTS.findIndex((item) => item.id === selected())
        const next = MASCOTS[(index + delta + MASCOTS.length) % MASCOTS.length]
        if (next) setSelected(next.id)
    }

    function hover(character: MascotId) {
        setSelected(character)
        setHovered(character)
        setFrames((current) => ({ ...current, [character]: 0 }))
    }

    createEffect(() => {
        const character = hovered()
        if (!character) return
        const timer = setInterval(() => {
            setFrames((current) => ({
                ...current,
                [character]: (current[character] + 1) % MASCOT_STATES.length,
            }))
        }, FRAME_MS)
        onCleanup(() => clearInterval(timer))
    })

    context.keymap.layer(() => ({
        target: () => panel(),
        priority: 20,
        commands: [
            {
                bind: "left",
                title: "Previous mascot",
                group: "Mascot Code",
                run: () => move(-1),
            },
            {
                bind: "right",
                title: "Next mascot",
                group: "Mascot Code",
                run: () => move(1),
            },
            {
                bind: "return",
                title: "Choose mascot",
                group: "Mascot Code",
                run: () => {
                    void pick(selected())
                },
            },
            {
                bind: "space",
                title: "Choose mascot",
                group: "Mascot Code",
                run: () => {
                    void pick(selected())
                },
            },
            {
                bind: "escape",
                title: "Close mascot picker",
                group: "Mascot Code",
                run: close,
            },
        ],
    }))

    return (
        <box
            ref={(element: any) => {
                setPanel(element)
                element.focusable = true
                setTimeout(() => {
                    if (panel() === element) element.focus()
                }, 50)
            }}
            width={68}
            flexDirection="column"
            border
            borderStyle="rounded"
            borderColor={theme.text.muted}
            backgroundColor={theme.background.raised.high}
            paddingLeft={2}
            paddingRight={2}
            paddingTop={1}
            paddingBottom={1}
            onMouseDown={() => panel()?.focus()}
        >
            <box flexDirection="row" justifyContent="space-between">
                <text fg={theme.text.base}>
                    <b>Choose your mascot</b>
                </text>
                <text fg={theme.text.muted} selectable={false}>
                    esc
                </text>
            </box>
            <text fg={theme.text.muted} selectable={false}>
                Hover the art to preview every expression. Click a mascot to choose it.
            </text>
            <box flexDirection="row" marginTop={1}>
                <For each={MASCOTS}>
                    {(mascot, index) => (
                        <box marginRight={index() === MASCOTS.length - 1 ? 0 : 2}>
                            <MascotCard
                                context={context}
                                mascot={mascot}
                                active={props.initial === mascot.id}
                                selected={selected() === mascot.id}
                                frame={frames()[mascot.id]}
                                onHover={() => hover(mascot.id)}
                                onLeave={() => {
                                    if (hovered() === mascot.id) setHovered(null)
                                }}
                                onPick={() => {
                                    void pick(mascot.id)
                                }}
                            />
                        </box>
                    )}
                </For>
            </box>
            <text fg={theme.text.muted} selectable={false} marginTop={1}>
                current: {props.initial} · ←/→ select · enter choose
            </text>
        </box>
    )
}

export default Plugin.define({
    id: "zcyrl.mascot",
    async setup(context) {
        let lastOpened = 0

        const openPicker = async () => {
            const now = Date.now()
            if (now - lastOpened < 300) return
            lastOpened = now
            const initial = await readCurrentSelection()
            context.ui.dialog.show(
                () => <MascotPicker context={context} initial={initial} />,
                () => {},
            )
            context.ui.dialog.set({ size: "large", centered: true })
        }

        context.keymap.layer(() => ({
            mode: "global",
            commands: [
                {
                    id: "zcyrl.mascot.choose",
                    title: "Choose mascot",
                    description: "Preview Empo and Claude, then pick one",
                    group: "Mascot Code",
                    palette: true,
                    slash: { name: "mascot" },
                    run: () => {
                        void openPicker()
                    },
                },
            ],
        }))

        // The typed command also works when the slash completion is dismissed:
        // it never reaches the model.
        context.keymap.layer(() => ({
            priority: 2,
            commands: [
                {
                    bind: "return",
                    title: "Choose mascot",
                    group: "Mascot Code",
                    run: () => {
                        const editor = context.renderer.currentFocusedEditor
                        const text = editor?.plainText.trim() ?? ""
                        if (!editor || text !== "/mascot") return false
                        editor.clear()
                        void openPicker()
                    },
                },
            ],
        }))
    },
})
