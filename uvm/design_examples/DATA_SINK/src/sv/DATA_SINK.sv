`timescale 1ns/100ps

import axi4_pkg::*;

module DATA_SINK
#(
    parameter DATA_WIDTH    = 32,
    parameter RAM_DEPTH     = 64
)
(
    input           ACLK,
    input           ARESETN,
    axi4s_if.slave  AXIS_PORT
);

    logic [DATA_WIDTH-1:0]          ram [RAM_DEPTH] = '{default: 32'd0};
    logic [$clog2(RAM_DEPTH)-1:0]   row;
    logic                           tready;

    // Circular buffer
    always_ff @(posedge ACLK) begin
        if(!ARESETN) begin
            tready <= 1'b0;
        end
        else begin
            tready <= 1'b0;

            if(AXIS_PORT.tvalid && !tready) begin
                tready <= 1'b1;
            end
        end
    end

    // Data logger
    always_ff @(posedge ACLK) begin
        if(!ARESETN) begin
            row <= {$clog2(RAM_DEPTH){1'b0}};
        end
        else if(AXIS_PORT.tvalid && tready) begin
            row <= row + 1;
            ram[row] <= AXIS_PORT.tdata;
        end
    end

    // Pinout
    assign AXIS_PORT.tready = tready;

    //@FUCKINGVIVADO/* synthesis translate_off */
    //@FUCKINGVIVADOinitial begin
    //@FUCKINGVIVADO    ram = '{default: 32'd0};
    //@FUCKINGVIVADOend
    //@FUCKINGVIVADO/* synthesis translate_on */
endmodule
