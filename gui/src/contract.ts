import { Schema } from "effect"
import { Ipc } from "@opencode/plugin/gui"

export const MascotSelection = Ipc.define({
  id: "zcyrl.mascot.selection",
  state: Schema.Struct({ character: Schema.String }),
  methods: {
    set: {
      input: Schema.String,
      output: Schema.String,
    },
  },
})
