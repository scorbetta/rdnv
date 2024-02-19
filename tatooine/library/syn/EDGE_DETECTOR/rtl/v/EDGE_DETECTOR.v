`default_nettype none

module EDGE_DETECTOR (
    input wire  CLK,
    input wire  SAMPLE_IN,
    output wire RISE_EDGE_OUT,
    output wire FALL_EDGE_OUT
);

    reg sample_in;
    
    always @(posedge CLK) begin
        sample_in <= SAMPLE_IN;
    end
    
    assign RISE_EDGE_OUT = ~sample_in & SAMPLE_IN;
    assign FALL_EDGE_OUT = sample_in & ~SAMPLE_IN;
endmodule

`default_nettype wire
