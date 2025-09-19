#!/usr/bin/env bash
set -euo pipefail

ZIP_URL="https://github.com/hyodotdev/openiap-gql/releases/download/1.0.8/openiap-dart.zip"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_FILE="${REPO_ROOT}/lib/types.dart"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

ZIP_PATH="${TMP_DIR}/openiap-dart.zip"

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required but not installed." >&2
  exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
  echo "Error: unzip is required but not installed." >&2
  exit 1
fi

echo "Downloading openiap-dart.zip from ${ZIP_URL}..."
curl -fL "${ZIP_URL}" -o "${ZIP_PATH}"

echo "Extracting types.dart..."
unzip -q -d "${TMP_DIR}" "${ZIP_PATH}" types.dart

if [ ! -f "${TMP_DIR}/types.dart" ]; then
  echo "Error: types.dart not found in archive." >&2
  exit 1
fi

mkdir -p "$(dirname "${TARGET_FILE}")"

echo "Replacing ${TARGET_FILE}"
cp "${TMP_DIR}/types.dart" "${TARGET_FILE}"

echo "Done."
