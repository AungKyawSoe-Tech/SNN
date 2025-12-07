# SNN Accelerator Simulation Makefile
# Supports both neuron-only and full accelerator testing

# Simulator selection
SIM ?= iverilog  # Options: iverilog, verilator

# Source files
RTL_DIR = ../rtl
SIM_DIR = .

# RTL sources for full accelerator
RTL_SRCS_FULL = $(RTL_DIR)/spike_fifo.v \
                $(RTL_DIR)/lif_neuron.v \
                $(RTL_DIR)/snn_accelerator_top.v

# RTL sources for neuron only
RTL_SRCS_NEURON = $(RTL_DIR)/lif_neuron.v

# Testbenches
TB_ACCEL = $(SIM_DIR)/tb_snn_accelerator.v
TB_NEURON = $(SIM_DIR)/tb_lif_neuron.v

# Output files
VVP_ACCEL = snn_accel.vvp
VVP_NEURON = lif_neuron.vvp
VCD_ACCEL = snn_accel_tb.vcd
VCD_NEURON = lif_neuron_tb.vcd

# Icarus Verilog settings
IVERILOG = iverilog
VVP = vvp
IVERILOG_FLAGS = -g2012 -Wall

# Verilator settings
VERILATOR = verilator
VERILATOR_FLAGS = --binary --timing -Wall -Wno-fatal

.PHONY: all clean sim sim_accel sim_neuron view help

# Default: run full accelerator test
all: sim_accel

# Full accelerator simulation
sim_accel: $(VVP_ACCEL)
	@echo "=== Running SNN Accelerator Simulation ==="
	$(VVP) $(VVP_ACCEL)
	@echo "=== Simulation Complete. Waveform: $(VCD_ACCEL) ==="

$(VVP_ACCEL): $(RTL_SRCS_FULL) $(TB_ACCEL)
	@echo "=== Compiling Accelerator Testbench ==="
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ $(RTL_SRCS_FULL) $(TB_ACCEL)

# Neuron-only simulation
sim_neuron: $(VVP_NEURON)
	@echo "=== Running LIF Neuron Simulation ==="
	$(VVP) $(VVP_NEURON)
	@echo "=== Simulation Complete. Waveform: $(VCD_NEURON) ==="

$(VVP_NEURON): $(RTL_SRCS_NEURON) $(TB_NEURON)
	@echo "=== Compiling Neuron Testbench ==="
	$(IVERILOG) $(IVERILOG_FLAGS) -o $@ $(RTL_SRCS_NEURON) $(TB_NEURON)

# View waveforms (GTKWave)
view: $(VCD_ACCEL)
	@echo "=== Launching GTKWave ==="
	gtkwave $(VCD_ACCEL) &

view_neuron: $(VCD_NEURON)
	@echo "=== Launching GTKWave for Neuron ==="
	gtkwave $(VCD_NEURON) &

# Syntax check only
check:
	@echo "=== Syntax Check: Accelerator ==="
	$(IVERILOG) $(IVERILOG_FLAGS) -tnull $(RTL_SRCS_FULL) $(TB_ACCEL)
	@echo "=== Syntax OK ==="

check_neuron:
	@echo "=== Syntax Check: Neuron ==="
	$(IVERILOG) $(IVERILOG_FLAGS) -tnull $(RTL_SRCS_NEURON) $(TB_NEURON)
	@echo "=== Syntax OK ==="

# Clean build artifacts
clean:
	@echo "=== Cleaning Simulation Artifacts ==="
	rm -f $(VVP_ACCEL) $(VVP_NEURON) $(VCD_ACCEL) $(VCD_NEURON)
	rm -rf obj_dir/
	rm -f *.log *.vcd *.vvp
	@echo "=== Clean Complete ==="

# Help
help:
	@echo "SNN Accelerator Simulation Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Run full accelerator test (default)"
	@echo "  sim_accel    - Simulate full SNN accelerator"
	@echo "  sim_neuron   - Simulate LIF neuron only"
	@echo "  view         - View accelerator waveform in GTKWave"
	@echo "  view_neuron  - View neuron waveform in GTKWave"
	@echo "  check        - Syntax check accelerator"
	@echo "  check_neuron - Syntax check neuron"
	@echo "  clean        - Remove build artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  make              # Run accelerator test"
	@echo "  make sim_neuron   # Test neuron only"
	@echo "  make view         # View waveforms"
	@echo "  help           - Show this help"
	@echo ""
	@echo "Usage:"
	@echo "  make sim       - Run test"
	@echo "  make wave      - View results"
