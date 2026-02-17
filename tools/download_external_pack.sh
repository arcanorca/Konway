#!/usr/bin/env bash
set -euo pipefail

# Offline helper: download additional RLE patterns into this package.
# Manifest format (whitespace-separated, comments allowed):
#   pattern_name category [sha256]
# Example:
#   glider gliders
#   lwss spaceships

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <manifest.txt> [base_url]" >&2
  exit 1
fi

manifest="$1"
base_url="${2:-https://conwaylife.com/patterns}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
pattern_root="${repo_root}/contents/patterns/rle"

resolve_path() {
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$1"
    return 0
  fi
  if command -v readlink >/dev/null 2>&1; then
    readlink -m "$1"
    return 0
  fi
  return 1
}

if ! pattern_root_real="$(resolve_path "${pattern_root}")"; then
  echo "realpath/readlink is required but not found" >&2
  exit 1
fi

if [[ ! -f "${manifest}" ]]; then
  echo "Manifest not found: ${manifest}" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required but not found" >&2
  exit 1
fi

hash_file_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print tolower($1)}'
    return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print tolower($1)}'
    return 0
  fi
  return 1
}

while IFS= read -r line; do
  line="${line%%#*}"
  line="$(sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' <<<"${line}")"
  [[ -z "${line}" ]] && continue

  read -r name category checksum extra <<<"${line}"

  if [[ -n "${extra:-}" ]]; then
    echo "Skipping malformed line (too many columns): ${line}" >&2
    continue
  fi

  if [[ -z "${name}" || -z "${category}" ]]; then
    echo "Skipping malformed line: ${line}" >&2
    continue
  fi

  if [[ ! "${name}" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Skipping unsafe pattern name '${name}'" >&2
    continue
  fi
  if [[ ! "${category}" =~ ^[A-Za-z0-9_-]+$ ]]; then
    echo "Skipping unsafe category '${category}'" >&2
    continue
  fi
  if [[ -n "${checksum:-}" && ! "${checksum}" =~ ^[A-Fa-f0-9]{64}$ ]]; then
    echo "Skipping invalid sha256 '${checksum}' for ${name}" >&2
    continue
  fi

  mkdir -p "${pattern_root}/${category}"
  url="${base_url}/${name}.rle"
  out="${pattern_root}/${category}/${name}.rle"
  if ! out_real="$(resolve_path "${out}")"; then
    echo "Failed to resolve output path for ${out}" >&2
    continue
  fi
  if [[ "${out_real}" != "${pattern_root_real}/"* ]]; then
    echo "Refusing path outside pattern root: ${out}" >&2
    continue
  fi

  tmp="$(mktemp "${out}.tmp.XXXXXX")"

  echo "Downloading ${url}"
  if ! curl --proto '=https' --tlsv1.2 --fail --show-error --location "${url}" -o "${tmp}"; then
    rm -f "${tmp}"
    echo "Download failed: ${url}" >&2
    continue
  fi

  if [[ -n "${checksum:-}" ]]; then
    if ! actual_checksum="$(hash_file_sha256 "${tmp}")"; then
      rm -f "${tmp}"
      echo "Checksum requested but no sha256 tool found (sha256sum/shasum)" >&2
      exit 1
    fi
    expected_checksum="$(tr '[:upper:]' '[:lower:]' <<<"${checksum}")"
    if [[ "${actual_checksum}" != "${expected_checksum}" ]]; then
      rm -f "${tmp}"
      echo "Checksum mismatch for ${name}.rle" >&2
      continue
    fi
  fi

  mv -f "${tmp}" "${out}"
done < "${manifest}"

"${repo_root}/tools/build_patterns_index.py"
echo "External pack import complete."
