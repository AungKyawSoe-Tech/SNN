// Leaky Integrate-and-Fire (LIF) Neuron Core
// Implements single neuron computation with configurable parameters

module lif_neuron #(
    parameter NEURON_WIDTH = 16,      // Membrane potential bit width
    parameter WEIGHT_WIDTH = 8,       // Synaptic weight bit width
    parameter THRESHOLD_WIDTH = 16,   // Threshold bit width
    parameter LEAK_WIDTH = 16         // Leak rate bit width (0.16 fixed-point)
)(
    input  wire                      clk,
    input  wire                      rst,
    
    // Configuration
    input  wire [THRESHOLD_WIDTH-1:0] threshold,      // Spike threshold
    input  wire [LEAK_WIDTH-1:0]      leak_rate,      // Membrane leak rate
    input  wire [7:0]                 refractory,     // Refractory period (cycles)
    input  wire                       leaky_enable,   // Enable leak
    input  wire                       reset_on_spike, // Reset membrane after spike
    
    // Input spike interface
    input  wire [15:0]                input_neuron_id, // Source neuron ID
    input  wire [WEIGHT_WIDTH-1:0]    synapse_weight,  // Weight for this connection
    input  wire                       spike_in_valid,
    output wire                       spike_in_ready,
    
    // Output spike interface
    output reg  [15:0]                output_neuron_id, // This neuron's ID
    output reg                        spike_out_valid,
    input  wire                       spike_out_ready,
    
    // Neuron ID (configuration)
    input  wire [15:0]                neuron_id,
    
    // Debug/Status
    output wire [NEURON_WIDTH-1:0]    membrane_potential,
    output wire                       in_refractory,
    output wire [7:0]                 refract_counter
);

    //=======================================================================
    // Internal State
    //=======================================================================
    reg signed [NEURON_WIDTH-1:0] membrane;        // Membrane potential (signed)
    reg [7:0] refractory_counter;                   // Refractory period countdown
    reg spike_pending;                              // Spike waiting to be output
    
    wire is_refractory = (refractory_counter > 0);
    wire can_integrate = spike_in_valid && spike_in_ready && !is_refractory;
    
    // Sign-extended weight for addition
    wire signed [NEURON_WIDTH-1:0] weight_extended = {
        {(NEURON_WIDTH-WEIGHT_WIDTH){synapse_weight[WEIGHT_WIDTH-1]}}, 
        synapse_weight
    };
    
    // Leak calculation (multiply membrane by leak_rate)
    // leak_rate is 0.16 fixed-point, so shift right by 16 after multiply
    wire signed [NEURON_WIDTH+LEAK_WIDTH-1:0] leak_product = membrane * $signed({1'b0, leak_rate});
    wire signed [NEURON_WIDTH-1:0] leak_value = leak_product[NEURON_WIDTH+LEAK_WIDTH-1:LEAK_WIDTH];
    
    // Threshold comparison (signed)
    wire spike_condition = (membrane >= $signed(threshold)) && !is_refractory;
    
    //=======================================================================
    // Input Ready Signal
    //=======================================================================
    // Can accept input when not in refractory period and not processing a spike
    assign spike_in_ready = !is_refractory && !spike_pending;
    
    //=======================================================================
    // State Machine
    //=======================================================================
    localparam STATE_IDLE = 2'b00;
    localparam STATE_INTEGRATE = 2'b01;
    localparam STATE_SPIKE = 2'b10;
    localparam STATE_REFRACT = 2'b11;
    
    reg [1:0] state, next_state;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always @(*) begin
        next_state = state;
        case (state)
            STATE_IDLE: begin
                if (can_integrate)
                    next_state = STATE_INTEGRATE;
                else if (spike_pending)
                    next_state = STATE_SPIKE;
            end
            
            STATE_INTEGRATE: begin
                if (spike_condition)
                    next_state = STATE_SPIKE;
                else
                    next_state = STATE_IDLE;
            end
            
            STATE_SPIKE: begin
                if (spike_out_ready)
                    next_state = STATE_REFRACT;
            end
            
            STATE_REFRACT: begin
                if (refractory_counter == 0)
                    next_state = STATE_IDLE;
            end
        endcase
    end
    
    //=======================================================================
    // Membrane Potential Update
    //=======================================================================
    always @(posedge clk) begin
        if (rst) begin
            membrane <= 0;
            refractory_counter <= 0;
            spike_pending <= 0;
            spike_out_valid <= 0;
            output_neuron_id <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    // Apply leak if enabled
                    if (leaky_enable && !is_refractory) begin
                        membrane <= membrane - leak_value;
                        // Prevent negative membrane potential
                        if (membrane < leak_value)
                            membrane <= 0;
                    end
                end
                
                STATE_INTEGRATE: begin
                    // Add weighted input
                    membrane <= membrane + weight_extended;
                    
                    // Check for spike after integration
                    if (spike_condition) begin
                        spike_pending <= 1;
                        output_neuron_id <= neuron_id;
                    end
                end
                
                STATE_SPIKE: begin
                    spike_out_valid <= 1;
                    
                    if (spike_out_ready) begin
                        spike_out_valid <= 0;
                        spike_pending <= 0;
                        refractory_counter <= refractory;
                        
                        // Reset membrane if configured
                        if (reset_on_spike)
                            membrane <= 0;
                        else
                            membrane <= membrane - $signed(threshold);
                    end
                end
                
                STATE_REFRACT: begin
                    // Countdown refractory period
                    if (refractory_counter > 0)
                        refractory_counter <= refractory_counter - 1;
                end
            endcase
        end
    end
    
    //=======================================================================
    // Debug Outputs
    //=======================================================================
    assign membrane_potential = membrane;
    assign in_refractory = is_refractory;
    assign refract_counter = refractory_counter;

endmodule
