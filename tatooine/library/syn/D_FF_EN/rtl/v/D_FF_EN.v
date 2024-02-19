`default_nettype none

// D-type flip-flop w/ enable
module D_FF_EN
(
    input wire  CLK,
    input wire  RSTN,
    input wire  D,
    input wire  EN,
    output wire Q
);

    reg q;

    always @(posedge CLK) begin
        if(!RSTN) begin
            q <= 1'b0;
        end
        else if(EN) begin
            q <= D;
        end
    end

    assign Q = q;
endmodule

`default_nettype wire
