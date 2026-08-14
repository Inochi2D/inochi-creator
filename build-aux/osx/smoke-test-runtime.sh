#!/usr/bin/env bash
set -euo pipefail

compiler="${1:-ldc2}"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

printf 'void main() {}\n' > "$temporary_directory/runtime_smoke.d"
"$compiler" "$temporary_directory/runtime_smoke.d" -of="$temporary_directory/runtime-smoke"
"$temporary_directory/runtime-smoke"

echo "D runtime smoke test passed with $compiler"
