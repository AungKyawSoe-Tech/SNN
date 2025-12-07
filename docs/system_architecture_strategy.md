# System Architecture and Strategy

## Vision
Deliver a Linux-capable RISC-V SoC on the Digilent Arty A7 that hosts a spiking neural network (SNN) accelerator, supports real-time visualisation, and provides a path toward on-board or host-assisted training. The solution must remain portable to larger FPGA or ASIC targets without heavy rework.

## Layered Overview
- **Hardware Platform**: LiteX SoC, VexRiscv (MMU), DDR3, LiteEth, SPI flash, GPIO.
- **Acceleration Fabric**: SNN core with configurable neuron/synapse arrays, DMA engines, spike FIFOs, performance counters.
- **System Software**: OpenSBI + Linux kernel with `litex_snn` driver, lightweight rootfs (Buildroot), instrumentation daemons.
- **User Space**: Python tooling for control/visualisation, optional C++ microservices for streaming data, integration points for PyTorch/SpikingJelly.
- **Visualization & Training**: Web-based dashboard (Flask + WebSockets) for spike trains, latency, utilisation; offline training loops leveraging host GPU and emitting weight updates via driver APIs.

## SNN Dataflow
1. Host loads neuron/synapse state via DMA descriptors prepared by the driver.
2. Accelerator advances simulation epochs, pushing spike events to egress FIFO.
3. Driver surfaces spikes via character device or `ioctl`-backed mmap buffer.
4. User-space daemon aggregates spikes, updates visualisation, and optionally logs to file for training datasets.
5. Training loop (initially host-only) computes weight deltas and pushes updates back through DMA writes.

## Visualisation Plan
- **Metrics**: spike raster plots, firing rates, membrane potentials, DMA throughput.
- **Pipeline**:
  1. Kernel driver exposes mmap'ed ring buffer for spike events.
  2. Python daemon (`snn_viz.py`) consumes ring buffer, publishes via ZeroMQ/WebSocket.
  3. Frontend (React/Dash) renders live charts and alerts on saturation/overflows.
- **Milestones**:
  - M0: CLI-based textual monitoring (per-epoch summaries).
  - M1: Local matplotlib dashboard.
  - M2: Web dashboard served on-board or from host PC.

## Training Roadmap
- **Phase A**: Offline training in Python using recorded spikes (PyTorch + surrogate gradients). Weight updates injected through driver.
- **Phase B**: Incremental on-board learning loops using simplified STDP kernels inside accelerator.
- **Phase C**: Optional hybrid co-processing with host GPU/FPU modules for gradient computation.

## Portability Strategy
- **FPGA Targets**: Maintain LiteX configuration profiles for Arty A7, Nexys Video (Artix-7 200T), Zynq ZCU104 (UltraScale+), and Lattice ECP5. Abstract board-specific IO in LiteX board files.
- **ASIC/SoC**: Partition accelerator RTL into technology-agnostic modules, isolate Xilinx primitives behind wrapper packages. Adopt AXI4 interfaces to ease reuse.
- **Software Stack**: Keep driver aligned with Linux mainline requirements, avoid LiteX-specific APIs in user space, rely on device tree descriptions to port.

## Work Packages (Sequenced, Manageable Units)
1. **WP1: Gateware Baseline**
   - Build LiteX SoC with Linux image; capture utilisation/timing baseline.
2. **WP2: Accelerator Prototype**
   - Implement CSR + spike FIFOs; loopback validation via driver.
3. **WP3: Driver & Test Harness**
   - Extend `litex_snn` with `ioctl`/mmap interfaces; expand `snn_test.py`.
4. **WP4: Visualisation MVP**
   - Develop CLI monitor, then matplotlib dashboard.
5. **WP5: Training Hooks**
   - Define weight update protocol; integrate Python training script.
6. **WP6: Portability Enablement**
   - Create board configuration matrix; validate synthesis on higher-capacity target.
7. **WP7: Optimisation Loop**
   - Apply timing/utilisation plan, document regressions, iterate floorplanning.

## Documentation & Traceability
- Each work package generates a dedicated engineering report in `docs/wpXX_*.md` capturing goals, changes, and validation results.
- Action logs appended to `001_prototype_litex_soc.md` to preserve chronological context.
- Architecture diagrams (ASCII/Graphviz) to be added in follow-up for knowledge transfer.
