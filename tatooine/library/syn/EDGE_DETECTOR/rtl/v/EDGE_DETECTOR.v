`default_nettype none

module EDGE_DETECTOR (
    input wire  CLK,
    input wire  RSTN,
    input wire  SAMPLE_IN,
    output wire RISE_EDGE_OUT,
    output wire FALL_EDGE_OUT
);

    wire        rise_edge_out;
    wire        fall_edge_out;
    reg [1:0]   sample_follower;
    
    always @(posedge CLK) begin
        if(!RSTN) begin
            sample_follower <= 2'b00;
        end
        else begin
            // The new sample goes into [0], the old one goes into [1]
            sample_follower <= { sample_follower[0], SAMPLE_IN };
        end
    end
    
    // Detect edges without introducing further delay
    assign rise_edge_out = (sample_follower == 2'b01);
    assign fall_edge_out = (sample_follower == 2'b10);
    
    // Pinout
    assign RISE_EDGE_OUT = rise_edge_out;
    assign FALL_EDGE_OUT = fall_edge_out;
endmodule

`default_nettype wire
