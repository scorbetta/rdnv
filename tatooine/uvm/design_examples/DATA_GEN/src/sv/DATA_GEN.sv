`timescale 1ns/100ps

import axi4_pkg::*;

module DATA_GEN
(
    input           ACLK,
    input           ARESETN,
    input           CFG_VALID,
    input [31:0]    CFG_DATA,
    input           START,
    axi4s_if.master AXIS_PORT
);

    logic [31:0]    stream_len;
    logic [31:0]    stream_count;
    logic           stream_count_reset;
    logic           start_seen;
    logic           tvalid;
    logic           last_seen;
    logic           last_beat;

    // Configuration latch
    always_ff @(posedge ACLK) begin
        if(!ARESETN) begin
            stream_len <= 32'd0;
        end
        else if(CFG_VALID) begin
            stream_len <= CFG_DATA;
        end
    end

    // Stream control
    always_ff @(posedge ACLK) begin
        if(!ARESETN) begin
            tvalid <= 1'b0;
            stream_count_reset <= 1'b0;
            start_seen <= 1'b0;
        end
        else begin
            tvalid <= 1'b0;
            stream_count_reset <= 1'b0;

            if(START && !start_seen) begin
                start_seen <= 1'b1;
                tvalid <= 1'b1;
                stream_count_reset <= 1'b1;
            end
            else if(start_seen && !last_seen) begin
                tvalid <= 1'b1;
            end
            else begin
                start_seen <= 1'b0;
            end
        end
    end

    // Data counter 
    always_ff @(posedge ACLK) begin
        if(stream_count_reset) begin
            stream_count <= 32'd0;
        end
        else if(tvalid && AXIS_PORT.tready) begin
            stream_count <= stream_count + 1;
        end
    end

    // Marks the very last beat of the stream
    assign last_beat = (stream_count == (stream_len - 1));
    assign last_seen = last_beat & tvalid & AXIS_PORT.tready;

    // Pinout
    assign AXIS_PORT.tvalid = tvalid;
    assign AXIS_PORT.tdata  = stream_count;
    assign AXIS_PORT.tlast  = (stream_count == (stream_len - 1));
endmodule
