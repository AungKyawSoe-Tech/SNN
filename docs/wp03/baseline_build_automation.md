# WP03: LiteX Baseline Build Automation

## Objectives
- Automate generation of the LiteX SoC bitstream for the Digilent Arty A7 with minimal manual steps.
- Capture reproducible Vivado build commands suitable for CI integration.
- Archive artefacts (bitstream, reports, console logs) per build.

## Build Flow Summary
1. Invoke LiteX target script to produce gateware (`python -m litex_boards.targets.digilent_arty ...`).
2. Run Vivado in batch mode with generated TCL (`build/digilent_arty/vivado_synth.tcl`).
3. Collect utilisation/timing reports into `build/reports/<timestamp>/`.
4. Package outputs for deployment (bitstream `.bit`, firmware `.bin`, device tree `.dts`).

## Automation Artifacts
- `scripts/build_baseline.ps1`: Windows/PowerShell wrapper for LiteX + Vivado build.
- `scripts/build_baseline.sh`: WSL/Linux equivalent for CI runners.
- `ci/github/workflows/build.yml`: Draft GitHub Actions workflow (future addition).

## Build Parameters
| Parameter | Default | Notes |
|-----------|---------|-------|
| CPU Type  | `vexriscv` | LiteX VexRiscv core |
| Variant   | `linux`    | Enables MMU/cache |
| Sys Clock | 100 MHz    | Derived from 100 MHz oscillator |
| Ethernet  | Enabled    | Optional; disable for resource savings |
| SD Card   | Enabled    | Provides removable storage |

## Execution Steps (PowerShell)
```pwsh
pwsh scripts/build_baseline.ps1 -Board arty_a7 -WithEthernet -WithSDCard -DryRun
```
Use `-DryRun` during CI smoke tests to exercise report archival without invoking Vivado.

## Logging & Reports
- Vivado logs stored under `build/digilent_arty/gateware/vivado.log`.
- Reports mirrored into `reports/vivado/<date>/` by scripts.
- Future enhancement: parse utilisation into CSV for trend tracking.
 - Dry-run mode still timestamps report directories even when build artifacts are absent.

## Next Tasks
- Implement CI workflow once scripts validated locally.
- Integrate timing/utilisation thresholds to fail builds automatically on regression.
```