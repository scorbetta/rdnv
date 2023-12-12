module EDGE_DETECTOR (
    input   CLK,
    input   RSTN,
    input   SAMPLE_IN,
    output  RISE_EDGE_OUT,
    output  FALL_EDGE_OUT
);

    logic       rise_edge_out;
    logic       fall_edge_out;
    logic [1:0] sample_follower;
    
    always_ff @(posedge CLK) begin
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
