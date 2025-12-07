// Simple synchronous FIFO for spike buffering
// Used for both input and output spike queues

module spike_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                  clk,
    input  wire                  rst,
    
    // Write interface
    input  wire [DATA_WIDTH-1:0] din,
    input  wire                  wr_en,
    output wire                  full,
    
    // Read interface
    output wire [DATA_WIDTH-1:0] dout,
    input  wire                  rd_en,
    output wire                  empty,
    
    // Status
    output wire [7:0]            level
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Pointers
    reg [ADDR_WIDTH:0] wr_ptr;
    reg [ADDR_WIDTH:0] rd_ptr;
    
    // Status signals
    wire [ADDR_WIDTH:0] fifo_count = wr_ptr - rd_ptr;
    assign full = (fifo_count == DEPTH);
    assign empty = (fifo_count == 0);
    assign level = (fifo_count > 255) ? 8'd255 : fifo_count[7:0];
    
    // Read data
    assign dout = mem[rd_ptr[ADDR_WIDTH-1:0]];
    
    // Write logic
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    // Read logic
    always @(posedge clk) begin
        if (rst) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

endmodule
