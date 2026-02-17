#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

package_id="$(grep -m1 '"Id"' "${repo_root}/metadata.json" | sed -E 's/.*"Id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
if [[ -z "${package_id}" ]]; then
  echo "Failed to read KPlugin.Id from metadata.json" >&2
  exit 1
fi

target_root="${HOME}/.local/share/plasma/wallpapers"
target_dir="${target_root}/${package_id}"

mkdir -p "${target_root}"
rsync -a --delete \
  --exclude '.git' \
  --exclude 'dist' \
  --exclude '.DS_Store' \
  "${repo_root}/" "${target_dir}/"

echo "Deployed to: ${target_dir}"
echo "If needed, restart shell:"
echo "  kquitapp6 plasmashell && kstart6 plasmashell"
