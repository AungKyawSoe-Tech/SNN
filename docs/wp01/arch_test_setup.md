# riscv-arch-test Harness Setup (Verilator)

## Goal
Provide repeatable instructions to run the official RISC-V architectural compliance tests against the VHDL core using Verilator.

## Prerequisites
- Environment configured per `docs/environment_setup_guide.md`
- Verilator 5.x installed (`verilator --version`)
- RISC-V GNU toolchain with `riscv32-unknown-elf-gcc`
- GHDL + ghdl-yosys-plugin installed to translate VHDL core to Verilog (`sudo apt install ghdl ghdl-yosys-plugin`)

## Repository Layout
- `rtl/` (to be populated) contains the VHDL/Verilog wrapper for the core under test.
- `sim/` will hold Verilator harness sources.
- `third_party/riscv-arch-test` cloned alongside project.

## Setup Steps
1. Clone the compliance suite:
   ```bash
   git clone https://github.com/riscv-non-isa/riscv-arch-test.git third_party/riscv-arch-test
   ```
2. Create a Verilator top-level wrapper that instantiates the VHDL core via verilated SystemVerilog/VHDL interface (`rtl/verilator_top.sv`).
3. Provide a C++ testbench (`sim/main.cpp`) that loads test binaries into simulated memory and steps the core.
4. Implement a `Makefile` under `sim/` that ties together Verilator, the wrapper, and the compliance suite build rules.

## Running Tests
```bash
cd sim
make ARCH=rv32imc TARGET=riscv_tests ISS=riscv32
```
- `ARCH` selects the subset (rv32i, rv32im, rv32imc, etc.).
- Results stored in `sim/out/<arch>/<test>/` with pass/fail markers.

## Automation Script
- `scripts/run_arch_tests.sh` invokes the Makefile with sanity defaults and collates results (see script for details).

## Reporting
- Summaries written to `reports/arch_tests/<timestamp>.json` (future enhancement).
- Failures should be logged with waveform captures (VCD) for debugging.

## Next Actions
- Populate `rtl/` and `sim/` scaffolding once core sources are imported.
- Extend Makefile to support waveform toggles and performance counters.
