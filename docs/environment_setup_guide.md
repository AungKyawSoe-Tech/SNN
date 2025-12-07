# Environment Setup Guide

## Toolchain Components
- **FPGA**: Xilinx Vivado 2023.1 (WebPACK) with Artix-7 support
- **Simulation**: Verilator 5.x, optional Questa/ModelSim
- **Software Build**: RISC-V GNU Toolchain (rv32imac-linux-gnu), Python 3.10+, LiteX dependencies
- **Testing**: `riscv-arch-test`, `pytest`

## Installation Steps (Windows Host with WSL Suggested)
1. **WSL Setup**
   - Enable WSL2 and install Ubuntu 22.04
   - Update packages: `sudo apt update && sudo apt upgrade`
2. **Vivado**
   - Install Vivado on Windows host; configure `settings64.bat`
   - For WSL builds, export `LITEX_VIVADO_PATH` pointing to Windows installation
3. **RISC-V Toolchain**
   ```bash
   git clone https://github.com/riscv/riscv-gnu-toolchain.git
   cd riscv-gnu-toolchain
   ./configure --prefix=$HOME/riscv --enable-multilib
   make linux -j$(nproc)
   ```
   - Add `$HOME/riscv/bin` to PATH
4. **LiteX & Dependencies**
   ```bash
   git clone https://github.com/enjoy-digital/litex.git
   cd litex
   git submodule update --init --recursive
   ./litex_setup.py init
   ./litex_setup.py install
   ```
5. **Python Environment**
   ```bash
   python3 -m venv ~/envs/snn
   source ~/envs/snn/bin/activate
   pip install -r litex_setup/requirements.txt
   pip install numpy matplotlib websockets zeromq pytest
   ```
6. **Simulation Tools**
   ```bash
   sudo apt install verilator gtkwave ghdl ghdl-yosys-plugin
   ```

## Verification
- Run `vivado -version` in PowerShell to confirm installation
- Run `riscv64-unknown-linux-gnu-gcc --version`
- Execute `python3 -m litex.soc.tools.litex_sim --help`

## Automation Scripts
- `scripts/setup_env.ps1` (PowerShell) and `scripts/setup_env.sh` (WSL) will wrap the above commands (see TODO).

## Next Steps
- Capture environment variables in `env/.env.sample`
- Document version pinning once first successful build completes
