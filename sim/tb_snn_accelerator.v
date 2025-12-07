// Testbench for SNN Accelerator Top Module
// Tests CSR access, FIFO operations, and basic control flow

`timescale 1ns / 1ps

module tb_snn_accelerator;

    // Clock and reset
    reg clk;
    reg rst;
    
    // Wishbone interface signals
    reg [31:0] wb_adr_i;
    reg [31:0] wb_dat_i;
    wire [31:0] wb_dat_o;
    reg wb_we_i;
    reg wb_stb_i;
    reg wb_cyc_i;
    wire wb_ack_o;
    
    // DMA interface (unused in this test)
    wire [31:0] dma_adr_o;
    wire [31:0] dma_dat_o;
    reg [31:0] dma_dat_i;
    wire dma_we_o;
    wire dma_stb_o;
    wire dma_cyc_o;
    reg dma_ack_i;
    
    // Interrupt
    wire irq;
    
    // Instantiate DUT
    snn_accelerator_top #(
        .NEURON_WIDTH(16),
        .WEIGHT_WIDTH(8),
        .FIFO_DEPTH(256),
        .MAX_NEURONS(1024)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wb_adr_i(wb_adr_i),
        .wb_dat_i(wb_dat_i),
        .wb_dat_o(wb_dat_o),
        .wb_we_i(wb_we_i),
        .wb_stb_i(wb_stb_i),
        .wb_cyc_i(wb_cyc_i),
        .wb_ack_o(wb_ack_o),
        .dma_adr_o(dma_adr_o),
        .dma_dat_o(dma_dat_o),
        .dma_dat_i(dma_dat_i),
        .dma_we_o(dma_we_o),
        .dma_stb_o(dma_stb_o),
        .dma_cyc_o(dma_cyc_o),
        .dma_ack_i(dma_ack_i),
        .irq(irq)
    );
    
    // Clock generation: 50MHz (20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // CSR Write Task
    task wb_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            wb_adr_i = addr;
            wb_dat_i = data;
            wb_we_i = 1;
            wb_stb_i = 1;
            wb_cyc_i = 1;
            @(posedge clk);
            wait(wb_ack_o);
            @(posedge clk);
            wb_stb_i = 0;
            wb_cyc_i = 0;
            wb_we_i = 0;
        end
    endtask
    
    // CSR Read Task
    task wb_read;
        input [31:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            wb_adr_i = addr;
            wb_we_i = 0;
            wb_stb_i = 1;
            wb_cyc_i = 1;
            @(posedge clk);
            wait(wb_ack_o);
            data = wb_dat_o;
            @(posedge clk);
            wb_stb_i = 0;
            wb_cyc_i = 0;
        end
    endtask
    
    // Test stimulus
    reg [31:0] read_data;
    integer i;
    
    initial begin
        // Initialize waveform dump
        $dumpfile("snn_accel_tb.vcd");
        $dumpvars(0, tb_snn_accelerator);
        
        // Initialize signals
        rst = 1;
        wb_adr_i = 0;
        wb_dat_i = 0;
        wb_we_i = 0;
        wb_stb_i = 0;
        wb_cyc_i = 0;
        dma_dat_i = 0;
        dma_ack_i = 0;
        
        // Reset
        #100;
        rst = 0;
        #100;
        
        $display("=== SNN Accelerator Testbench ===");
        $display("Time: %0t", $time);
        
        // Test 1: Read STATUS register (should be 0x02 = input FIFO empty)
        $display("\n[TEST 1] Reading STATUS register");
        wb_read(32'h04, read_data);
        $display("  STATUS = 0x%08h (expected: input FIFO empty)", read_data);
        
        // Test 2: Write CONFIG register (enable accelerator)
        $display("\n[TEST 2] Enabling accelerator");
        wb_write(32'h00, 32'h00000001); // Set enable bit
        wb_read(32'h00, read_data);
        $display("  CONFIG = 0x%08h (enable bit should be set)", read_data);
        
        // Test 3: Write neuron count
        $display("\n[TEST 3] Setting neuron count to 256");
        wb_write(32'h14, 32'd256);
        wb_read(32'h14, read_data);
        $display("  NEURON_COUNT = %0d", read_data);
        
        // Test 4: Configure parameters
        $display("\n[TEST 4] Configuring neuron parameters");
        wb_write(32'h4C, 32'h00010000); // Threshold = 1.0 (16.16 fixed-point)
        wb_write(32'h50, 32'h00000100); // Leak rate = 1/256
        wb_write(32'h54, 32'd5);        // Refractory = 5 cycles
        
        wb_read(32'h4C, read_data);
        $display("  THRESHOLD = 0x%08h", read_data);
        wb_read(32'h50, read_data);
        $display("  LEAK_RATE = 0x%08h", read_data);
        wb_read(32'h54, read_data);
        $display("  REFRACTORY = %0d cycles", read_data);
        
        // Test 5: Push spikes to input FIFO
        $display("\n[TEST 5] Pushing spikes to input FIFO");
        for (i = 0; i < 10; i = i + 1) begin
            wb_write(32'h20, {16'd0, 16'(i)}); // Spike data: neuron_id = i
            $display("  Pushed spike %0d", i);
        end
        
        // Test 6: Check FIFO status
        $display("\n[TEST 6] Checking FIFO status");
        wb_read(32'h24, read_data);
        $display("  FIFO_IN_STATUS = 0x%08h", read_data);
        $display("    Level = %0d", read_data[7:0]);
        $display("    Full = %0d", read_data[16]);
        $display("    Empty = %0d", read_data[17]);
        
        // Test 7: Start computation
        $display("\n[TEST 7] Starting computation");
        wb_write(32'h08, 32'h01); // Send START command
        
        // Wait for some processing
        #1000;
        
        // Test 8: Check timestep counter
        $display("\n[TEST 8] Checking timestep counter");
        wb_read(32'h18, read_data);
        $display("  TIMESTEP = %0d", read_data);
        
        // Test 9: Check spike count
        wb_read(32'h1C, read_data);
        $display("  SPIKE_COUNT = %0d", read_data);
        
        // Test 10: Check output FIFO
        $display("\n[TEST 10] Checking output FIFO");
        wb_read(32'h2C, read_data);
        $display("  FIFO_OUT_STATUS = 0x%08h", read_data);
        if (!read_data[17]) begin // Not empty
            wb_read(32'h28, read_data);
            $display("  FIFO_OUT_DATA = 0x%08h", read_data);
        end
        
        // Test 11: Enable interrupts
        $display("\n[TEST 11] Enabling interrupts");
        wb_write(32'h0C, 32'h3F); // Enable all interrupts
        wb_read(32'h10, read_data);
        $display("  IRQ_STATUS = 0x%08h", read_data);
        $display("  IRQ line = %0d", irq);
        
        // Test 12: Stop computation
        $display("\n[TEST 12] Stopping computation");
        wb_write(32'h08, 32'h02); // Send STOP command
        
        // Test 13: Reset accelerator
        $display("\n[TEST 13] Resetting accelerator");
        wb_write(32'h08, 32'h08); // Send RESET command
        #100;
        
        wb_read(32'h18, read_data);
        $display("  TIMESTEP after reset = %0d (should be 0)", read_data);
        
        // Test 14: Verify FIFO flush
        $display("\n[TEST 14] Flushing FIFOs");
        wb_write(32'h08, 32'h20); // Send FIFO_FLUSH command
        #100;
        
        wb_read(32'h24, read_data);
        $display("  FIFO_IN_STATUS = 0x%08h (should be empty)", read_data);
        
        // Test complete
        #1000;
        $display("\n=== Test Complete ===");
        $display("Total simulation time: %0t ns", $time);
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #100000; // 100us timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    // Monitor key signals
    initial begin
        $monitor("Time=%0t rst=%b STATUS=0x%02h FIFO_IN_LEVEL=%0d IRQ=%b",
                 $time, rst, dut.status_reg[7:0], dut.fifo_in_level, irq);
    end

endmodule
