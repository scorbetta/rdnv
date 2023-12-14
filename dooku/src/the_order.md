# the_order

## Preamble
Verilog is the preferred language for designing digital circuits. SystemVerilog is also used in some
cases, but since open-source EDA tools have poor support for SystemVerilog, its usage is kept at a
minimum. Verification is generally performed using a mixture of SystemVerilog and Python. Please
refer to [organa](/organa) for additional information.

## Coding style
Styling and conventions are here presented starting with a reference example that clarifies the
intentions.

```verilog
// Preferred way of writing Verilog modules
module MY_MODULE
#(
    parameter DATA_WIDTH = 32
)
(
    input wire                      CLK,
    input wire                      RSTN,
    input wire                      WVALID,
    input wire [DATA_WIDTH-1:0]     DATA,
    outut wire                      RVALID,
    output wire [DATA_WIDTH-1:0]    RDATA
);

    // Connections
    reg                     rvalid;
    reg [DATA_WIDTH-1:0]    rdata;

    always @(posedge CLK)
    begin
        if(!RSTN) begin
            rvalid <= 1'b0;
        end
        else begin
            rvalid <= WVALID;
            rdata <= ~WDATA;
        end
    end

    // Pinout
    assign RVALID   = rvalid;
    assign RDATA    = rdata;
endmodule
```

The above example would be written in a file called `MY_MODULE.v`. The name of the file matches the
name of the module it contains. Both are always all caps; file extension is always lower case. Every
file contains one and only one module definition.

Parameters and ports are all caps as well. Ports are always defined as `wire`. When an output port
is registered, a `reg` signal with the same name of the port, but lower case, is included in the
list of signals. Then, a pinout assignment exists for that particular PORT/signal pair. This is good
habit since it makes the code easier to read, and it helps visual debug as well: every time we find
an all-caps name as RHS, we are reading a port; whenever we find an all-caps name as LHS, on the
other hand, that is an error.

To keep things simple, all parameters are treated as integers. There is no need to declare their
type.

Different elements of the same type are aligned if they are shown in blocks (i.e., multiple
occurrences). This happens for example in the definition of ports, signals and assignment blocks.
When a single line is present, as in the parameters section of the example, there is no need.
Alignment is enforced configuring the editor such that tab characters are expanded into spacs. The
size of a tab is generally set to 4 (spaces). The alignment is such that the starting of the column
is the first column who's an integer multiple of 4 (the atomic space amount) counting from the
position of the last character of the longest line in that block. In the above example, we see that
the `RDATA` line is the longest one. So we press one single tab character from the `]` character.
Here is where we write the port name. This right-wise column alignment applies to names in ports,
parameters and signals and to '=' in assignment blocks. In all other cases, only a single space is
required.

Resets are synchronous, with preferred polarity being low. Check of single-bit values in
conditionals (e.g., `if`) is always expressed in Boolean terms (use `!` instead of `== 1'b0`).

Negation operation is done using the `~` operator, to diversify conditionals from arithmetics.
