# LiteX SoC Prototype Plan

## Objective
Capture the configuration and build flow required to generate a Linux-capable LiteX SoC for the Digilent Arty A7 (Artix-7) using a VexRiscv core with MMU support.

## Platform Overview
- **Board**: Digilent Arty A7 (XC7A35T/100T)
- **Memory**: 256 MB DDR3 via MIG
- **Peripherals**: UART, Ethernet (LiteEth), SPI flash, GPIO
- **Toolchain**: LiteX + VexRiscv, Vivado 2023.1, Buildroot (LiteX Linux)

## Build Environment Prerequisites
1. Install Python 3.10+ and pip
2. Clone LiteX and submodules:
   ```pwsh
   git clone https://github.com/enjoy-digital/litex.git
   cd litex
   git submodule update --init --recursive
   ```
3. Install LiteX Python dependencies:
   ```pwsh
   pip install -r litex_setup/requirements.txt
   ```
4. Ensure Vivado 2023.1 is in PATH or configure `LITEX_VIVADO_PATH`
5. Install RISC-V GNU toolchain (Linux-capable, e.g., `riscv64-linux-gnu-`) and add to PATH

## SoC Configuration Targets
- VexRiscv SMP disabled, single core with MMU (`--cpu-type vexriscv --cpu-variant linux`) 
- Enable integrated ROM for BIOS and SPI flash boot (`--integrated-rom-size 0x8000`)
- DDR3 controller via LiteDRAM (`--with-sdram --sdram-module MT41K256M16 --sdram-rd-bitslip 5 --sdram-wr-bitslip 3`)
- UART for console (`--uart-name serial`)
- Ethernet for TFTP/NFS boot if desired (`--with-ethernet`)
- CSR/Bus frequency: target 100 MHz fabric

## Build Steps
1. Generate gateware and software images:
   ```pwsh
   python -m litex_boards.targets.digilent_arty --cpu-type vexriscv --cpu-variant linux --with-ethernet --with-sdcard --build --load
   ```
   - Use `--build` to invoke Vivado synthesis/implementation
   - Use `--load` for immediate bitstream download via OpenOCD/Digilent tools
2. Build Linux images with LiteX Buildroot integration:
   ```pwsh
   ./litex_setup.py build buildroot
   ./litex_setup.py build linux
   ```
3. Package kernel, rootfs, and device tree in SPI flash or load via TFTP
4. Boot sequence: SPI Flash -> LiteX BIOS -> OpenSBI -> Linux kernel -> BusyBox rootfs

## Validation Checklist
- BIOS boots and detects DDR3
- OpenSBI reports hart0 booting successfully
- Linux kernel reaches shell prompt on UART
- Ethernet link up and ping works (if included)

## Open Questions
- Confirm DDR3 calibration values for specific Arty A7 revision
- Decide on SD card vs TFTP rootfs strategy
- Determine required clock constraints for SoC peripherals
