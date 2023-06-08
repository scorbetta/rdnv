`timescale 1ns/100ps

`define NUM_OUTPUTS 8

module ootbtb;
    logic [15:0]                        bus_in;
    logic [15:0]                        bus_out [`NUM_OUTPUTS];
    logic [$clog2(`NUM_OUTPUTS)-1:0]    sel_in;

    // DUT
    PARAMETRIC_DEMUX #(
        .DATA_WIDTH (16),
        .NUM_OUTPUTS (`NUM_OUTPUTS)
    )
    DUT_SV (
        .BUS_IN     (bus_in),
        .SEL_IN     (sel_in),
        .BUS_OUT    (bus_out)
    );

    initial begin
        for(integer idx = 1; idx < 50; idx++) begin
            // Random selected input
            sel_in = $random % `NUM_OUTPUTS;
            bus_in = $random;

            // Check output
            #1;
            if(bus_out[sel_in] != bus_in) begin
                $display("erro: Unexpected output from DUT_SV @%0d: 0x%04x (expected: 0x%04x)", bus_out[sel_in], bus_in, sel_in);
            end

        end

        $finish;
    end

    initial begin
        $monitor("dbug: DUT_SV: bus_in=0x%04x, sel_in=%0d, bus_out={ 0x%04x, 0x%04x, 0x%04x, 0x%04x, 0x%04x, 0x%04x, 0x%04x, 0x%04x }", bus_in, sel_in, bus_out[0], bus_out[1], bus_out[2], bus_out[3], bus_out[4], bus_out[5], bus_out[6], bus_out[7]);
    end
endmodule
