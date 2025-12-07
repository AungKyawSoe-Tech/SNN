# Quick Reference Card - SNN Project on Arty A7

## Project Structure
```
SNN/
├── build/digilent_arty/          ← LiteX build outputs
│   ├── gateware/*.v              ← Synthesizable Verilog
│   ├── software/bios/            ← Compiled BIOS
│   └── csr.csv                   ← Register map
├── rtl/                          ← Custom RTL
│   ├── snn_accelerator_top.v    ← Main peripheral
│   ├── spike_fifo.v              ← FIFO module
│   └── snn_accel_litex.py       ← LiteX wrapper
├── docs/                         ← Documentation
│   ├── wp03/                     ← Hardware build guides
│   └── wp04/                     ← Linux kernel guides
├── third_party/                  ← External repos
│   ├── litex/                    ← SoC generator
│   └── litex-boards/             ← Board definitions
└── litex_venv/                   ← Python environment
```

## Key Commands

### LiteX Build
```bash
cd /mnt/c/CoPilot_Cli/SNN
source litex_venv/bin/activate

# Baseline (no synthesis)
python3 -m litex_boards.targets.digilent_arty \
  --cpu-type vexriscv --cpu-variant linux \
  --sys-clk-freq 50e6 --integrated-main-ram-size 0x8000 \
  --no-compile-gateware --build

# Full build with Vivado (30 min)
python3 -m litex_boards.targets.digilent_arty \
  --cpu-type vexriscv --cpu-variant linux \
  --sys-clk-freq 50e6 --integrated-main-ram-size 0x8000 \
  --build
```

### Vivado Synthesis
```powershell
cd C:\CoPilot_Cli\SNN\build\digilent_arty\gateware
vivado -mode batch -source digilent_arty.tcl
# Output: digilent_arty.bit (~1-2 MB)
```

### FPGA Programming
```powershell
# Via Vivado Hardware Manager
vivado -mode tcl
> open_hw_manager
> connect_hw_server
> open_hw_target
> program_hw_devices [current_hw_device] digilent_arty.bit

# Via OpenFPGALoader (WSL)
wsl openFPGALoader -b arty digilent_arty.bit
```

### UART Console
```powershell
# Find COM port
Get-WmiObject Win32_SerialPort | Select Name,DeviceID

# Connect with PuTTY
putty -serial COM3 -sercfg 115200,8,n,1,N
```

## Memory Map

| Region | Start | End | Size | Purpose |
|--------|-------|-----|------|---------|
| ROM | 0x00000000 | 0x0001FFFF | 128KB | BIOS |
| SRAM | 0x10000000 | 0x10001FFF | 8KB | Scratchpad |
| Main RAM | 0x40000000 | 0x40007FFF | 32KB | Code/Data |
| CSR | 0xf0000000 | 0xf000FFFF | 64KB | Peripherals |
| I/O | 0x80000000 | 0xFFFFFFFF | 2GB | Memory-mapped I/O |

### CSR Peripherals
| Name | Address | Location | IRQ |
|------|---------|----------|-----|
| ctrl | 0xf0000000 | 0 | - |
| identifier | 0xf0000800 | 1 | - |
| leds | 0xf0001000 | 2 | - |
| timer0 | 0xf0001800 | 3 | 1 |
| uart | 0xf0002000 | 4 | 0 |
| **snn_accel** | **0xf0003000** | **5** | **2** |

## SNN Accelerator CSR Map

| Offset | Register | Access | Function |
|--------|----------|--------|----------|
| +0x00 | CONFIG | RW | Enable, mode config |
| +0x04 | STATUS | RO | FIFO status, errors |
| +0x08 | CONTROL | RW | Commands (start/stop) |
| +0x0C | IRQ_MASK | RW | Interrupt enables |
| +0x10 | IRQ_STATUS | RW1C | Interrupt flags |
| +0x20 | FIFO_IN_DATA | WO | Push spike |
| +0x28 | FIFO_OUT_DATA | RO | Pop spike |
| +0x4C | THRESHOLD | RW | Spike threshold |
| +0x50 | LEAK_RATE | RW | Membrane leak |

**Full map:** See `002_snn_accelerator_integration.md`

## Common Tasks

### Rebuild LiteX SoC
```bash
cd /mnt/c/CoPilot_Cli/SNN
source litex_venv/bin/activate
python3 -m litex_boards.targets.digilent_arty \
  --cpu-type vexriscv --cpu-variant linux \
  --sys-clk-freq 50e6 --build
```

### Add SNN to Platform
Edit: `third_party/litex-boards/litex_boards/targets/digilent_arty.py`
```python
from rtl.snn_accel_litex import add_snn_accelerator

class BaseSoC(SoCCore):
    def __init__(self, **kwargs):
        # ... existing code ...
        add_snn_accelerator(self)
```

### Check Build Logs
```bash
# Last build output
tail -100 build.log

# Vivado reports
ls -lh build/digilent_arty/gateware/*.rpt
```

### Linux Kernel Build
```bash
cd /mnt/c/CoPilot_Cli/SNN/third_party/buildroot
make qemu_riscv32_virt_defconfig
make menuconfig  # Apply custom config
make -j$(nproc)  # 30-60 min first time
# Output: output/images/Image, rootfs.cpio.gz
```

## Useful Registers

### Read SNN Status (via driver)
```python
import mmap
CSR_BASE = 0xf0003000
STATUS_OFFSET = 0x04
with open("/dev/mem", "r+b") as f:
    mem = mmap.mmap(f.fileno(), 4096, offset=CSR_BASE)
    status = int.from_bytes(mem[STATUS_OFFSET:STATUS_OFFSET+4], 'little')
    print(f"FIFO IN empty: {status & 0x2}")
    print(f"Compute active: {status & 0x10}")
```

### Push Spike to FIFO
```python
FIFO_IN_DATA = 0x20
spike_data = (neuron_id << 16) | timestamp
mem[FIFO_IN_DATA:FIFO_IN_DATA+4] = spike_data.to_bytes(4, 'little')
```

## Troubleshooting

### Vivado Not Found
```powershell
# Find installation
dir "C:\Xilinx\Vivado\*\bin\vivado.bat" -Recurse

# Add to PATH temporarily
$env:PATH += ";C:\Xilinx\Vivado\2023.1\bin"
```

### UART No Output
- Check baud rate: Must be 115200
- Verify COM port number
- Try different USB port
- Check JP1 jumper on board (UART enable)

### Build Fails
```bash
# Clean and retry
rm -rf build/
python3 -m litex_boards.targets.digilent_arty --clean
```

### Out of Memory (Synthesis)
- Close other applications
- Increase Windows page file
- Use Vivado GUI instead of batch mode

## Important Files

| File | Purpose |
|------|---------|
| `001_prototype_litex_soc.md` | First session log |
| `002_snn_accelerator_integration.md` | Second session log |
| `SESSION_SUMMARY.md` | This session summary |
| `build/digilent_arty/csr.csv` | Register addresses |
| `rtl/snn_accelerator_top.v` | Main accelerator RTL |
| `docs/wp03/vivado_synthesis_quickstart.md` | Synthesis guide |
| `docs/wp04/linux_kernel_build_guide.md` | Kernel build guide |

## Resource Targets

| Resource | Baseline | +SNN | Target Max |
|----------|----------|------|------------|
| LUTs | ~8K | ~13K | <15K (70%) |
| FFs | ~10K | ~16K | <25K (60%) |
| BRAM | ~15 | ~25 | <35 (70%) |
| DSPs | 0 | ~16 | <70 (80%) |

## Next Actions Checklist
- [ ] Run Vivado synthesis
- [ ] Program FPGA and verify UART
- [ ] Implement neuron core (lif_neuron.v)
- [ ] Integrate SNN into LiteX platform
- [ ] Test CSR access via Python
- [ ] Build Linux kernel with Buildroot
- [ ] Complete Linux driver
- [ ] Test spike processing on hardware

## Support
- **LiteX Docs:** https://github.com/enjoy-digital/litex/wiki
- **VexRiscv:** https://github.com/SpinalHDL/VexRiscv
- **Arty A7:** https://reference.digilentinc.com/arty-a7
- **Session Logs:** See `00X_*.md` files for detailed rationale
