# Konway

<p align="center">
  <img src="assets/konway-logo.svg" alt="Konway logo" width="220">
</p>

Konway is a lightweight and highly customizable live wallpaper plugin for KDE Plasma 6 built around Conway's Game of Life.

[demo.webm](https://github.com/user-attachments/assets/09198183-d5c2-430a-a4b2-1fdf05154a2e)


## [Settings GUI]

<p align="center">
  Konway offers a robust settings interface to tweak every aspect of the simulation.
</p>

<table align="center">
  <tr>
    <td align="center" width="33%">
      <img src="assets/screenshots/settings-model.png" alt="Model Selection" width="100%">
      <br><b>🧬 Models</b><br>Choose between Conway, HighLife, Day & Night, etc.
    </td>
    <td align="center" width="33%">
      <img src="assets/screenshots/settings-colors.png" alt="Color Customization" width="100%">
      <br><b>🎨 Aesthetics</b><br>Full control over cell/background colors and decay trails.
    </td>
    <td align="center" width="33%">
      <img src="assets/screenshots/settings-grid.png" alt="Grid Settings" width="100%">
      <br><b>📐 Grid & Gap</b><br>Adjust cell size and gaps for pixel-perfect looks.
    </td>
  </tr>
  <tr>
    <td align="center" width="33%">
      <img src="assets/screenshots/settings-interaction.png" alt="Interaction" width="100%">
      <br><b>🖱️ Interaction</b><br>Paint life with your mouse or create barriers.
    </td>
    <td align="center" width="33%">
      <img src="assets/screenshots/settings-behavior.png" alt="Behavior" width="100%">
      <br><b>⚡ Performance</b><br>Cap FPS and simulation speed to save battery.
    </td>
    <td align="center" width="33%">
      <h3>🚀<br>Runs on GPU</h3>
    </td>
  </tr>
</table>


## // HIGHLIGHTS
- The simulation runs on the GPU, so even older PCs handle it well. There’s no per-cell CPU loop each frame, making Konway one of the most efficient live wallpaper plugins.
- Calm default look with built-in palette set:
  `Calm Dark, Paper Light, Emerald, Amber, Monochrome, Catppuccin, Dracula, Tokyo Night, Nord, Gruvbox, Everforest, Rose Pine`
- Activity injector so simulation does not stall
- Optional resizable digital clock overlay mode (`Off` / `Hybrid Local Time`)
- Mouse seeding: left click places a glider, left drag uses brush
- Full settings UI tabs:
  `General, Simulation, Patterns, Appearance, Performance, Safety`
  
## // HOW IT WORKS

### 1) GPU Simulation
- The simulation is stored in a texture (alive/dead cells).
- Every tick, a shader reads the previous state and writes the next state (ping-pong / feedback).
- No per-cell CPU loop each frame — the CPU mostly just schedules ticks.

### 2) Staying Alive (Pattern Injection)
Classic Life often settles into still lifes or emptiness.  
Konway can keep the world lively by **stamping curated patterns** (ships, oscillators, methuselahs, etc.) when activity drops.

- Fully configurable (thresholds, interval, pattern categories)
- Can be disabled for “pure” Life

### 3) Calm Rendering (Long-session friendly)
Life can flicker (oscillators, rapid changes).
- Subtle trails / persistence (reduces harsh blinking)
- Eye-friendly palettes and brightness limits (Safety tab)


## // INSTALL

### KDE Store

`Desktop and Wallpaper` -> `Get New Plugins...` -> search `Konway`

### Local Deploy

Run from `life.wallpaper/`:

```bash
./tools/deploy_local.sh
```

If Plasma still shows stale QML/settings:

```bash
plasmashell --replace & disown
```

## // Quick Settings Guide

- `Cell size`: visual size of cells
- `Target TPS`: simulation speed (ticks per second)
- `Sync with TPS`: keeps internal driver timing aligned with TPS
- `Pause when Plasma is inactive`: optional power save behavior

## // Build Shaders (`.qsb`)

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

## // Pattern Packs

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

## // KPackage Build

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

## // License
GPL-3.0-or-later

## // Stack
KDE Plasma 6 • Qt 6 (QML/JS) • GLSL (.qsb via Qt RHI) • kpackagetool6

*Dedicated to the memory of John Horton Conway.*
