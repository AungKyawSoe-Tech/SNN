"""
SNN Accelerator LiteX Integration
Adds Spiking Neural Network peripheral to LiteX SoC
"""

from migen import *
from litex.soc.interconnect.csr import *
from litex.soc.interconnect import wishbone
from litex.soc.integration.doc import AutoDoc, ModuleDoc


class SNNAccelerator(Module, AutoCSR, AutoDoc):
    """Spiking Neural Network Hardware Accelerator
    
    Implements a Leaky Integrate-and-Fire (LIF) neuron array with
    configurable network topology, spike routing via FIFOs, and
    DMA-based state/weight memory access.
    """
    
    def __init__(self, platform, neuron_width=16, weight_width=8, 
                 fifo_depth=256, max_neurons=1024):
        self.intro = ModuleDoc("""SNN Accelerator Integration
        
        This module provides a memory-mapped interface to control and
        monitor a hardware-accelerated spiking neural network. It includes:
        - Dual FIFOs for spike ingress/egress
        - Configurable LIF neuron parameters
        - DMA engine for bulk memory operations
        - Interrupt generation for events
        
        Base address: 0xf0003000 (CSR location 5)
        """)
        
        # Control/Status Registers
        self.config = CSRStorage(32, name="config", description="""
            Global Configuration Register
            [0]: Enable - Global accelerator enable
            [1]: Reset on spike - Clear membrane potential after spike
            [2]: Leaky integrate - Enable membrane leak
            [3]: DMA enable - Enable DMA engine
            [7:4]: Datapath width (RO) - Bit width of computation
            [15:8]: FIFO depth log2 (RO) - Log2 of FIFO depth
        """)
        
        self.status = CSRStatus(32, name="status", description="""
            Status Register (Read-Only)
            [0]: FIFO input full
            [1]: FIFO input empty
            [2]: FIFO output full
            [3]: FIFO output empty
            [4]: Compute pipeline active
            [5]: FIFO input underflow
            [6]: FIFO output overflow
            [7]: DMA busy
            [15:8]: Last error code
        """)
        
        self.control = CSRStorage(8, name="control", description="""
            Control Command Register
            Write command byte:
            0x01: START - Begin spike processing
            0x02: STOP - Halt processing (graceful)
            0x04: ABORT - Emergency stop
            0x08: RESET - Reset all internal state
            0x10: SINGLE_STEP - Process one timestep
            0x20: FIFO_FLUSH - Clear all FIFOs
        """)
        
        self.irq_mask = CSRStorage(32, name="irq_mask", description="""
            Interrupt Mask Register
            [0]: Spike output available
            [1]: Computation timestep done
            [2]: DMA transfer complete
            [3]: Input FIFO below threshold
            [4]: Output FIFO above threshold
            [5]: Error condition
        """)
        
        self.irq_status = CSRStatus(32, name="irq_status", description="""
            Interrupt Status (Write-1-Clear)
            Same bit mapping as irq_mask
        """)
        
        # Network Configuration
        self.neuron_count = CSRStorage(32, name="neuron_count", 
            reset=256, description="Number of neurons in network")
        
        self.timestep = CSRStatus(32, name="timestep",
            description="Current simulation timestep counter")
        
        self.spike_count = CSRStatus(32, name="spike_count",
            description="Total spikes processed since last reset")
        
        # FIFO Interface
        self.fifo_in_data = CSRStorage(32, name="fifo_in_data",
            write_from_dev=True, description="Write spike to input FIFO")
        
        self.fifo_in_status = CSRStatus(32, name="fifo_in_status",
            description="Input FIFO status [7:0]=level, [16]=full, [17]=empty")
        
        self.fifo_out_data = CSRStatus(32, name="fifo_out_data",
            description="Read spike from output FIFO")
        
        self.fifo_out_status = CSRStatus(32, name="fifo_out_status",
            description="Output FIFO status [7:0]=level, [16]=full, [17]=empty")
        
        # DMA Configuration
        self.dma_src = CSRStorage(32, name="dma_src",
            description="DMA source address (neuron states or weights)")
        
        self.dma_dst = CSRStorage(32, name="dma_dst",
            description="DMA destination address")
        
        self.dma_length = CSRStorage(32, name="dma_length",
            description="DMA transfer length in bytes")
        
        self.dma_control = CSRStorage(8, name="dma_control",
            description="DMA control: 0x01=START, 0x02=ABORT")
        
        self.dma_status = CSRStatus(32, name="dma_status",
            description="DMA status: [0]=busy, [1]=done, [2]=error")
        
        # Network Parameters
        self.weight_base = CSRStorage(32, name="weight_base",
            description="Base address of synaptic weight memory")
        
        self.state_base = CSRStorage(32, name="state_base",
            description="Base address of neuron state memory")
        
        self.threshold = CSRStorage(32, name="threshold", reset=0x00010000,
            description="Global spike threshold (signed 16.16 fixed-point)")
        
        self.leak_rate = CSRStorage(32, name="leak_rate", reset=0x00000100,
            description="Membrane leak rate (0.16 fixed-point)")
        
        self.refractory = CSRStorage(32, name="refractory", reset=5,
            description="Refractory period in timesteps")
        
        # Debug registers
        self.debug_0 = CSRStatus(32, name="debug_0",
            description="Debug register 0 - internal state visibility")
        
        self.debug_1 = CSRStatus(32, name="debug_1",
            description="Debug register 1 - pipeline counters")
        
        # Interrupt line
        self.irq = Signal()
        
        # Instantiate Verilog module
        self.specials += Instance("snn_accelerator_top",
            # Parameters
            p_NEURON_WIDTH = neuron_width,
            p_WEIGHT_WIDTH = weight_width,
            p_FIFO_DEPTH = fifo_depth,
            p_MAX_NEURONS = max_neurons,
            
            # System
            i_clk = ClockSignal(),
            i_rst = ResetSignal(),
            
            # Wishbone CSR interface
            i_wb_adr_i = Cat(Signal(2), self._csr_address()),
            i_wb_dat_i = self._csr_wdata(),
            o_wb_dat_o = self._csr_rdata(),
            i_wb_we_i = self._csr_we(),
            i_wb_stb_i = self._csr_stb(),
            i_wb_cyc_i = self._csr_cyc(),
            o_wb_ack_o = self._csr_ack(),
            
            # DMA interface (TODO: connect to wishbone master)
            o_dma_adr_o = Signal(32),
            o_dma_dat_o = Signal(32),
            i_dma_dat_i = Signal(32),
            o_dma_we_o = Signal(),
            o_dma_stb_o = Signal(),
            o_dma_cyc_o = Signal(),
            i_dma_ack_i = Signal(),
            
            # Interrupt
            o_irq = self.irq
        )
        
        # Add Verilog sources
        platform.add_source("rtl/snn_accelerator_top.v")
        platform.add_source("rtl/spike_fifo.v")
    
    def _csr_address(self):
        """Extract CSR address from wishbone"""
        # TODO: Implement proper CSR address extraction
        return Signal(8)
    
    def _csr_wdata(self):
        return Signal(32)
    
    def _csr_rdata(self):
        return Signal(32)
    
    def _csr_we(self):
        return Signal()
    
    def _csr_stb(self):
        return Signal()
    
    def _csr_cyc(self):
        return Signal()
    
    def _csr_ack(self):
        return Signal()


def add_snn_accelerator(soc, **kwargs):
    """Helper function to add SNN accelerator to LiteX SoC
    
    Usage in platform file:
        from rtl.snn_accel_litex import add_snn_accelerator
        add_snn_accelerator(soc, neuron_width=16, fifo_depth=512)
    """
    soc.submodules.snn_accel = SNNAccelerator(soc.platform, **kwargs)
    soc.add_csr("snn_accel")
    soc.add_interrupt("snn_accel")
    return soc.snn_accel
