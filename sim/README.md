# Simulation Harness Placeholder

This directory will contain the Verilator harness used by the riscv-arch-test automation. Once the VHDL core is imported, add/maintain the following (requires GHDL + ghdl-yosys-plugin for VHDL conversion):

- `verilator_top.sv`: SystemVerilog wrapper that instantiates the core and exposes memory/CSR buses.
- `main.cpp`: C++ driver that loads ELF binaries from the compliance suite and runs the simulation loop.
- `memory.cpp/h`: Simple memory model for instruction/data access.
- Updated `Makefile` invoking Verilator, linking generated C++.

Refer to `docs/wp01/arch_test_setup.md` for the detailed plan.
