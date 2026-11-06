import { createEffect, createSignal, For, onCleanup } from "solid-js"
import {
  MASCOT_FRAMES,
  MASCOT_STATES,
  MASCOTS,
  type MascotId,
} from "../../opencode/mascot/art"

const FRAME_MS = 1400

export function MascotPicker(props: {
  current: () => MascotId
  onPick: (character: MascotId) => void | Promise<void>
  onClose: () => void
}) {
  const [hovered, setHovered] = createSignal<MascotId | null>(null)
  const [frames, setFrames] = createSignal<Record<MascotId, number>>({ empo: 0, clawd: 0 })
  const [saving, setSaving] = createSignal(false)

  function startPreview(character: MascotId) {
    setHovered(character)
    setFrames((current) => ({ ...current, [character]: 0 }))
  }

  function stopPreview(character: MascotId) {
    if (hovered() === character) setHovered(null)
  }

  async function choose(character: MascotId) {
    if (saving()) return
    setSaving(true)
    try {
      await props.onPick(character)
    } finally {
      setSaving(false)
    }
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

  return (
    <div class="mascot-code-picker">
      <p class="mascot-code-hint">
        Hover a mascot to preview all nine expressions. Click one to make it the coding companion.
      </p>
      <div class="mascot-code-grid">
        <For each={MASCOTS}>
          {(mascot) => {
            const state = () => MASCOT_STATES[frames()[mascot.id] % MASCOT_STATES.length]
            const active = () => props.current() === mascot.id
            return (
              <button
                type="button"
                class="mascot-code-card"
                style={{ "--mascot-accent": mascot.accent } as Record<string, string>}
                aria-pressed={active()}
                aria-label={`Choose ${mascot.name}`}
                autofocus={active()}
                onMouseEnter={() => startPreview(mascot.id)}
                onMouseLeave={() => stopPreview(mascot.id)}
                onFocus={() => startPreview(mascot.id)}
                onBlur={() => stopPreview(mascot.id)}
                onClick={() => void choose(mascot.id)}
                disabled={saving()}
              >
                <img
                  class="mascot-code-image"
                  src={MASCOT_FRAMES[mascot.id][state()]}
                  alt={`${mascot.name} ${state()}`}
                  draggable={false}
                />
                <span class="mascot-code-name">
                  <span class="mascot-code-dot" />
                  {mascot.name}
                </span>
                <span class="mascot-code-state">{state()}</span>
                <span class="mascot-code-tagline">{mascot.tagline}</span>
                <span class={active() ? "mascot-code-badge active" : "mascot-code-badge"}>
                  {active() ? "Active mascot" : "Click to choose"}
                </span>
              </button>
            )
          }}
        </For>
      </div>
      <div class="mascot-code-foot">
        <span>Current: {props.current()}</span>
        <button type="button" class="mascot-code-close" onClick={props.onClose}>
          Close
        </button>
      </div>
    </div>
  )
}
