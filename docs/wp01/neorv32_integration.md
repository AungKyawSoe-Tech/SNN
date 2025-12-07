# NEORV32 Integration Plan

## Repository Acquisition
- Recommended approach: add NEORV32 as a git submodule for traceability.
  ```bash
  git submodule add https://github.com/stnolting/neorv32.git rtl/neorv32
  git submodule update --init --recursive
  ```
- Alternative: vendor a specific release tarball into `rtl/neorv32` while preserving LICENSE files.

## Directory Layout
```
rtl/
  neorv32/
    rtl/
      core/
      processor_templates/
    sw/
    docs/
```

## Configuration Targets
- Enable `NEORV32_USE_MULDIV=1` and `NEORV32_USE_Zicsr=1` to expose RV32IM
- Evaluate `NEORV32_USE_Zifencei` and `NEORV32_USE_Zicsr` toggles required by Linux
- Confirm availability of PMP/MMU; NEORV32 does not ship with a full MMU, so LiteX integration must provide page-table emulation or alternative core (follow-up action)

## Build Hooks
- Add `rtl/neorv32/rtl/core/` to LiteX platform when replacing VexRiscv (experimental)
- For compliance testing, use GHDL or ghdl-yosys-plugin to translate VHDL into Verilog consumable by Verilator:
  ```bash
  ghdl --std=08 -i --work=neorv32work rtl/neorv32/rtl/core/*.vhd
  ghdl --std=08 -m --work=neorv32work neorv32_top
  ghdl --std=08 --synth neorv32_top > rtl/neorv32_synth.v
  ```
  (Exact command sequence to be refined once sources are present.)

## Open Questions
1. Does NEORV32 provide Supervisor-mode support suitable for Linux? If not, consider PicoRV32 w/ MMU or VexRiscv MMU core as primary Linux host, using NEORV32 for coprocessing/testing.
2. What is the plan for integration with LiteX (native CPU vs. external IP block)? Need to assess bridging overhead.
3. Confirm licensing implications when modifying NEORV32 for SNN extensions.

## Next Steps
- Clone repository and record commit hash in `docs/wp01/core_assessment.md`.
- Replace `neorv32_placeholder.vhd` once sources are available.
- Update feature matrix with concrete statuses derived from documentation and HDL inspection.
