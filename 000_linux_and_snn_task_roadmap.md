# RISC-V with SNN Extensions Roadmap
## FPGA: Xilinx Artix-7 | Core: RISC-V VHDL | Goal: SNN Accelerator with Linux

## Phase 1: RISC-V Core Assessment & Preparation
### 1.1 Current Core Evaluation
- [ ] Analyze existing VHDL RISC-V implementation
- [ ] Verify RV32IMAC compliance (minimum for Linux)
- [ ] Check for existing extension mechanisms
- [ ] Identify free custom opcode space (major opcodes: 0x0B, 0x2B, etc.)

### 1.2 Development Environment Setup
- [ ] Install Vivado/Vitis 2023.1+
- [ ] Set up RISC-V toolchain (riscv-gnu-toolchain)
- [ ] Prepare simulation environment (Verilator/Questa)
- [ ] Create build automation scripts

## Phase 2: SNN ISA Extension Design
### 2.1 SNN Instruction Set Architecture
- [ ] Define custom instruction formats (R-type, I-type for SNN ops)
- [ ] Design neuron control instructions:
  ```vhdl
  -- Example instruction formats
  SNN.NEURON rd, rs1, rs2    -- Configure neuron parameters
  SNN.SPIKE rd, rs1          -- Generate spike output
  SNN.SYNAPSE rd, rs1, rs2   -- Configure synaptic weights
  SNN.POTENTIAL rd           -- Read membrane potential
  ```

### 2.2 Microarchitectural Hooks
- [ ] Map SNN custom ops to accelerator ports or issue queues
- [ ] Specify CSR interactions for neuron state snapshots
- [ ] Document privilege requirements for accelerator access

## Phase 3: LiteX SoC Bring-up
- [ ] Generate LiteX SoC for Arty A7 with VexRiscv Linux variant
- [ ] Validate DDR3 calibration and memory test in BIOS
- [ ] Boot Linux (LiteX Buildroot image) and capture console logs
- [ ] Archive bitstream, DTS, and boot artifacts

## Phase 4: Accelerator Integration
- [ ] Instantiate CSR block, spike FIFOs, and DMA in LiteX design
- [ ] Develop loopback self-test firmware
- [ ] Synthesize and compare resource/timing deltas vs. baseline
- [ ] Record findings in `docs/wp02_accelerator.md`

## Phase 5: Linux Software Stack
### 5.1 Kernel Support
- [ ] Extend `litex_snn` driver with char device + mmap ring buffer
- [ ] Implement IRQ-based epoch notifications
- [ ] Create device tree bindings and sample overlay
- [ ] Write kernel unit tests (KUnit or kunit-tool harness)

### 5.2 User Applications
- [ ] Expand `snn_test.py` to script DMA transfers and validation
- [ ] Build CLI monitoring tool for per-epoch stats
- [ ] Package utilities with setuptools/Poetry for reuse

## Phase 6: Visualisation & Training Enablement
- [ ] Implement Python daemon streaming spike data over WebSocket
- [ ] Develop plotting frontend (matplotlib then web dashboard)
- [ ] Define weight update protocol with JSON/YAML schema
- [ ] Integrate with PyTorch-based offline training pipeline
- [ ] Document workflow for generating and applying trained weights

## Phase 7: Portability & Optimisation
- [ ] Create LiteX board profiles for higher-capacity FPGAs
- [ ] Abstract vendor-specific RTL primitives with wrappers
- [ ] Port build scripts to CI (GitHub Actions or local runner)
- [ ] Apply timing/utilisation plan and track KPIs per build
- [ ] Draft migration checklist for ASIC or SoC targets