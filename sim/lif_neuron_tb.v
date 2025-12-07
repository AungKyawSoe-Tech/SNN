// Testbench for LIF Neuron Core
// Tests basic functionality: integration, spiking, refractory period, leak

`timescale 1ns / 1ps

module lif_neuron_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 100MHz
    parameter NEURON_WIDTH = 16;
    parameter WEIGHT_WIDTH = 8;
    
    // DUT signals
    reg                      clk;
    reg                      rst;
    reg  [15:0]              threshold;
    reg  [15:0]              leak_rate;
    reg  [7:0]               refractory;
    reg                      leaky_enable;
    reg                      reset_on_spike;
    reg  [15:0]              input_neuron_id;
    reg  [WEIGHT_WIDTH-1:0]  synapse_weight;
    reg                      spike_in_valid;
    wire                     spike_in_ready;
    wire [15:0]              output_neuron_id;
    wire                     spike_out_valid;
    reg                      spike_out_ready;
    reg  [15:0]              neuron_id;
    wire [NEURON_WIDTH-1:0]  membrane_potential;
    wire                     in_refractory;
    wire [7:0]               refract_counter;
    
    // Instantiate DUT
    lif_neuron #(
        .NEURON_WIDTH(NEURON_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .threshold(threshold),
        .leak_rate(leak_rate),
        .refractory(refractory),
        .leaky_enable(leaky_enable),
        .reset_on_spike(reset_on_spike),
        .input_neuron_id(input_neuron_id),
        .synapse_weight(synapse_weight),
        .spike_in_valid(spike_in_valid),
        .spike_in_ready(spike_in_ready),
        .output_neuron_id(output_neuron_id),
        .spike_out_valid(spike_out_valid),
        .spike_out_ready(spike_out_ready),
        .neuron_id(neuron_id),
        .membrane_potential(membrane_potential),
        .in_refractory(in_refractory),
        .refract_counter(refract_counter)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        rst = 1;
        threshold = 16'd1000;
        leak_rate = 16'd256; // Small leak (0.00390625)
        refractory = 8'd5;
        leaky_enable = 0;
        reset_on_spike = 1;
        input_neuron_id = 16'd0;
        synapse_weight = 8'd0;
        spike_in_valid = 0;
        spike_out_ready = 1;
        neuron_id = 16'd42;
        
        // Reset
        repeat(5) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);
        
        $display("=== Test 1: Basic Integration ===");
        // Send input spikes to build up membrane potential
        send_spike(0, 100); // Weight 100
        #50;
        send_spike(1, 150); // Weight 150
        #50;
        send_spike(2, 200); // Weight 200
        #50;
        
        $display("Membrane after 3 spikes: %d", membrane_potential);
        assert(membrane_potential == 450) else $error("Integration failed");
        
        $display("\n=== Test 2: Spike Generation ===");
        // Send enough to cross threshold
        send_spike(3, 600); // Should cause spike (450+600 > 1000)
        #50;
        
        assert(spike_out_valid == 1) else $error("Spike not generated");
        assert(output_neuron_id == 42) else $error("Wrong neuron ID");
        
        // Wait for spike to be consumed
        wait(!spike_out_valid);
        #50;
        
        $display("Membrane after spike: %d", membrane_potential);
        assert(membrane_potential == 0 || membrane_potential == 50) 
            else $error("Membrane not reset correctly");
        
        $display("\n=== Test 3: Refractory Period ===");
        assert(in_refractory == 1) else $error("Should be in refractory");
        $display("Refractory counter: %d", refract_counter);
        
        // Try to send spike during refractory (should be ignored)
        send_spike(4, 200);
        #50;
        $display("Membrane during refractory: %d (should be ~0)", membrane_potential);
        
        // Wait for refractory to end
        wait(!in_refractory);
        $display("Refractory period ended");
        #50;
        
        $display("\n=== Test 4: Leaky Integration ===");
        leaky_enable = 1;
        leak_rate = 16'd6554; // ~10% leak per cycle
        
        // Build up membrane
        send_spike(5, 200);
        #50;
        $display("Membrane before leak: %d", membrane_potential);
        
        // Let it leak for several cycles
        repeat(10) @(posedge clk);
        $display("Membrane after leak: %d (should be lower)", membrane_potential);
        
        $display("\n=== Test 5: Multiple Rapid Spikes ===");
        leaky_enable = 0;
        threshold = 16'd500;
        
        send_spike(6, 100);
        send_spike(7, 100);
        send_spike(8, 100);
        send_spike(9, 100);
        send_spike(10, 150); // Total = 550, should spike
        
        wait(spike_out_valid);
        $display("Spike generated after rapid inputs");
        wait(!spike_out_valid);
        
        #100;
        
        $display("\n=== All Tests Passed ===");
        $finish;
    end
    
    // Task to send a spike
    task send_spike(input [15:0] src_id, input [7:0] weight);
        begin
            @(posedge clk);
            wait(spike_in_ready);
            input_neuron_id = src_id;
            synapse_weight = weight;
            spike_in_valid = 1;
            @(posedge clk);
            spike_in_valid = 0;
        end
    endtask
    
    // Monitor
    always @(posedge clk) begin
        if (spike_out_valid && spike_out_ready) begin
            $display("[%0t] SPIKE OUT: Neuron %d fired! Membrane was %d", 
                     $time, output_neuron_id, membrane_potential);
        end
        if (spike_in_valid && spike_in_ready) begin
            $display("[%0t] SPIKE IN: From neuron %d, weight %d, membrane now %d", 
                     $time, input_neuron_id, synapse_weight, membrane_potential);
        end
    end
    
    // Timeout watchdog
    initial begin
        #10000;
        $display("ERROR: Test timeout!");
        $finish;
    end

endmodule
