import { Command, Plugin, Style } from "@opencode/plugin/gui"
import { MascotSelection } from "./contract"
import { main } from "./main"
import { MascotPicker } from "./picker"
import type { MascotId } from "../../opencode/mascot/art"
import css from "./styles.css?inline"

function normalizeCharacter(value: unknown): MascotId {
  const text = String(value ?? "").toLowerCase()
  if (text === "clawd" || text === "claude") return "clawd"
  return "empo"
}

export default Plugin.define({
  i18n: {
    en: {
      "command.choose": "Choose mascot",
      "command.description": "Preview Empo and Claude, then pick one",
      "dialog.title": "Choose your mascot",
      "dialog.description": "Each card cycles its expressions while you hover.",
      "dialog.close": "Close",
      "toast.selected": "Mascot selected",
      "toast.failed": "Could not select mascot",
    },
  },
  setup(ctx) {
    const ui = ctx.ui
    const ipc = ctx.main(MascotSelection)

    ctx.add(Style, css)

    const current = () => normalizeCharacter(ipc.state()?.character)

    ctx.add(
      Command,
      (): Command => ({
        id: "choose",
        title: ctx.t("command.choose"),
        description: ctx.t("command.description"),
        group: "Mascot Code",
        slash: { name: "mascot" },
        featured: true,
        run: () => {
          ctx.dialogs.open(
            (dialog) => (
              <ui.Dialog
                title={ctx.t("dialog.title")}
                description={ctx.t("dialog.description")}
                size="large"
                footer={
                  <ui.Button variant="contrast" onClick={dialog.close}>
                    {ctx.t("dialog.close")}
                  </ui.Button>
                }
              >
                <MascotPicker
                  current={current}
                  onPick={async (character) => {
                    try {
                      await ipc.set(character, { signal: ctx.signal })
                      const name = character === "clawd" ? "Claude" : "Empo"
                      ctx.toast.show({
                        variant: "success",
                        title: ctx.t("toast.selected"),
                        description: `${name} is now the coding companion.`,
                      })
                      dialog.close()
                    } catch (error) {
                      ctx.toast.show({
                        variant: "error",
                        title: ctx.t("toast.failed"),
                        description: error instanceof Error ? error.message : String(error),
                      })
                    }
                  }}
                />
              </ui.Dialog>
            ),
            { replace: true },
          )
        },
      }),
    )
  },
  main,
})
