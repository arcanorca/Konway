#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

if ! command -v tar >/dev/null 2>&1; then
  echo "tar is required but not found" >&2
  exit 1
fi
if ! command -v zip >/dev/null 2>&1; then
  echo "zip is required but not found" >&2
  exit 1
fi

package_id="$(grep -m1 '"Id"' "${repo_root}/metadata.json" | sed -E 's/.*"Id"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
version="$(grep -m1 '"Version"' "${repo_root}/metadata.json" | sed -E 's/.*"Version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"

if [[ -z "${package_id}" || -z "${version}" ]]; then
  echo "Failed to read Id/Version from metadata.json" >&2
  exit 1
fi

dist_dir="${repo_root}/dist"
mkdir -p "${dist_dir}"

base_name="${package_id}-${version}"
tgz_path="${dist_dir}/${base_name}.kpackage.tar.gz"
zip_path="${dist_dir}/${base_name}.kpackage.zip"

rm -f "${tgz_path}" "${zip_path}"

# Package root must contain metadata.json + contents/ for KPackage tools.
tar -czf "${tgz_path}" -C "${repo_root}" metadata.json contents README.md tools
(
  cd "${repo_root}"
  zip -qr "${zip_path}" metadata.json contents README.md tools
)

echo "Created:"
echo "  ${tgz_path}"
echo "  ${zip_path}"
echo
echo "Local install test:"
echo "  kpackagetool6 --type Plasma/Wallpaper --install \"${tgz_path}\""
