# SNN Accelerator Interface Specification

## Objectives
Define the hardware/software interface for a spiking neural network (SNN) accelerator attached to the LiteX SoC, including configuration registers, spike data paths, and DMA interactions.

## Architectural Overview
- **Host CPU**: VexRiscv (LiteX) running Linux
- **Interconnect**: LiteX CSR bus for control/status, Wishbone/AXI-lite for memory-mapped DMA control
- **Accelerator Blocks**:
  - Neuron State Memory (BRAM/URAM)
  - Synapse Weight Memory (external DDR via DMA, optional on-chip cache)
  - Spike Ingress FIFO (receives spikes from host or external sensors)
  - Spike Egress FIFO (returns spikes/events to host)
  - DMA Engine (burst transfers of neuron/synapse data)

## Register Map (CSR Bus, 32-bit)
| Offset | Name              | Description |
|--------|-------------------|-------------|
| 0x00   | CTRL              | Bit[0]=enable, Bit[1]=soft reset, Bit[2]=irq enable |
| 0x04   | STATUS            | Bit[0]=busy, Bit[1]=error, Bit[2]=fifo overflow |
| 0x08   | EPOCH_LEN         | Simulation ticks per epoch |
| 0x0C   | NEURON_COUNT      | Number of active neurons |
| 0x10   | SYNAPSE_COUNT     | Number of active synapses |
| 0x14   | DMA_SRC_ADDR      | Source address for DMA read (host memory) |
| 0x18   | DMA_DST_ADDR      | Destination address for DMA write |
| 0x1C   | DMA_LEN           | Transfer length in bytes |
| 0x20   | DMA_CMD           | Bit[0]=start read, Bit[1]=start write |
| 0x24   | IRQ_STATUS        | Bit[0]=epoch complete, Bit[1]=dma done, write-one-to-clear |
| 0x28   | SPIKE_IN_LEVEL    | Depth of ingress FIFO |
| 0x2C   | SPIKE_OUT_LEVEL   | Depth of egress FIFO |

## DMA Transactions
- **Neuron State Load**: Host populates neuron state buffers in DDR, configures DMA to load into accelerator BRAM prior to simulation start.
- **Synapse Weight Fetch**: Host streams synapse blocks into local cache as needed; accelerator triggers DMA reads autonomously via descriptor queue.
- **Spike Logging**: Egress FIFO optionally flushed via DMA to host memory for batch processing.

## Interrupt Strategy
- Primary IRQ line routed to LiteX interrupt controller
- IRQ sources: epoch complete, DMA completion, error
- Driver uses interrupt to wake user-space poll loops, reducing busy-waiting on CSR registers.

## Data Formats
- **Spike Packet (Ingress/Egress)**:
  - Bits[0:15]: neuron ID
  - Bits[16:27]: timestamp delta (12 bits)
  - Bits[28:31]: flags (e.g., inhibitory/excitatory)
- **Neuron State**:
  - Membrane potential (Q1.15 fixed point)
  - Refractory counter (8 bits)
  - Threshold (Q1.15)
- **Synapse Entry**:
  - Pre-neuron ID (16 bits)
  - Weight (Q1.15)
  - Delay slots (8 bits)

## LiteX Integration Notes
- Expose CSR region via LiteX-generated header for driver consumption (`csr.h`)
- Tie DMA engine to LiteX crossbar for access to system DDR
- Provide optional AXI-stream bridge for external sensor interfaces

## Verification Hooks
- Loopback mode to route ingress spikes directly to egress FIFO for driver sanity tests
- CSR-accessible performance counters (cycles per epoch, DMA stalls)

## Open Items
- Define maximum neuron/synapse counts supported within Artix-7 resource limits
- Decide whether synapse weights reside primarily on-chip or in external DDR
- Determine precision (fixed vs floating) for neuron update arithmetic
