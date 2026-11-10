import { createEffect, createSignal, For, onCleanup, onMount } from "solid-js"
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
}) {
  const [hovered, setHovered] = createSignal<MascotId | null>(null)
  const [selected, setSelected] = createSignal<MascotId>(props.current())
  const [frames, setFrames] = createSignal<Record<MascotId, number>>({ empo: 0, claude: 0 })
  const [saving, setSaving] = createSignal(false)
  const cards: Partial<Record<MascotId, HTMLButtonElement>> = {}

  function startPreview(character: MascotId) {
    setSelected(character)
    setHovered(character)
    setFrames((current) => ({ ...current, [character]: 0 }))
  }

  function stopPreview(character: MascotId) {
    if (hovered() === character) setHovered(null)
  }

  function move(delta: number) {
    const index = MASCOTS.findIndex((mascot) => mascot.id === selected())
    const next = MASCOTS[(index + delta + MASCOTS.length) % MASCOTS.length]
    if (!next) return
    setSelected(next.id)
    startPreview(next.id)
    cards[next.id]?.focus()
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

  function handleKeyDown(event: KeyboardEvent) {
    if (event.ctrlKey || event.metaKey || event.altKey) return
    if (event.key === "ArrowLeft") {
      event.preventDefault()
      event.stopPropagation()
      move(-1)
    } else if (event.key === "ArrowRight") {
      event.preventDefault()
      event.stopPropagation()
      move(1)
    } else if (event.key === "Enter") {
      event.preventDefault()
      event.stopPropagation()
      void choose(selected())
    }
  }

  onMount(() => {
    // Capture at the window so the host's global navigation cannot steal the
    // arrow keys or close the dialog before the cards see them.
    window.addEventListener("keydown", handleKeyDown, true)
    const focus = () => cards[props.current()]?.focus()
    requestAnimationFrame(focus)
    const retry = setTimeout(focus, 120)
    onCleanup(() => {
      clearTimeout(retry)
      window.removeEventListener("keydown", handleKeyDown, true)
    })
  })

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
    <div
      class="mascot-code-picker"
      onKeyDown={(event) => {
        if (event.key === "ArrowLeft") {
          event.preventDefault()
          move(-1)
        } else if (event.key === "ArrowRight") {
          event.preventDefault()
          move(1)
        }
      }}
    >
      <p class="mascot-code-hint">
        Hover to preview all nine expressions. Use ← → and Enter, or click a card.
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
                ref={(element) => {
                  cards[mascot.id] = element
                }}
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
    </div>
  )
}
