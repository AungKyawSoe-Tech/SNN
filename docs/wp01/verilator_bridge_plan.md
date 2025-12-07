# Verilator Bridge Plan for VHDL Core

## Objective
Translate the VHDL-only NEORV32 core into a form consumable by Verilator so the riscv-arch-test suite can be executed without commercial simulators.

## Approaches
1. **ghdl-yosys-plugin flow**
   - Use GHDL frontend to elaborate VHDL and emit Verilog via Yosys.
   - Commands:
     ```bash
     ghdl --std=08 -i rtl/neorv32/rtl/core/*.vhd
     ghdl --std=08 -m neorv32_top
     ghdl --std=08 --synth neorv32_top > rtl/neorv32_synth.v
     ```
   - Feed `neorv32_synth.v` into Verilator along with LiteX wrapper.

2. **Mixed-Language Simulation**
   - Use commercial simulator (Questa) with VHDL/VLOG co-sim and connect via DPI.
   - Not preferred for CI due to licensing constraints.

3. **Alternative Core**
   - If conversion proves difficult, maintain VexRiscv for Linux and run NEORV32 as secondary IP with dedicated testbench.

## Deliverables
- `sim/convert_neorv32.sh`: script automating GHDL synthesis to Verilog.
- Updated `sim/Makefile` to invoke conversion step before Verilator build.
- Documentation in `docs/wp01/arch_test_setup.md` referencing bridge requirement.

## Caveats
- ghdl-yosys output may require manual patches for RAM/DSP components.
- Need to ensure license compatibility when distributing synthesized Verilog.

## Next Steps
- Install ghdl-yosys-plugin in environment (documented in setup guide).
- Prototype conversion on subset of modules to validate feasibility.
- Integrate conversion script and update automation.
