# SNN Accelerator Simulation Suite

## Overview
This directory contains simulation testbenches and infrastructure for the SNN Accelerator project.

## Directory Structure
```
sim/
├── Makefile                    # Icarus Verilog simulation targets
├── tb_snn_accelerator.v        # Full accelerator testbench
├── tb_lif_neuron.v             # Neuron core unit test
├── README_sim.md               # This file
└── results/                    # Simulation outputs (VCD, logs)
```

## Prerequisites
- **Icarus Verilog** (iverilog, vvp): Install from http://iverilog.icarus.com/
  ```powershell
  # Windows: Download installer from website
  # Or use Chocolatey: choco install iverilog
  ```
- **GTKWave** (optional, for waveform viewing): https://gtkwave.sourceforge.net/

## Simulation Targets

### Full Accelerator Simulation
Tests the complete SNN accelerator with Wishbone interface, CSRs, FIFOs, and control logic.

```bash
cd sim
make all              # Compile and run accelerator testbench
make view             # Open waveforms in GTKWave
```

**Test Coverage:**
- Wishbone CSR read/write operations
- Configuration register access
- Input/output FIFO push/pop
- Control commands (START, STOP, RESET, FLUSH)
- Interrupt generation
- Status register updates

**Expected Output:**
```
=== SNN Accelerator Testbench ===
[TEST 1] Reading STATUS register
  STATUS = 0x00000002 (expected: input FIFO empty)
[TEST 2] Enabling accelerator
  CONFIG = 0x00000001 (enable bit should be set)
...
[TEST 13] Resetting accelerator
  TIMESTEP after reset = 0 (should be 0)
=== Test Complete ===
Total simulation time: 23450 ns
```

### Neuron Core Simulation
Tests the LIF neuron computation module in isolation.

```bash
cd sim
make sim_neuron       # Run neuron testbench
```

**Test Coverage:**
- Membrane potential integration
- Spike threshold detection
- Refractory period enforcement
- Leak rate dynamics

## Simulation Waveforms

### Viewing in GTKWave
```bash
# After running simulation:
make view

# Manual invocation:
gtkwave snn_accel_tb.vcd &
```

**Key Signals to Monitor:**
- `clk`, `rst` - Clock and reset
- `wb_*` - Wishbone bus transactions
- `dut.status_reg` - Accelerator status
- `dut.fifo_in_*` - Input FIFO state
- `dut.fifo_out_*` - Output FIFO state
- `irq` - Interrupt line

## Common Issues

### Issue: `iverilog: command not found`
**Solution:** Install Icarus Verilog:
```powershell
# Windows (Chocolatey):
choco install iverilog

# Or download from: http://bleyer.org/icarus/
```

### Issue: Module not found errors
**Solution:** Ensure all RTL dependencies exist:
```bash
ls ../rtl/spike_fifo.v
ls ../rtl/lif_neuron.v
ls ../rtl/snn_accelerator_top.v
```

### Issue: VCD file not generated
**Solution:** Check testbench has `$dumpfile()` and `$dumpvars()` calls:
```verilog
initial begin
    $dumpfile("snn_accel_tb.vcd");
    $dumpvars(0, tb_snn_accelerator);
end
```

## Adding New Tests

### 1. Create Testbench File
```verilog
// sim/tb_my_test.v
`timescale 1ns / 1ps
module tb_my_test;
    // Test logic here
endmodule
```

### 2. Add Makefile Target
```makefile
sim_my_test: tb_my_test.v $(RTL_SOURCES)
    iverilog -g2012 -o my_test.vvp $^
    vvp my_test.vvp
```

### 3. Run Simulation
```bash
make sim_my_test
```

## Performance Notes
- **Compile time:** 1-2 seconds for full accelerator
- **Simulation time:** <1 second for 100,000 ns
- **VCD file size:** ~500KB for full test suite

## Next Steps
1. Run full accelerator test: `make all`
2. View waveforms: `make view`
3. Add custom test stimulus in `tb_snn_accelerator.v`
4. Integrate with CI/CD pipeline for automated testing

## References
- Icarus Verilog Manual: http://iverilog.wikia.com/
- GTKWave Documentation: http://gtkwave.sourceforge.net/gtkwave.pdf
- Wishbone B4 Specification: https://opencores.org/howto/wishbone
