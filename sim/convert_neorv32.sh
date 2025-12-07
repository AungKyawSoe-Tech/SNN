#!/usr/bin/env bash
# Convert NEORV32 VHDL sources to Verilog using ghdl-yosys-plugin.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RTL_DIR="${PROJECT_ROOT}/rtl/neorv32"
OUTPUT="${PROJECT_ROOT}/rtl/neorv32_synth.v"

if [[ ! -d "$RTL_DIR" ]]; then
  echo "NEORV32 sources not found at $RTL_DIR" >&2
  exit 1
fi

if ! command -v ghdl >/dev/null 2>&1; then
  echo "Error: ghdl not found. Install ghdl and ghdl-yosys-plugin (see docs/environment_setup_guide.md)." >&2
  exit 1
fi

GHDL_FLAGS=(--std=08 --no-formal)

mkdir -p "${PROJECT_ROOT}/build/ghdl"
pushd "${PROJECT_ROOT}/build/ghdl" >/dev/null

ghdl -i "${GHDL_FLAGS[@]}" ${RTL_DIR}/rtl/core/*.vhd

ghdl --elab-run "${GHDL_FLAGS[@]}" neorv32_top --no-run

ghdl --synth "${GHDL_FLAGS[@]}" neorv32_top > "$OUTPUT"

echo "Generated $OUTPUT"

popd >/dev/null
