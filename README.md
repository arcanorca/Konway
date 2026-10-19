# Konway

<p align="center">
  <img src="assets/konway-logo.svg" alt="Konway logo" width="220">
</p>

A lightweight Conway's Game of Life live wallpaper for KDE Plasma 6. The simulation runs on the GPU.

[demo.webm](https://github.com/user-attachments/assets/09198183-d5c2-430a-a4b2-1fdf05154a2e)

## Settings

<p align="center">
  <img src="assets/settings_general.png" width="32%" />
  <img src="assets/settings_simulation.png" width="32%" />
  <img src="assets/settings_activity.png" width="32%" />
  <br>
  <img src="assets/settings_appearance.png" width="32%" />
  <img src="assets/settings_zen.png" width="32%" />
  <img src="assets/settings_performance.png" width="32%" />
  <br>
  <img src="assets/settings_safety.png" width="32%" />
</p>

## Features

- **GPU simulation:** no per-cell CPU loop, so it stays light even on older machines.
- **Adaptive auto-injection:** the wallpaper watches which parts of the screen have gone quiet and adds gliders, growth seeds and small soups there, so it never settles into a few static blinkers. A Liveliness slider sets how busy it stays. The old timer-based injector is still available as Classic, and injection can be turned off.
- **Zen mode:** slow breathing tempo, soft trails, gentle injections and an optional evening dim.
- **Profiles:** Zen, Balanced, Lively.
- **48 palettes:** Catppuccin, Dracula, Nord, Gruvbox, Tokyo Night, Rose Pine, Kanagawa, Game Boy, Commodore 64 and more, plus custom colors.
- **Clock overlay:** 24-hour or 12-hour with optional AM/PM. Keeps ticking while paused (can be turned off).
- **Any B/S rule:** Life (`B3/S23`), HighLife (`B36/S23`), Day & Night (`B3678/S34678`), Seeds (`B2/S`) and others.
- **Mouse:** click places a glider, drag paints cells.
- **Comfort options:** fading trails, contrast and saturation limits, speed limiter.

## Install

**KDE Store:** Desktop and Wallpaper → Get New Plugins → search `Konway`.

**From source:**

```bash
git clone https://github.com/arcanorca/Konway.git
cd Konway
./tools/deploy_local.sh
```

**From a package:**

```bash
kpackagetool6 --type Plasma/Wallpaper --upgrade dist/com.github.arcanorca.konway-<version>.kpackage.tar.gz
```

If Plasma shows the old version, restart it:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## Development

- Rebuild shaders: `./tools/build_shaders.sh`
- Rebuild the pattern index after editing `.rle` files: `./tools/build_patterns_index.py`
- Build install packages into `dist/`: `./tools/build_kpackage.sh`
- Check the adaptive injector without Plasma: `node tools/simulate_injection.js`

## Changelog

### 0.2.0

- New Adaptive injector (Classic stays selectable).
- New Zen mode; profiles are now Zen, Balanced, Lively.
- 12-hour clock with AM/PM; clock keeps ticking while paused.
- 48 palettes with a larger picker.
- Redesigned settings that work in small windows.
- Pause when inactive is on by default; speed is capped at 20.

### 0.1.1

- Adjustable fade length (1 to 8 ticks), clock polish, new clock sizes, settings cleanup.

## License

GPL-3.0-or-later. Built with KDE Plasma 6, Qt 6 (QML/JS), GLSL.

<p align="center">
  <i>Dedicated to the memory of John Horton Conway.</i>
</p>
