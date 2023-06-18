// Internal signals accessor. Just add any desired signal to probe in this interface
interface data_sink_whitebox_if
#(
    parameter DATA_WIDTH    = 32,
    parameter RAM_DEPTH     = 64
)
(
    input [$clog2(RAM_DEPTH)-1:0]   row,
    input [DATA_WIDTH-1:0]          ram [RAM_DEPTH]
);
endinterface
