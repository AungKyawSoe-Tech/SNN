#!/usr/bin/env bash
# Run riscv-arch-test compliance suite using the Verilator harness.
set -euo pipefail

ARCH="rv32imc"
TARGET="riscv_tests"
RESULTS_DIR="../reports/arch_tests"
MAKE_ARGS=()

usage() {
  echo "Usage: $0 [-a arch] [-t target]"
  echo "Example: $0 -a rv32i"
}

while getopts "a:t:h" opt; do
  case "$opt" in
    a) ARCH="$OPTARG" ;;
    t) TARGET="$OPTARG" ;;
    h|*) usage; exit 0 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIM_DIR="${SCRIPT_DIR}/../sim"

mkdir -p "$RESULTS_DIR"

pushd "$SIM_DIR" >/dev/null
if [[ ! -f "verilator_top.sv" ]]; then
  echo "verilator_top.sv missing. Import core sources into rtl/ and regenerate wrapper." >&2
  exit 1
fi

make ARCH="$ARCH" TARGET="$TARGET" "${MAKE_ARGS[@]}"
popd >/dev/null

echo "Compliance run complete. Inspect ${RESULTS_DIR} for summaries (TODO)."
