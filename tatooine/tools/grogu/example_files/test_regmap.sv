module {{module_name}} (
        input wire clk,
        input wire rst,

        {%- for signal in user_out_of_hier_signals %}
        {%- if signal.width == 1 %}
        input wire {{kwf(signal.inst_name)}},
        {%- else %}
        input wire [{{signal.width-1}}:0] {{kwf(signal.inst_name)}},
        {%- endif %}
        {%- endfor %}

        {{cpuif.port_declaration|indent(8)}}
        {%- if hwif.has_input_struct or hwif.has_output_struct %},{% endif %}

        {{hwif.port_declaration|indent(8)}}

);

    // Internal connections
    logic           regpool_wen;
    logic [15:0]    regpool_waddr;
    logic [31:0]    regpool_wdata;
    logic           regpool_ren;
    logic [15:0]    regpool_raddr;
    logic [31:0]    regpool_rdata;
    logic           regpool_rvalid;

    // AXI4 Lite interface
    AXIL2NATIVE #(
        .DATA_WIDTH (32),
        .ADDR_WIDTH (16)
    )
    AXIL2NATIVE_0 (
        .AXI_ACLK       (clk),
        .AXI_ARESETN    (~rst),
        .AXI_AWADDR     ({{cpuif.port_declaration}}.awaddr),
        .AXI_AWPROT     ({{cpuif.port_declaration}}.awprot),
        .AXI_AWVALID    ({{cpuif.port_declaration}}.awvalid),
        .AXI_AWREADY    ({{cpuif.port_declaration}}.awready),
        .AXI_WDATA      ({{cpuif.port_declaration}}.wdata),
        .AXI_WSTRB      ({{cpuif.port_declaration}}.wstrb),
        .AXI_WVALID     ({{cpuif.port_declaration}}.wvalid),
        .AXI_WREADY     ({{cpuif.port_declaration}}.wready),
        .AXI_BRESP      ({{cpuif.port_declaration}}.bresp),
        .AXI_BVALID     ({{cpuif.port_declaration}}.bvalid),
        .AXI_BREADY     ({{cpuif.port_declaration}}.bready),
        .AXI_ARADDR     ({{cpuif.port_declaration}}.araddr),
        .AXI_ARPROT     ({{cpuif.port_declaration}}.arprot),
        .AXI_ARVALID    ({{cpuif.port_declaration}}.arvalid),
        .AXI_ARREADY    ({{cpuif.port_declaration}}.arready),
        .AXI_RDATA      ({{cpuif.port_declaration}}.rdata),
        .AXI_RRESP      ({{cpuif.port_declaration}}.rresp),
        .AXI_RVALID     ({{cpuif.port_declaration}}.rvalid),
        .AXI_RREADY     ({{cpuif.port_declaration}}.rready),
        .WEN            (regpool_wen),
        .WADDR          (regpool_waddr),
        .WDATA          (regpool_wdata),
        .WACK           (), // Unused
        .REN            (regpool_ren),
        .RADDR          (regpool_raddr),
        .RDATA          (regpool_rdata),
        .RVALID         (regpool_rvalid)
    );

    // Field logic
    {{field_logic.get_combo_struct()|indent}}

    {{field_logic.get_storage_struct()|indent}}

    {{field_logic.get_implementation()|indent}}
endmodule
