# Quick Start: Vivado Synthesis and Hardware Programming

## Prerequisites
- Vivado 2023.1 WebPACK installed and in PATH
- Digilent Arty A7 board connected via USB (JTAG)
- LiteX baseline build completed (Verilog generated)

## Step 1: Run Vivado Synthesis
```powershell
# In PowerShell
cd C:\CoPilot_Cli\SNN\build\digilent_arty\gateware
vivado -mode batch -source digilent_arty.tcl
```

**Expected Output:**
- Bitstream: `digilent_arty.bit` (typically 1-2MB)
- Reports:
  - `digilent_arty_utilization.rpt` - Resource usage
  - `digilent_arty_timing.rpt` - Timing analysis
  - `digilent_arty_power.rpt` - Power estimate
- Runtime: 15-30 minutes (depends on CPU)

## Step 2: Program FPGA via Vivado Hardware Manager
```powershell
vivado -mode tcl
# Inside Vivado TCL console:
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [get_hw_devices xc7a*]
set_property PROGRAM.FILE {digilent_arty.bit} [current_hw_device]
program_hw_devices [current_hw_device]
close_hw_manager
exit
```

## Step 3: Connect to UART Console
```powershell
# Install PuTTY or use Windows Terminal with COM port
# Settings:
# - Baud: 115200
# - Data bits: 8
# - Stop bits: 1
# - Parity: None
# - Flow control: None

# Find COM port:
Get-WmiObject Win32_SerialPort | Select-Object Name,DeviceID

# Example with PuTTY:
putty -serial COM3 -sercfg 115200,8,n,1,N
```

**Expected BIOS Output:**
```
        __   _ __      _  __
       / /  (_) /____ | |/_/
      / /__/ / __/ -_)>  <
     /____/_/\__/\__/_/|_|
   Build your hardware, easily!

 (c) Copyright 2012-2025 Enjoy-Digital
 (c) Copyright 2007-2015 M-Labs

 BIOS built on Dec  6 2025 21:23:45
 BIOS CRC passed (00000000)

--=============== SoC ==================--
CPU:            VexRiscv_Linux @ 50MHz
BUS:            WISHBONE 32-bit @ 4.0GiB
CSR:            32-bit data
ROM:            24KiB
SRAM:           8KiB
MAIN-RAM:       32KiB

--============== Boot ==================--
Booting from serial...
Press Q or ESC to abort boot completely.
sL5DdSMmkekro
[LXTERM] Received firmware download request from the device.
[LXTERM] Uploading kernel to 0x40000000 (xxxxx bytes)...
[LXTERM] Upload complete (x.xKB/s).
[LXTERM] Booting the device.
[LXTERM] Done.
Executing booted program at 0x40000000

--============= Liftoff! ===============--
```

## Step 4: Verify LED Activity
- LEDs should chase in sequence (default behavior)
- Press CPU reset button to restart BIOS

## Alternative: OpenFPGALoader (Faster)
```bash
# In WSL (if openFPGALoader installed):
wsl -e bash -lc "openFPGALoader -b arty /mnt/c/CoPilot_Cli/SNN/build/digilent_arty/gateware/digilent_arty.bit"
```

## Troubleshooting

### Synthesis Fails
- **Error: License issue** → Ensure Vivado WebPACK license activated
- **Error: Path not found** → Check `digilent_arty.tcl` references in generated script
- **Error: Out of memory** → Close other applications; increase Windows page file

### JTAG Not Found
```powershell
# Install Digilent Adept Runtime or Vivado drivers
# Check Device Manager → Universal Serial Bus controllers
# Should see "Digilent USB Device"
```

### No UART Output
- Check Device Manager for COM port number
- Verify USB cable (some are power-only)
- Try different USB port (USB 2.0 may be more stable)
- Check solder jumpers on board (JP1 should be shorted for UART)

## Next: Linux Kernel Boot
See `docs/wp04/linux_boot_guide.md` (to be created) for:
- Buildroot configuration for RV32IMA
- Kernel compilation
- Boot via TFTP or SPI flash
- Root filesystem setup

## Resource Monitoring
After synthesis, check utilization vs. target:
```
Target Headroom for SNN Accelerator:
- LUTs: Reserve ~40% (8,000 / 20,800)
- FFs: Reserve ~40% (16,640 / 41,600)
- BRAM: Reserve ~40% (20 / 50 blocks)
- DSPs: Reserve for multiply-accumulate (MAC) operations
```

## Build Time Reference
| Step | Duration | Notes |
|------|----------|-------|
| Verilog generation | ~60s | Already completed |
| Vivado synthesis | ~10-15min | Depends on host CPU |
| Implementation | ~10-15min | Place & route |
| Bitstream generation | ~2min | Final step |
| **Total** | **~25-35min** | First build |

## Files of Interest
- **RTL:** `digilent_arty.v` (top-level design)
- **Constraints:** `digilent_arty.xdc` (pin assignments, timing)
- **TCL:** `digilent_arty.tcl` (Vivado project script)
- **Memory Init:** `*_init` files (ROM/RAM content)
- **CSR Map:** `../csr.csv` (register addresses for drivers)
