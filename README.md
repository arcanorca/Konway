# Konway

![Konway logo](assets/konway-logo.svg)

Konway is a KDE Plasma 6 live wallpaper plugin based on Conway's Game of Life.

It is QML + GLSL only, GPU-driven, and tuned for stable daily use.

Respect to John Horton Conway.

## Highlights

- GPU ping-pong simulation (Qt RHI shaders, no per-cell CPU loop each frame)
- Calm default look with built-in palette set:
  `Calm Dark, Paper Light, Emerald, Amber, Monochrome, Catppuccin, Dracula, Tokyo Night, Nord, Gruvbox, Everforest`
- Activity injector so simulation does not stall
- Optional clock overlay mode (`Off` / `Hybrid Local Time`)
- Mouse seeding: left click places a glider, left drag uses brush
- Full settings UI tabs:
  `General, Simulation, Patterns, Appearance, Performance, Safety`

## Important Simulation Note

`Startup seed intensity` is interpreted as a startup/reseed **coverage ratio**.

- `100%` means startup seed fills the entire simulation grid
- Higher coverage can enter overpopulation range and cause early mass extinction (expected Life behavior)
- UI warns this zone with red slider accent + warning text

Default behavior remains technically aligned with the previous balanced startup feel.

## Install

### KDE Store

`Desktop and Wallpaper` -> `Get New Plugins...` -> search `Konway`

### Local Deploy

Run from `life.wallpaper/`:

```bash
./tools/deploy_local.sh
```

If Plasma still shows stale QML/settings:

```bash
kquitapp6 plasmashell && kstart6 plasmashell
```

## Quick Controls

- `Cell size`: visual size of cells
- `Target TPS`: simulation speed (ticks per second)
- `Simulation downscale`: lower load by reducing simulation resolution (`1` is max detail)
- `Sync with TPS`: keeps internal driver timing aligned with TPS
- `Pause when Plasma is inactive`: optional power save behavior

## Build Shaders (`.qsb`)

From `life.wallpaper/`:

```bash
qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/shaders/life_step.frag.qsb contents/shaders/life_step.frag
qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/shaders/visualize.frag.qsb contents/shaders/visualize.frag
qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/shaders/population_probe.frag.qsb contents/shaders/population_probe.frag
```

or:

```bash
./tools/build_shaders.sh
```

## Pattern Packs

Built-in pattern data:

- `contents/patterns/rle/<category>/*.rle`
- `contents/patterns/index.json`
- `contents/patterns/patternData.js`

Rebuild index/data after RLE edits:

```bash
./tools/build_patterns_index.py
```

Optional external pack helper:

```bash
./tools/download_external_pack.sh /path/to/manifest.txt
```

## KPackage Build

Create install/upload archives:

```bash
./tools/build_kpackage.sh
```

Output:

- `dist/com.github.arcanorca.konway-<version>.kpackage.tar.gz`
- `dist/com.github.arcanorca.konway-<version>.kpackage.zip`

Local package install test:

```bash
kpackagetool6 --type Plasma/Wallpaper --install dist/com.github.arcanorca.konway-<version>.kpackage.tar.gz
```

## License

GPL-3.0-or-later
