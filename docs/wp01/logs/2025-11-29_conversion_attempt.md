# NEORV32 Conversion Attempt (2025-11-29)

## Command
```bash
wsl -e bash -lc "cd /mnt/c/CoPilot_Cli/SNN/sim && ./convert_neorv32.sh"
```

## Outcome
- Failure: `ghdl: command not found`

## Diagnosis
- WSL environment missing GHDL and ghdl-yosys-plugin packages.
- Script now computes project root without relying on git.

## Next Actions
1. Run `sudo apt install ghdl ghdl-yosys-plugin` inside WSL (already documented in setup guide).
2. Re-run `sim/convert_neorv32.sh` to generate `rtl/neorv32_synth.v`.
3. Verify `sim/Makefile` picks up the generated file before invoking Verilator.
