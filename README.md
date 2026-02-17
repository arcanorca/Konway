# Konway

Konway is a lightweight and highly customizable live wallpaper plugin for KDE Plasma 6 built around Conway's Game of Life.

It is fully open source, QML + GLSL only, and focused on simple, stable day-to-day use.

Respect to John Horton Conway for that made all of this possible.

## What You Get

- GPU-driven Life simulation (ping-pong textures, Qt RHI shaders)
- Calm default visuals for long sessions
- Randomized pattern injector so the world stays lively (can be disabled)
- Optional local-time clock mode
- Mouse seeding (click for glider, drag for brush)
- Practical settings tabs (General, Simulation, Patterns, Appearance, Performance, Safety)
- Contains several popular themes in Apperance tab such as "Paper Light, Emerald, Amber, Monochrome, Catppuccin, Dracula, Tokyo Night, Nord, Gruvbox, Everforest"

## Install

### KDE Store

Install **Konway** from `Desktop and Wallpaper` -> `Get New Plugins...` -> search `Konway`

### Manual Local Install

From this repo root (`life.wallpaper/`):

```bash
./tools/deploy_local.sh
```

If Plasma still shows old UI text/settings, restart shell:

```bash
plasmashell --replace & disown
```

## Quick Settings Guide

- `Cell size`: visual pixel size of cells.
- `Target TPS`: simulation speed (ticks per second).
- `Simulation downscale`: simulation detail level. `1` is max detail, `2` is usually enough.
- `Sync with TPS`: recommended default. Internal driver timing follows TPS automatically.
- `Clock mode`: `Off` or `Hybrid Local Time`. Clock size control is active only when clock mode is on.

## Stability and Safety Notes

- Simulation runs on GPU which is quite easy to run for even old PCs; no per-cell CPU loop per frame, this makes it one of the most efficient live wallpaper plugin.
- Downscale has a safety guard: if grid density becomes too heavy, Konway auto-raises effective downscale to avoid freezes.
- In Safety tab you can enable visual safety limits and reduce ticks per second even more.
- `Pause when Plasma is inactive` is available in Performance tab.

## Build Shaders (`.qsb`)

Run from `life.wallpaper/`:

```bash
qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/shaders/life_step.frag.qsb contents/shaders/life_step.frag
qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/shaders/visualize.frag.qsb contents/shaders/visualize.frag
qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/shaders/population_probe.frag.qsb contents/shaders/population_probe.frag
```

Or:

```bash
./tools/build_shaders.sh
```

## Pattern Packs

Built-in patterns are under:

- `contents/patterns/rle/<category>/*.rle`
- `contents/patterns/index.json`
- `contents/patterns/patternData.js`

After adding/editing `.rle` files, rebuild pattern metadata:

```bash
./tools/build_patterns_index.py
```

Optional external import helper:

```bash
./tools/download_external_pack.sh /path/to/manifest.txt
```

Manifest format:

- `pattern_name category`
- `pattern_name category sha256`

The importer validates name/category, blocks path traversal, and verifies hash when provided.

## KDE Store / KPackage Build

Konway is already a Plasma wallpaper KPackage layout (`metadata.json` + `contents/`).

To produce upload/install archives:

```bash
./tools/build_kpackage.sh
```

Output files are written to `dist/`:

- `com.github.arcanorca.konway-<version>.kpackage.tar.gz`
- `com.github.arcanorca.konway-<version>.kpackage.zip`

Local install test:

```bash
kpackagetool6 --type Plasma/Wallpaper --install dist/com.github.arcanorca.konway-<version>.kpackage.tar.gz
```

## Main Files

- `metadata.json`: plugin metadata and ID
- `contents/ui/main.qml`: runtime logic
- `contents/config/main.xml`: config schema
- `contents/ui/config*.qml`: settings pages
- `contents/shaders/*.frag`: shader sources
- `tools/`: build, deploy, packaging, and pattern scripts

## License

GPL-3.0-or-later.
