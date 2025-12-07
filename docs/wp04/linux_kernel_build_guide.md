# Linux Kernel Compilation Guide for Arty A7

## Overview
This guide details building a minimal Linux kernel for the VexRiscv CPU on Arty A7 using Buildroot.

## Prerequisites
- RISC-V cross-compiler installed (already done: `gcc-riscv64-unknown-elf`)
- Buildroot source tree
- ~5GB disk space for build artifacts
- 30-60 minutes build time (first run)

## Step 1: Clone and Configure Buildroot

```bash
cd /mnt/c/CoPilot_Cli/SNN/third_party
git clone https://github.com/buildroot/buildroot.git
cd buildroot
git checkout 2024.02.x  # Use stable release

# Start with minimal RISC-V configuration
make qemu_riscv32_virt_defconfig
```

## Step 2: Customize Configuration

```bash
make menuconfig
```

### Required Settings

#### Target Options
```
Target Architecture: RISCV
Target Architecture Variant: Custom
Target Architecture Size: 32-bit
Target ABI: ilp32
```

#### Toolchain
```
Toolchain type: External toolchain
Toolchain: Custom toolchain
Toolchain origin: Pre-installed toolchain
Toolchain path: /usr
Toolchain prefix: riscv64-unknown-elf-
External toolchain kernel headers: 6.1.x
```

#### Kernel
```
Kernel version: 6.1.x (LTS)
Kernel configuration: Using a custom config file
Custom kernel config file: $(TOPDIR)/configs/litex_vexriscv_defconfig
Kernel binary format: Image
Build a Device Tree Blob (DTB): YES
Device Tree Source file: arch/riscv/boot/dts/litex_vexriscv.dts
```

#### System Configuration
```
Root filesystem overlay: $(BR2_EXTERNAL)/board/litex/rootfs-overlay
Init system: BusyBox
/dev management: Dynamic using devtmpfs only
Enable root login with password: NO
Root password: (leave empty for passwordless)
System hostname: litex-snn
System banner: Welcome to LiteX SNN System
```

#### Target Packages
**Essential:**
- BusyBox (already selected)
- dropbear (SSH server) - Optional
- strace (debugging) - Optional

**Useful:**
- python3 (for user-space SNN tests)
- numpy (if enough space)
- kmod (kernel module utilities)

#### Filesystem Images
```
ext2/3/4 root filesystem: YES
  ext2/3/4 variant: ext4
  exact size: 32M
cpio root filesystem: YES (for initramfs)
  Compression method: gzip
tar root filesystem: YES (for backup)
```

## Step 3: Create Custom Kernel Config

```bash
mkdir -p configs
cat > configs/litex_vexriscv_defconfig << 'EOF'
CONFIG_RISCV=y
CONFIG_32BIT=y
CONFIG_ARCH_RV32I=y
CONFIG_MMU=y
CONFIG_SMP=n

# CPU features
CONFIG_RISCV_ISA_C=y
CONFIG_RISCV_ISA_A=y
CONFIG_FPU=n

# Platform
CONFIG_SOC_LITEX=y
CONFIG_LITEX_SOC_CONTROLLER=y

# Memory
CONFIG_FLATMEM=y
CONFIG_SPLIT_PTLOCK_CPUS=4
CONFIG_PHYS_ADDR_T_64BIT=n

# Drivers
CONFIG_SERIAL_LITEUART=y
CONFIG_SERIAL_LITEUART_CONSOLE=y
CONFIG_HW_RANDOM_LITEX=y

# Device Tree
CONFIG_OF=y
CONFIG_OF_EARLY_FLATTREE=y

# Disable unnecessary features
CONFIG_MODULES=n
CONFIG_BLK_DEV=n
CONFIG_NETWORK=n
CONFIG_WIRELESS=n
CONFIG_WLAN=n

# Enable debugging
CONFIG_DEBUG_KERNEL=y
CONFIG_PRINTK=y
CONFIG_EARLY_PRINTK=y
CONFIG_CONSOLE_LOGLEVEL_DEFAULT=7

# Initramfs
CONFIG_BLK_DEV_INITRD=y
CONFIG_INITRAMFS_SOURCE=""
CONFIG_INITRAMFS_COMPRESSION_GZIP=y
EOF
```

## Step 4: Create Device Tree

```bash
mkdir -p board/litex
cat > board/litex/litex_vexriscv.dts << 'EOF'
/dts-v1/;

/ {
    #address-cells = <1>;
    #size-cells = <1>;
    compatible = "litex,vexriscv";
    model = "LiteX VexRiscv on Arty A7";

    chosen {
        bootargs = "console=liteuart earlycon=liteuart,0xf0002000 rootwait root=/dev/ram0";
        stdout-path = &uart0;
    };

    cpus {
        #address-cells = <1>;
        #size-cells = <0>;
        timebase-frequency = <50000000>; // 50MHz

        cpu@0 {
            device_type = "cpu";
            compatible = "riscv";
            reg = <0>;
            riscv,isa = "rv32imac";
            mmu-type = "riscv,sv32";
            
            interrupt-controller {
                #interrupt-cells = <1>;
                compatible = "riscv,cpu-intc";
                interrupt-controller;
            };
        };
    };

    memory@40000000 {
        device_type = "memory";
        reg = <0x40000000 0x8000000>; // 128MB (adjust if using external DDR)
    };

    reserved-memory {
        #address-cells = <1>;
        #size-cells = <1>;
        ranges;

        // Reserve ROM area
        rom@0 {
            reg = <0x00000000 0x20000>;
            no-map;
        };
    };

    soc {
        #address-cells = <1>;
        #size-cells = <1>;
        compatible = "litex,soc", "simple-bus";
        ranges;

        uart0: serial@f0002000 {
            compatible = "litex,liteuart";
            reg = <0xf0002000 0x100>;
            interrupts = <0>;
            status = "okay";
        };

        timer0: timer@f0001800 {
            compatible = "litex,timer";
            reg = <0xf0001800 0x100>;
            interrupts = <1>;
        };

        snn_accel: snn@f0003000 {
            compatible = "litex,snn-accelerator";
            reg = <0xf0003000 0x100>;
            interrupts = <2>;
            status = "disabled"; // Enable after driver ready
        };
    };
};
EOF
```

## Step 5: Build

```bash
# Full build (30-60 minutes first time)
make -j$(nproc)

# Outputs will be in output/images/:
# - Image - Linux kernel
# - litex_vexriscv.dtb - Device tree blob
# - rootfs.cpio.gz - Root filesystem (initramfs)
# - rootfs.ext4 - Root filesystem (block device)
# - rootfs.tar - Root filesystem (for inspection)
```

## Step 6: Generate Boot Files for LiteX

```bash
# Combine kernel + initramfs + dtb into boot binary
cd output/images

# Create boot image
cat Image litex_vexriscv.dtb > boot.bin

# Convert to memory initialization format for LiteX
# (This requires litex/tools/litex_json2dts_linux.py)
cd /mnt/c/CoPilot_Cli/SNN/third_party/litex
python3 litex/soc/software/bios/boot.py \
    --kernel=../../buildroot/output/images/Image \
    --dtb=../../buildroot/output/images/litex_vexriscv.dtb \
    --rootfs=../../buildroot/output/images/rootfs.cpio.gz
```

## Step 7: Boot Options

### Option A: Serial Boot (Testing)
1. Program FPGA with LiteX bitstream
2. Connect to UART (115200 baud)
3. Interrupt BIOS autoboot
4. Send kernel via `litex_term`:
```bash
litex_term /dev/ttyUSB0 --kernel=boot.bin
```

### Option B: SPI Flash Boot (Persistent)
1. Flash kernel to SPI flash:
```bash
cd /mnt/c/CoPilot_Cli/SNN/build/digilent_arty
openFPGALoader -b arty -o 0x100000 boot.bin
```
2. Configure BIOS to boot from flash offset 0x100000

### Option C: TFTP Boot (Development)
1. Set up TFTP server on host
2. Configure BIOS network settings
3. Boot via `boot tftp`

## Troubleshooting

### Kernel Panic: No init found
- Verify initramfs included: `CONFIG_INITRAMFS_SOURCE`
- Check rootfs has /init or /sbin/init
- Verify busybox compiled with `CONFIG_INIT`

### UART Not Working
- Check device tree `stdout-path` points to correct UART
- Verify `console=liteuart` in kernel command line
- Ensure `CONFIG_SERIAL_LITEUART_CONSOLE=y`

### Kernel Too Large
- Disable modules: `CONFIG_MODULES=n`
- Remove drivers: Network, Block devices, Filesystems
- Use gzip compression: `CONFIG_KERNEL_GZIP=y`
- Target size: <4MB for comfortable fit

### Out of Memory
- Increase RAM allocation in LiteX SoC (use external DDR)
- Reduce initramfs size (minimal busybox config)
- Use external root filesystem on SD card

## Expected Output

```
[    0.000000] Linux version 6.1.x (buildroot@litex) ...
[    0.000000] Machine model: LiteX VexRiscv on Arty A7
[    0.000000] earlycon: liteuart0 at MMIO 0xf0002000
[    0.000000] printk: bootconsole [liteuart0] enabled
[    0.000000] Zone ranges:
[    0.000000]   Normal   [mem 0x40000000-0x47ffffff]
[    0.000000] Memory: 128MB available
[    0.050000] clocksource: riscv_clocksource: mask: 0xffffffff max_cycles: ...
[    0.060000] Console: colour dummy device 80x25
[    0.070000] Calibrating delay loop... 50.00 BogoMIPS
[    0.150000] pid_max: default: 32768 minimum: 301
[    0.160000] Mount-cache hash table entries: 1024
[    0.200000] devtmpfs: initialized
[    0.450000] liteuart f0002000.serial: ttyLXU0 at MMIO 0xf0002000 (irq = 0)
[    0.460000] printk: console [ttyLXU0] enabled
[    0.500000] Freeing unused kernel memory: 1024K
[    0.510000] Run /init as init process
Starting system initialization...
Welcome to LiteX SNN System

litex-snn login: root
# 
```

## Next Steps
- Build SNN accelerator kernel driver (`kernel/snn_accel.c`)
- Test driver with userspace tool (`user/snn_test.py`)
- Optimize kernel size for faster boot
- Add network support for remote testing

## Build Time Estimates
| Task | Duration | Notes |
|------|----------|-------|
| Buildroot download | 5-10 min | One-time |
| Kernel compilation | 10-20 min | Depends on CPU |
| Rootfs generation | 5-10 min | BusyBox, tools |
| **Total (first build)** | **20-40 min** | Parallel build |
| **Incremental rebuild** | **2-5 min** | After config changes |

## Disk Space Requirements
- Buildroot source: ~500MB
- Build artifacts: ~2-3GB
- Output images: ~50MB
- **Total:** ~3-4GB
