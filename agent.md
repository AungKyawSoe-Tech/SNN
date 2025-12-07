# Agent Activity Log

## Summary to Date (2025-12-06)

- **Roadmap Synchronisation**: Reviewed and expanded `linux_and_snn_task_roadmap.md`, and duplicated canonical planning in `000_linux_and_snn_task_roadmap.md` to keep the programme roadmap consistent.
- **Session Logging**: Established chronological activity tracking in `001_prototype_litex_soc.md`, appending rationale for every major action.
- **LiteX Bring-up Preparation**:
  - Authored `docs/litex_prototype_plan.md` outlining the VexRiscv/Linux build flow for Arty A7.
  - Created automation scripts (`scripts/build_baseline.ps1`, `scripts/build_baseline.sh`) with dry-run support and documented usage in `docs/wp03/baseline_build_automation.md` and `docs/wp03/logs/2025-11-29_dryrun_plan.md`.
  - Cloned LiteX into `third_party/litex`; first real build attempt failed due to missing `litex_boards` module (recorded in session log).
- **SNN Accelerator Planning**:
  - Drafted interface specification (`docs/snn_accelerator_interface.md`) covering CSR map, DMA strategy, and spike data format.
  - Produced timing/utilisation iteration plan in `docs/timing_utilization_plan.md`.
- **Software Stack Skeletons**:
  - Added Linux driver scaffold (`kernel/snn_accel.c`) and user-space smoke test (`user/snn_test.py`).
- **Visualization/Training Strategy**: Captured long-term architecture and work packages in `docs/system_architecture_strategy.md`.
- **Work Package Kick-offs**:
  - WP01: Created `docs/wp01/core_assessment.md`, feature matrix (`core_matrix_template.csv`), opcode map, NEORV32 integration plan, and conversion logs.
  - WP03: Authored baseline automation notes and logging stubs.
- **Tooling & Environment**:
  - Documented environment setup (`docs/environment_setup_guide.md`) and provided setup scripts for PowerShell/WSL.
  - Cloned NEORV32 into `rtl/neorv32` (commit `cfcfda82`), removed placeholders, updated feature matrix to reflect current core capabilities.
  - Added GHDL conversion plan (`docs/wp01/verilator_bridge_plan.md`) and scripts (`sim/convert_neorv32.sh`); conversion currently blocked pending installation of `ghdl` and `ghdl-yosys-plugin` in WSL.
- **Compliance Automation**: Stubbed Verilator harness (`sim/verilator_top.sv`, `sim/main.cpp`) and runner (`scripts/run_arch_tests.sh`), awaiting successful VHDL-to-Verilog conversion.

## Outstanding Prerequisites
1. Install `ghdl` and `ghdl-yosys-plugin` inside the WSL environment, then rerun `sim/convert_neorv32.sh` followed by `scripts/run_arch_tests.sh`.
2. Execute `./litex_setup.py init && ./litex_setup.py install` inside `third_party/litex` to provide the `litex_boards` Python module before reattempting the baseline build scripts without dry run.

## Next Planned Steps
- After the above prerequisites, re-run compliance tests and baseline build, verify report artefacts, and proceed toward Arty A7 programming workflow.
