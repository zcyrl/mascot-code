import { defineConfig } from "vite"
import { gui } from "@opencode/plugin/gui/vite"

export default defineConfig({
  plugins: [
    gui({
      entry: "src/gui.tsx",
      outFile: "../opencode/mascot/gui-experimental.cjs",
    }),
  ],
})
