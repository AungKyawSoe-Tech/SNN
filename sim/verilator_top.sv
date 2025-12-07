// Placeholder SystemVerilog wrapper for NEORV32 core
// Replace with actual instantiation once VHDL sources are integrated via VHDL co-simulation.

module verilator_top;
    reg clk = 0;
    reg rstn = 0;

    wire uart_txd;
    reg  uart_rxd = 1'b1;

    always #5 clk = ~clk; // 100 MHz default

    initial begin
        repeat (20) @(posedge clk);
        rstn <= 1'b1;
    end

    // VHDL module instantiated via foreign module (placeholder)
    neorv32_top dut (
        .clk_i(clk),
        .rstn_i(rstn),
        .uart_txd(uart_txd),
        .uart_rxd(uart_rxd)
    );
endmodule
