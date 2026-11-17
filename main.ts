// THE GIANT — best-game-01 entry program (Node 22, standard library only).
//
// The game itself is the Godot HTML5 export under game/: index.html plus the
// engine (index.js, index.wasm, index.pck, the audio worklet), a WebAssembly
// build that runs offline from a plain static file server — no threads, so no
// special headers, and no network requests. This program hands it in: it
// copies game/ and screenshots/ from beside this file into the output
// directory and writes dossier.json with the make.fun library, which is the
// summary the judge reads.
//
// Run locally the way the kit says:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { cpSync, existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildDossier } from "./vendor/makefun-game.ts";

// The scorer's own caps, copied from the kit's gate.json. Only text_max_bytes
// shapes the dossier bytes; the rest refuse an entry the scorer would refuse
// (more than 4 screenshots or one over 256 KiB; game/ past 993 files or
// 48 MiB, or a path under game/ over 1000 bytes).
const CAPS = {
  text_max_bytes: 163840,
  screenshots: { max: 4, max_bytes: 262144 },
  game_max_files: 993,
  game_max_bytes: 50331648,
  game_path_max_bytes: 1000,
};

const root = fileURLToPath(new URL(".", import.meta.url));
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

function handIn(): void {
  mkdirSync(outDir, { recursive: true });
  cpSync(join(root, "game"), join(outDir, "game"), { recursive: true });
  const shots = join(root, "screenshots");
  mkdirSync(join(outDir, "screenshots"), { recursive: true });
  if (existsSync(shots)) {
    cpSync(shots, join(outDir, "screenshots"), { recursive: true });
  }
  writeFileSync(join(outDir, "dossier.json"), buildDossier(outDir, CAPS));
}

handIn();
