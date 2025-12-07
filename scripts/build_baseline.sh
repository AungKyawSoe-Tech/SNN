#!/usr/bin/env bash
# Trigger LiteX baseline build in batch mode and archive reports.
set -euo pipefail

CPU_TYPE="vexriscv"
CPU_VARIANT="linux"
WITH_ETHERNET=1
WITH_SDCARD=1
LITEX_PATH="${HOME}/litex"
LOG_DIR="../reports/vivado"
DRY_RUN=0

usage() {
  echo "Usage: $0 [--no-ethernet] [--no-sdcard] [--litex PATH]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-ethernet) WITH_ETHERNET=0; shift ;;
    --no-sdcard) WITH_SDCARD=0; shift ;;
    --litex) LITEX_PATH="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option $1"; usage; exit 1 ;;
  esac
done

if [[ ! -d "$LITEX_PATH" ]]; then
  echo "LiteX path '$LITEX_PATH' not found" >&2
  exit 1
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
REPORT_PATH="${LOG_DIR}/${TIMESTAMP}"
mkdir -p "$REPORT_PATH"

pushd "$LITEX_PATH" >/dev/null
CMD=(python -m litex_boards.targets.digilent_arty --cpu-type "$CPU_TYPE" --cpu-variant "$CPU_VARIANT" --build)
[[ $WITH_ETHERNET -eq 1 ]] && CMD+=(--with-ethernet)
[[ $WITH_SDCARD -eq 1 ]] && CMD+=(--with-sdcard)

echo "Running LiteX build: ${CMD[*]}"
if [[ $DRY_RUN -eq 0 ]]; then
  "${CMD[@]}"
else
  echo "Dry run enabled; skipping execution."
fi

cp build/digilent_arty/gateware/vivado.log "$REPORT_PATH"/vivado.log || true
cp build/digilent_arty/gateware/top_utilization.rpt "$REPORT_PATH"/utilization.rpt || true
cp build/digilent_arty/gateware/top_timing.rpt "$REPORT_PATH"/timing.rpt || true
popd >/dev/null

echo "Reports archived to $REPORT_PATH"
