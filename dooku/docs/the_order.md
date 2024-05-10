## Preamble
Verilog is the preferred language for designing digital circuits. SystemVerilog is also used in some
cases, but since open-source EDA tools have poor support for SystemVerilog, its usage is kept at a
minimum. Verification is generally performed using a mixture of SystemVerilog and Python. Please
refer to [organa](organa.md) for additional information.

## References
This design guide book merges ideas by the author himself and from external references. Important
references are reported.

- ["RTL Design Guidelines"](http://www.asic.co.in/DesignGuidlinesRTLcoding.htm);
- ["UltraFast Design Methodology Guide for FPGAs and SoCs (UG949)"](https://docs.xilinx.com/r/en-US/ug949-vivado-design-methodology/RTL-Coding-Guidelines).

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

## Style and naming
1. File name extension for each RTL source file shall be `.v` for Verilog and `.sv` for
   SystemVerilog.
2. Every source file shall contain one and only one module.
3. The name of the file shall match the name of the module definition.
4. Whenever needed, port functionality shall be defined in comments in the port declaration section;
   module functionality shall be defiined in a comment preceeding the module declaration section.
5. Identifiers for modules, ports, module and local parameters, and constants shall be upper case.
6. Signal names are active-high by default. Active-low signal names must have either an `_n` or an
   `n` suffix; port names must have either an `_N` or an `N` suffix;

## Modules instantiation
1. Only signals names should be connected to module ports. Do not insert logic expressions of any
   kind on inputs to modules.
2. Make port connections explicit

## Simulator-friendly rules
1. Signal names shall never change when traversing the design hierarchy. This is particularly true
   for clock signals.
3. Module stand-alone test bench must drive X’s when input is not needed
WHY: In order to stress the proper tolerance of unknown values on input signals (and therefore the correct qualification of various signals or busses), stand-alone module test benches should drive X’s on unused inputs where appropriate.

## Synthesis-friendly rules
1. Use of `initial` statements is prohibited for logic initialization.
1. There should be no gate or behavioral code instantiated at the chip top level or core top level.
No synthesizable code or hand-instantiated gates should be placed in the very top level modules of the design.
2. Constrain fanout in synthesis
Synthesis should be constrained to less than 16 (pins) and in most cases less than 8 (pins).
WHY: Constraining fanout will tend to limit the length of the wire and therefore the capacitive load.
It will result in a faster circuit. More importantly, it will keep the wire length in a region better modeled by wire load models and will assist in timing closure.
3. Do not fix hold time during synthesis.
In general, libraries are built such that flop to flop logic does not have any hold time issues assuming ideal clocks. Hold time is therefore caused by clock skew after P&R and clock tree generation. The synthesis tool does not have the proper information to therefore fix any hold time problems that could occur in the physical design stage

## Sequential logic rules 
1. The basic register element is the positive-edge-triggered flip-flop. Negative-edge-triggered flip
   flops are not allowed. Exceptions are allowed when needed to meet specific design challenges, but
must be highlighted in the microarchitecture specification.
2. Avoid using asynchronous resettable flip flops. Asynchronous reset lines are susceptible to
   glitches caused by crosstalk when using 0.18um and smaller CMOS technology. Exceptions are
allowed in special cases (initial central reset logic and clock generation logic). These exceptions
should be documented in the module microarchitecture specification.
3. All control flip-flops in the design must be initialized by a synchronous reset using the flip flop’s synchronous reset. Datapath flops can be left un-initialized.
4. The generic structure of flopped signal follows:
```
always @(posedge CLK) begin
    if(!RSTN) begin
        my_signal <= 1'b0;
    end
    else begin
        my_signal <= ...;
    end
end
```

5. All assignments in a sequential procedural block must be non-blocking (<=).
WHY: Blocking assignments imply order, which may or may not be correctly duplicated in synthesized code.

6. No latches shall be used
WHY: Latches severely complicate the STA and are more difficult to test. They lead to pseudo-asynchronous designs. Implied or explicit instantiation of latches is illegal.
ALLOWED VIOLATION: Latches are required (transparent low) in the gated clock structures.
Latches are also necessary as data lockup latches between clock domains in scan chains.

## Combinational logic rules
1. The RTL will be completely specified
No “implied” structure is allowed. For example, in a case statement, the default case must be included.  However, no logical value can be assigned in the default case, as the default case is used for proper X and Z handling. For state machines, initialization and state transitions from unused states must be specified to prevent incorrect operation. All elements within a combinatorial always block will be specified in the sensitivity list.
WHY: Incompletely specified RTL will result in incorrect X handling, Z handling, RTL vs. structural simulation violations, inferrence of latches, etc.

## FSMs
1. All state machines must either be initialized to a known state OR must self-clear from every state.
WHY: State machines cannot be trusted to power up in a known state, let alone the default or idle state. They should either be initialized at reset or every state should ultimately resolve into the state cycle.

## Clock, reset and timing closure guidelines
1. The design must be fully synchronous and must use only the rising edge of the clock.
There must be only one clock in each clock domain, and only the rising edge of this clock is to be used for state changes.
WHY: This rule results in insensitivity to the clock duty cycle and simplifies Static Timing Analysis (STA).
ALLOWED VIOLATION: The falling edge is only allowed in the gated clock logic as specified by the GCK modules. Compliance to industry-standard interfaces may also require use of the falling edge of the clock.

2. Reset generation logic should be grouped into a single module

## CDC rules
1. All clock domain boundaries should be handled using 2-stage synchronizers.
2. Never synchronize a bus through 2 stage synchronizers
The sampling could capture transitional values that are not valid. Sending a bus from 1 clock domain to another requires special attention. Buses should be captured by implementing the multi-bit synchronizer, lib_bus_sync.v located in “WHEREVERWEAREGOINGTOSTOREIT. This guarantees timing and automatically gets incorporated into the synthesis and primetime scripts.







#### CHECK THESE 
An assignment of d to q is the only one allowed. No logic equations except for the synchronous reset can appear on the right side of this assignment statement.
WHY: This results in correct sync-clear-D-flip-flop inferral in synthesis.


§                     All output of register elements must be suffixed with the letter "q"
This must follow the module  identifying letter in the signal name. e.g. x_widgetnet_q or x_widgetnet_qn (active low)
WHY: This will allow for simple parsing by scripts of the synthesis output files to detect unintentional flip-flop or latch inferrals.


§                     All inputs of register elements must be suffixed with the letter "d"
This must follow the module identifying letter in the signal name.
WHY: This creates a consistent naming convention between the input and output of a register element that will aid in debug, as well as identifying critical paths. The d or q version of a signal will be more appropriately used in different circumstances, and will be reviewed as such.
ALLOWED VIOLATION: This rule only applies if the "d" signal is newly created. If this "d" signal is a signal from another module, only registered within this module, the rename is not necessary, as it will needlessly increase the size of the database from the simulation and slow down the simulation. In addition, if signals correspond to pipeline stages, the d=q convention must be dropped, as it is imperative that a signal name not incorrectly bear the name of a pipeline stage in which it is not valid.

assign x_yyyyy_d = some logic equation;
always @(posedge clk)
x_yyyyy_q <= x_yyyyy_d

where x is the module identifying letters, q or d identifies the signal attach pin, and yyyyy is the signal name. All elements of this register structure must be placed together in RTL such that the entire structure is easily read and understood.



§                     Sequential Logic must always be partitioned into Combinatorial Logic and Flip-flops
This rule requires that storage elements or nodes be explicitly called out in the RTL and that all sequential logic be considered combinatorial logic combined with storage elements.

e.g.

//cominational part
always @ (variable…..)
begin
  if (some condition) x_widget_d <= 1’b1;
  else x_widget_d <= 1’b0;
end

//Register
always @ (posedge clock)
begin
  if (!reset_n) x_widget_q <= 1’b0;
  else x_widget_q <= x_widget_d;
end

WHY: This rule forces designers to think of the hardware aspect of their design currently coded only in RTL. In addition, this partitioning will assist synthesis. As stated above, the combinatorial and sequential elements comprising the sequential logic shall be placed close together in code so as to ease readability.
EXCEPTION: In cases of extremely simple blocks, such as counters, it is both more readable and more supportable to have the combinatorial and register logic in the same procedural block.


   Future state determination will depend only on registered state variables
Only registered state variables shall be used to determine future states.
WHY: Use of pre-registered state variables can cause long and/or false timing paths.


§                     State machines should be coded with Case statements and parameters for state variable names
State machines should be easy to read and should be in the following form:

parameter IDLE=3’b000, ACTIVE=3;b001;
// Combinatorial part
always @ (state or xyz or abc)
begin
case (state)
IDLE:
if (xyz) next_state <= ACTIVE;
else next_state <= IDLE;
ACTIVE:
if (abc) next_state <= IDLE;
else next_state <= ACTIVE;
endcase
end

// flops
always @ (posedge clk)
begin
if (!reset_n) state <= IDLE;
else state <= next_state;
end


§                     STA must be performed with identical results at a 50/50 +/- 10% duty cycle
STA should be performed on a sample or final netlist at 40/60, 50/50 and 60/40.
WHY: The weaker drive strength relative to wire load, and the increasing number of flops on a clock net, may clip the clock waveform to a +/- 10% duty cycle.

§                     150 picoseconds hold time margin requirement at best case conditions
STA should indicate that the netlist and (trial) layout will have 150 ps of hold time margin (above that built into the library) at best case process, +5% voltage and 0C. This rule will require use of robust flip-flops.
WHY: Extra hold time margin makes the design more reusable and covers variations in the signoff tool suite and libraries.
ALTERNATE VARIATION: In the event that -40C is the signoff condition instead, 100 ps margin is required.


§                     5% Setup Margin Required
STA should indicate that the netlist and (trial) layout will have a 5% setup time margin (above that built into the library) at the worst case process, -5% voltage and 125C. For example, a design that needs to run at 100 MHz would need to pass STA at 105 MHz.
WHY: Extra setup time is required to maintain the promised frequency over the lifetime of the design, covering variations in the signoff tool suite and libraries.

