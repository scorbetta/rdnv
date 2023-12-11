// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtop.h for the primary calling header

#ifndef VERILATED_VTOP___024ROOT_H_
#define VERILATED_VTOP___024ROOT_H_  // guard

#include "verilated.h"


class Vtop__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtop___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(CLK,0,0);
    VL_IN8(RSTN,0,0);
    VL_IN8(SAMPLE_IN,0,0);
    VL_OUT8(RISE_EDGE_OUT,0,0);
    VL_OUT8(FALL_EDGE_OUT,0,0);
    CData/*0:0*/ EDGE_DETECTOR__DOT__CLK;
    CData/*0:0*/ EDGE_DETECTOR__DOT__RSTN;
    CData/*0:0*/ EDGE_DETECTOR__DOT__SAMPLE_IN;
    CData/*0:0*/ EDGE_DETECTOR__DOT__RISE_EDGE_OUT;
    CData/*0:0*/ EDGE_DETECTOR__DOT__FALL_EDGE_OUT;
    CData/*0:0*/ EDGE_DETECTOR__DOT__rise_edge_out;
    CData/*0:0*/ EDGE_DETECTOR__DOT__fall_edge_out;
    CData/*1:0*/ EDGE_DETECTOR__DOT__sample_follower;
    CData/*0:0*/ __Vtrigprevexpr___TOP__CLK__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VstlIterCount;
    IData/*31:0*/ __VicoIterCount;
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtop__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtop___024root(Vtop__Syms* symsp, const char* v__name);
    ~Vtop___024root();
    VL_UNCOPYABLE(Vtop___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
