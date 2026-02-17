#!/usr/bin/env bash
set -euo pipefail

QSB_BIN="$(command -v qsb || true)"
if [[ -z "${QSB_BIN}" ]]; then
  QSB_BIN="/usr/lib/qt6/bin/qsb"
fi

"${QSB_BIN}" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/shaders/life_step.frag.qsb contents/shaders/life_step.frag
"${QSB_BIN}" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/shaders/visualize.frag.qsb contents/shaders/visualize.frag
"${QSB_BIN}" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o contents/shaders/population_probe.frag.qsb contents/shaders/population_probe.frag
