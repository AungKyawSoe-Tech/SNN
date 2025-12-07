# LiteX Baseline Build Success Log
**Date:** 2025-12-06  
**Objective:** Generate hardware baseline for Arty A7 with VexRiscv Linux variant  
**Status:** ✅ SUCCESS (Verilog generation complete, Vivado synthesis pending)

## Configuration
- **Target:** Digilent Arty A7 (XC7A35TICSG324-1L)
- **SoC Generator:** LiteX f4baf8e
- **CPU:** VexRiscv Linux variant (RV32IMAC + MMU + S-mode)
- **System Clock:** 50MHz (PLL from 100MHz input)
- **Memory Map:**
  - ROM: 0x00000000 - 0x0001FFFF (128KB, resized from 131,072B to 24,524B after BIOS)
  - SRAM: 0x10000000 - 0x10001FFF (8KB)
  - Main RAM: 0x40000000 - 0x40007FFF (32KB integrated)
  - CSR: 0xf0000000 - 0xf000FFFF (64KB)
  - I/O: 0x80000000 - 0xFFFFFFFF (2GB)
- **Peripherals:**
  - UART @ 0xf0002000 (115200 baud)
  - Timer @ 0xf0001800
  - LED controller @ 0xf0001000
  - System controller @ 0xf0000000
- **Bus:** 32-bit Wishbone, 4GB address space

## Build Steps
1. **Environment Setup:**
   - Created Python venv at `c:\CoPilot_Cli\SNN\litex_venv`
   - Installed LiteX ecosystem (litex, migen, litex-boards)
   - Installed RISC-V toolchain: `gcc-riscv64-unknown-elf` 13.2.0
   - Installed build dependencies: meson 1.9.2, ninja 1.13.0

2. **Source Generation:**
   ```bash
   cd third_party/litex
   python3 litex_setup.py init    # Clone all repositories
   python3 litex_setup.py --install  # Install Python packages
   ```

3. **SoC Build:**
   ```bash
   python3 -m litex_boards.targets.digilent_arty \
     --cpu-type vexriscv \
     --cpu-variant linux \
     --sys-clk-freq 50e6 \
     --integrated-main-ram-size 0x8000 \
     --no-compile-gateware \
     --build
   ```

## Outputs
### Generated Files
- **Verilog:** `build/digilent_arty/gateware/digilent_arty.v` (2054 lines)
- **Constraints:** `build/digilent_arty/gateware/digilent_arty.xdc`
- **TCL script:** `build/digilent_arty/gateware/digilent_arty.tcl`
- **Memory initialization:**
  - `digilent_arty_rom.init` (BIOS, 24,524 bytes)
  - `digilent_arty_sram.init` (8KB)
  - `digilent_arty_main_ram.init` (32KB)
  - `digilent_arty_mem.init` (combined)
- **CSR map:** `build/digilent_arty/csr.csv` (56 lines, machine-readable)
- **CSR JSON:** `build/digilent_arty/csr.json` (for drivers/tools)

### BIOS Statistics
```
ROM usage: 23.93KiB (18.70% of 128KB)
RAM usage: 1.62KiB  (20.21% of 8KB)
```

### SoC Hierarchy
```
BaseSoC
├── crg (_CRG) - Clock/Reset Generator (S7PLL, 100→50MHz sys, 25MHz eth)
├── bus (SoCBusHandler) - Wishbone interconnect (2 masters, 4 slaves)
├── cpu (VexRiscv) - RV32IMAC Linux variant with dual-bus interface
├── rom (SRAM) - Bootstrap ROM @ 0x0
├── sram (SRAM) - Scratchpad @ 0x10000000
├── main_ram (SRAM) - Main memory @ 0x40000000
├── uart (UART) - RS232 PHY with TX/RX FIFOs
├── timer0 (Timer) - 32-bit countdown timer
├── leds (LedChaser) - 4x LED controller
└── csr_bridge (Wishbone2CSR) - CSR bus bridge @ 0xf0000000
```

## Issues Resolved
1. **Line Ending (CRLF):** Bypassed by invoking Python directly instead of shebang
2. **PEP 668 (externally-managed):** Created venv instead of system-wide pip install
3. **Missing Toolchain:** Installed `gcc-riscv64-unknown-elf` from Ubuntu repos
4. **Missing Build System:** Installed `meson` and `ninja` via pip

## Next Steps
1. **Vivado Synthesis (WP03.2):**
   ```bash
   cd build/digilent_arty/gateware
   vivado -mode batch -source digilent_arty.tcl
   ```
   - Expected runtime: 15-30 minutes on modern workstation
   - Output: `digilent_arty.bit` bitstream file
   - Reports: Timing, utilization, power

2. **Hardware Programming (WP03.3):**
   - Load bitstream via JTAG: `openFPGALoader -b arty digilent_arty.bit`
   - Or via Vivado Hardware Manager
   - Verify LED activity and UART output

3. **Linux Boot Validation (WP04):**
   - Build minimal kernel (Buildroot RV32 config)
   - Load via TFTP or SPI flash
   - Confirm kernel boot messages on UART

4. **SNN Accelerator Integration (WP04.3):**
   - Add CSR block at 0xf0003000 (spike_config, spike_fifo, dma_ctrl)
   - Instantiate in LiteX platform file
   - Resynthesize and compare resource delta

## Resource Baseline (Pre-Accelerator)
| Resource | Usage | Available | Util% |
|----------|-------|-----------|-------|
| LUTs     | TBD   | 20,800    | TBD   |
| FFs      | TBD   | 41,600    | TBD   |
| BRAM     | TBD   | 50 (1.8Mb)| TBD   |
| DSPs     | TBD   | 90        | TBD   |

**Note:** Run Vivado synthesis to populate utilization numbers.

## Lessons Learned
1. **VexRiscv Default:** LiteX's native VexRiscv core already provides Linux support (MMU, S-mode), eliminating need for NEORV32 conversion.
2. **Toolchain Ordering:** RISC-V GCC must be installed before LiteX BIOS build; meson/ninja required for software compilation.
3. **WSL Path Handling:** LiteX handles `/mnt/c/` paths correctly; no symlink workarounds needed.
4. **Build Speed:** Verilog generation completes in ~60 seconds; Vivado synthesis expected 15-30 minutes.

## References
- LiteX commit: f4baf8e
- VexRiscv variant: `linux` (includes MMU, S-mode, A-extension)
- Arty A7 board file: `third_party/litex-boards/litex_boards/targets/digilent_arty.py`
- BIOS source: `third_party/litex/litex/soc/software/bios/`
- CSR documentation: `build/digilent_arty/csr.csv`
