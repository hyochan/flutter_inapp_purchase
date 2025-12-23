#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_FILE="${REPO_ROOT}/lib/types.dart"
TMP_DIR="$(mktemp -d)"
VERSIONS_FILE="${REPO_ROOT}/openiap-versions.json"

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required but not installed." >&2
  exit 1
fi

OPENIAP_GQL_VERSION=$(python3 - "${VERSIONS_FILE}" <<'PY'
import json
import sys
from pathlib import Path
versions_path = Path(sys.argv[1])
try:
    data = json.loads(versions_path.read_text())
except FileNotFoundError:
    print(f"Error: {versions_path} not found", file=sys.stderr)
    sys.exit(1)
except json.JSONDecodeError as exc:
    print(f"Error parsing {versions_path}: {exc}", file=sys.stderr)
    sys.exit(1)

value = data.get('gql')
if not value:
    print("Error: 'gql' version missing in openiap-versions.json", file=sys.stderr)
    sys.exit(1)

print(value)
PY
)

ZIP_URL="https://github.com/hyodotdev/openiap/releases/download/gql-${OPENIAP_GQL_VERSION}/openiap-dart.zip"

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
# Add ignore directives at the top of the file
# Note: dart format doesn't respect these, but analyzer and coverage do
echo "// ignore_for_file: type=lint" > "${TARGET_FILE}"
echo "// coverage:ignore-file" >> "${TARGET_FILE}"
echo "" >> "${TARGET_FILE}"
cat "${TMP_DIR}/types.dart" >> "${TARGET_FILE}"

echo "Done."
