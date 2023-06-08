`timescale 1ns/100ps

`define NUM_INPUTS 8

module ootbtb;
    logic [15:0]                    bus_in [`NUM_INPUTS];
    logic [15:0]                    bus_out;
    logic [$clog2(`NUM_INPUTS)-1:0] sel_in;

    // DUT
    PARAMETRIC_MUX #(
        .DATA_WIDTH (16),
        .NUM_INPUTS (`NUM_INPUTS)
    )
    DUT_SV (
        .BUS_IN     (bus_in),
        .SEL_IN     (sel_in),
        .BUS_OUT    (bus_out)
    );

    initial begin
        for(integer idx = 1; idx < 50; idx++) begin
            // Random selected input
            sel_in = $random % `NUM_INPUTS;

            for(integer bdx = 0; bdx < `NUM_INPUTS; bdx++) begin
                // Unknown data on default inputs
                bus_in[bdx] = 16'hxxxx;

                // Random data on selected input
                if(bdx == sel_in) begin
                    bus_in[bdx] = $random;
                end
            end

            // Check output
            #1;
            if(bus_out != bus_in[sel_in]) begin
                $display("erro: Unexpected output from DUT_SV: 0x%04x (expected: 0x%04x) when sel equals %d", bus_out, bus_in[sel_in], sel_in);
            end

        end

        $finish;
    end

    initial begin
        $monitor("dbug: DUT_SV: bus_in={ 0x%04x, 0x%04x, 0x%04x, 0x%04x, 0x%04x, 0x%04x, 0x%04x, 0x%04x }, sel_in=%0d, bus_out=0x%04x", bus_in[0], bus_in[1], bus_in[2], bus_in[3], bus_in[4], bus_in[5], bus_in[6], bus_in[7], sel_in, bus_out);
    end
endmodule
