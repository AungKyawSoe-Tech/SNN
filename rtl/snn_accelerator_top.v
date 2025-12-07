// SNN Accelerator Top Module
// LiteX-compatible peripheral for Spiking Neural Network processing
// Implements Leaky Integrate-and-Fire (LIF) neuron model

module snn_accelerator_top #(
    parameter NEURON_WIDTH = 16,      // Membrane potential bit width
    parameter WEIGHT_WIDTH = 8,       // Synaptic weight bit width
    parameter FIFO_DEPTH = 256,       // Spike FIFO depth
    parameter MAX_NEURONS = 1024      // Maximum network size
)(
    // System signals
    input  wire        clk,
    input  wire        rst,
    
    // Wishbone bus interface (slave)
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output reg         wb_ack_o,
    
    // DMA interface (master)
    output reg  [31:0] dma_adr_o,
    output reg  [31:0] dma_dat_o,
    input  wire [31:0] dma_dat_i,
    output reg         dma_we_o,
    output reg         dma_stb_o,
    output reg         dma_cyc_o,
    input  wire        dma_ack_i,
    
    // Interrupt output
    output wire        irq
);

    //=======================================================================
    // CSR Addresses (offset from peripheral base)
    //=======================================================================
    localparam ADDR_CONFIG         = 8'h00;
    localparam ADDR_STATUS         = 8'h04;
    localparam ADDR_CONTROL        = 8'h08;
    localparam ADDR_IRQ_MASK       = 8'h0C;
    localparam ADDR_IRQ_STATUS     = 8'h10;
    localparam ADDR_NEURON_COUNT   = 8'h14;
    localparam ADDR_TIMESTEP       = 8'h18;
    localparam ADDR_SPIKE_COUNT    = 8'h1C;
    localparam ADDR_FIFO_IN_DATA   = 8'h20;
    localparam ADDR_FIFO_IN_STATUS = 8'h24;
    localparam ADDR_FIFO_OUT_DATA  = 8'h28;
    localparam ADDR_FIFO_OUT_STATUS= 8'h2C;
    localparam ADDR_DMA_SRC        = 8'h30;
    localparam ADDR_DMA_DST        = 8'h34;
    localparam ADDR_DMA_LENGTH     = 8'h38;
    localparam ADDR_DMA_CONTROL    = 8'h3C;
    localparam ADDR_DMA_STATUS     = 8'h40;
    localparam ADDR_WEIGHT_BASE    = 8'h44;
    localparam ADDR_STATE_BASE     = 8'h48;
    localparam ADDR_THRESHOLD      = 8'h4C;
    localparam ADDR_LEAK_RATE      = 8'h50;
    localparam ADDR_REFRACTORY     = 8'h54;
    localparam ADDR_DEBUG_0        = 8'h58;
    localparam ADDR_DEBUG_1        = 8'h5C;

    //=======================================================================
    // CSR Registers
    //=======================================================================
    reg [31:0] config_reg;
    reg [31:0] control_reg;
    reg [31:0] irq_mask_reg;
    reg [31:0] irq_status_reg;
    reg [31:0] neuron_count_reg;
    reg [31:0] timestep_reg;
    reg [31:0] spike_count_reg;
    reg [31:0] dma_src_reg;
    reg [31:0] dma_dst_reg;
    reg [31:0] dma_length_reg;
    reg [31:0] weight_base_reg;
    reg [31:0] state_base_reg;
    reg [31:0] threshold_reg;
    reg [31:0] leak_rate_reg;
    reg [31:0] refractory_reg;

    //=======================================================================
    // Status Signals
    //=======================================================================
    wire fifo_in_full, fifo_in_empty;
    wire fifo_out_full, fifo_out_empty;
    wire [7:0] fifo_in_level, fifo_out_level;
    wire compute_active;
    wire dma_busy;
    
    wire [31:0] status_reg = {
        8'h0,                    // [31:24] Reserved
        8'h0,                    // [23:16] Error code
        dma_busy,                // [7] DMA busy
        1'b0,                    // [6] FIFO overflow
        1'b0,                    // [5] FIFO underflow
        compute_active,          // [4] Compute active
        fifo_out_empty,          // [3] Output empty
        fifo_out_full,           // [2] Output full
        fifo_in_empty,           // [1] Input empty
        fifo_in_full             // [0] Input full
    };

    //=======================================================================
    // FIFO Instances
    //=======================================================================
    wire [31:0] fifo_in_din, fifo_in_dout;
    wire fifo_in_wr, fifo_in_rd;
    
    wire [31:0] fifo_out_din, fifo_out_dout;
    wire fifo_out_wr, fifo_out_rd;

    // Input spike FIFO
    spike_fifo #(
        .DATA_WIDTH(32),
        .DEPTH(FIFO_DEPTH)
    ) spike_fifo_in_inst (
        .clk(clk),
        .rst(rst),
        .din(fifo_in_din),
        .wr_en(fifo_in_wr),
        .dout(fifo_in_dout),
        .rd_en(fifo_in_rd),
        .full(fifo_in_full),
        .empty(fifo_in_empty),
        .level(fifo_in_level)
    );

    // Output spike FIFO
    spike_fifo #(
        .DATA_WIDTH(32),
        .DEPTH(FIFO_DEPTH)
    ) spike_fifo_out_inst (
        .clk(clk),
        .rst(rst),
        .din(fifo_out_din),
        .wr_en(fifo_out_wr),
        .dout(fifo_out_dout),
        .rd_en(fifo_out_rd),
        .full(fifo_out_full),
        .empty(fifo_out_empty),
        .level(fifo_out_level)
    );

    //=======================================================================
    // Wishbone CSR Interface
    //=======================================================================
    wire csr_access = wb_cyc_i && wb_stb_i;
    wire [7:0] csr_addr = wb_adr_i[7:0];
    
    always @(posedge clk) begin
        if (rst) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'h0;
            config_reg <= 32'h0;
            control_reg <= 32'h0;
            irq_mask_reg <= 32'h0;
            neuron_count_reg <= 32'd256; // Default network size
            threshold_reg <= 32'h00010000; // Default threshold
            leak_rate_reg <= 32'h00000100; // Default leak
            refractory_reg <= 32'd5;       // Default refractory period
        end else begin
            wb_ack_o <= csr_access && !wb_ack_o;
            
            // Read access
            if (csr_access && !wb_we_i) begin
                case (csr_addr)
                    ADDR_CONFIG:         wb_dat_o <= config_reg;
                    ADDR_STATUS:         wb_dat_o <= status_reg;
                    ADDR_CONTROL:        wb_dat_o <= control_reg;
                    ADDR_IRQ_MASK:       wb_dat_o <= irq_mask_reg;
                    ADDR_IRQ_STATUS:     wb_dat_o <= irq_status_reg;
                    ADDR_NEURON_COUNT:   wb_dat_o <= neuron_count_reg;
                    ADDR_TIMESTEP:       wb_dat_o <= timestep_reg;
                    ADDR_SPIKE_COUNT:    wb_dat_o <= spike_count_reg;
                    ADDR_FIFO_IN_STATUS: wb_dat_o <= {16'h0, fifo_in_level, 6'h0, fifo_in_full, fifo_in_empty};
                    ADDR_FIFO_OUT_DATA:  wb_dat_o <= fifo_out_dout;
                    ADDR_FIFO_OUT_STATUS:wb_dat_o <= {16'h0, fifo_out_level, 6'h0, fifo_out_full, fifo_out_empty};
                    ADDR_DMA_SRC:        wb_dat_o <= dma_src_reg;
                    ADDR_DMA_DST:        wb_dat_o <= dma_dst_reg;
                    ADDR_DMA_LENGTH:     wb_dat_o <= dma_length_reg;
                    ADDR_DMA_STATUS:     wb_dat_o <= {31'h0, dma_busy};
                    ADDR_WEIGHT_BASE:    wb_dat_o <= weight_base_reg;
                    ADDR_STATE_BASE:     wb_dat_o <= state_base_reg;
                    ADDR_THRESHOLD:      wb_dat_o <= threshold_reg;
                    ADDR_LEAK_RATE:      wb_dat_o <= leak_rate_reg;
                    ADDR_REFRACTORY:     wb_dat_o <= refractory_reg;
                    default:             wb_dat_o <= 32'hDEADBEEF;
                endcase
            end
            
            // Write access
            if (csr_access && wb_we_i && !wb_ack_o) begin
                case (csr_addr)
                    ADDR_CONFIG:       config_reg <= wb_dat_i;
                    ADDR_CONTROL:      control_reg <= wb_dat_i;
                    ADDR_IRQ_MASK:     irq_mask_reg <= wb_dat_i;
                    ADDR_IRQ_STATUS:   irq_status_reg <= irq_status_reg & ~wb_dat_i; // W1C
                    ADDR_NEURON_COUNT: neuron_count_reg <= wb_dat_i;
                    ADDR_FIFO_IN_DATA: ; // Handled by FIFO logic
                    ADDR_DMA_SRC:      dma_src_reg <= wb_dat_i;
                    ADDR_DMA_DST:      dma_dst_reg <= wb_dat_i;
                    ADDR_DMA_LENGTH:   dma_length_reg <= wb_dat_i;
                    ADDR_DMA_CONTROL:  ; // Handled by DMA logic
                    ADDR_WEIGHT_BASE:  weight_base_reg <= wb_dat_i;
                    ADDR_STATE_BASE:   state_base_reg <= wb_dat_i;
                    ADDR_THRESHOLD:    threshold_reg <= wb_dat_i;
                    ADDR_LEAK_RATE:    leak_rate_reg <= wb_dat_i;
                    ADDR_REFRACTORY:   refractory_reg <= wb_dat_i;
                endcase
            end
        end
    end

    // FIFO write control
    assign fifo_in_wr = csr_access && wb_we_i && (csr_addr == ADDR_FIFO_IN_DATA);
    assign fifo_in_din = wb_dat_i;
    
    // FIFO read control
    assign fifo_out_rd = csr_access && !wb_we_i && (csr_addr == ADDR_FIFO_OUT_DATA);

    //=======================================================================
    // Control Logic
    //=======================================================================
    wire enable = config_reg[0];
    wire cmd_start = control_reg[0];
    wire cmd_stop = control_reg[1];
    wire cmd_reset = control_reg[3];
    
    assign compute_active = enable && !fifo_in_empty;

    //=======================================================================
    // Interrupt Generation
    //=======================================================================
    assign irq = |(irq_status_reg & irq_mask_reg);

    //=======================================================================
    // Placeholder for neuron computation pipeline
    //=======================================================================
    // TODO: Implement LIF neuron core
    // TODO: Implement synapse weight lookup
    // TODO: Implement DMA controller
    
    assign dma_busy = 1'b0; // Placeholder

endmodule
