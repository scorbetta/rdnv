// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vtop__Syms.h"
#include "Vtop.h"
#include "Vtop___024root.h"

// FUNCTIONS
Vtop__Syms::~Vtop__Syms()
{

    // Tear down scope hierarchy
    __Vhier.remove(0, &__Vscope_EDGE_DETECTOR);

}

Vtop__Syms::Vtop__Syms(VerilatedContext* contextp, const char* namep, Vtop* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
    // Setup scopes
    __Vscope_EDGE_DETECTOR.configure(this, name(), "EDGE_DETECTOR", "EDGE_DETECTOR", -9, VerilatedScope::SCOPE_MODULE);
    __Vscope_TOP.configure(this, name(), "TOP", "TOP", 0, VerilatedScope::SCOPE_OTHER);

    // Set up scope hierarchy
    __Vhier.add(0, &__Vscope_EDGE_DETECTOR);

    // Setup export functions
    for (int __Vfinal = 0; __Vfinal < 2; ++__Vfinal) {
        __Vscope_EDGE_DETECTOR.varInsert(__Vfinal,"CLK", &(TOP.EDGE_DETECTOR__DOT__CLK), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_EDGE_DETECTOR.varInsert(__Vfinal,"FALL_EDGE_OUT", &(TOP.EDGE_DETECTOR__DOT__FALL_EDGE_OUT), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_EDGE_DETECTOR.varInsert(__Vfinal,"RISE_EDGE_OUT", &(TOP.EDGE_DETECTOR__DOT__RISE_EDGE_OUT), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_EDGE_DETECTOR.varInsert(__Vfinal,"RSTN", &(TOP.EDGE_DETECTOR__DOT__RSTN), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_EDGE_DETECTOR.varInsert(__Vfinal,"SAMPLE_IN", &(TOP.EDGE_DETECTOR__DOT__SAMPLE_IN), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_EDGE_DETECTOR.varInsert(__Vfinal,"fall_edge_out", &(TOP.EDGE_DETECTOR__DOT__fall_edge_out), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_EDGE_DETECTOR.varInsert(__Vfinal,"rise_edge_out", &(TOP.EDGE_DETECTOR__DOT__rise_edge_out), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,0);
        __Vscope_EDGE_DETECTOR.varInsert(__Vfinal,"sample_follower", &(TOP.EDGE_DETECTOR__DOT__sample_follower), false, VLVT_UINT8,VLVD_NODIR|VLVF_PUB_RW,1 ,1,0);
        __Vscope_TOP.varInsert(__Vfinal,"CLK", &(TOP.CLK), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
        __Vscope_TOP.varInsert(__Vfinal,"FALL_EDGE_OUT", &(TOP.FALL_EDGE_OUT), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0);
        __Vscope_TOP.varInsert(__Vfinal,"RISE_EDGE_OUT", &(TOP.RISE_EDGE_OUT), false, VLVT_UINT8,VLVD_OUT|VLVF_PUB_RW,0);
        __Vscope_TOP.varInsert(__Vfinal,"RSTN", &(TOP.RSTN), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
        __Vscope_TOP.varInsert(__Vfinal,"SAMPLE_IN", &(TOP.SAMPLE_IN), false, VLVT_UINT8,VLVD_IN|VLVF_PUB_RW,0);
    }
}
