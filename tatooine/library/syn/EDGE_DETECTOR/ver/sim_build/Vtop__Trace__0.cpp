// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_fst_c.h"
#include "Vtop__Syms.h"


void Vtop___024root__trace_chg_sub_0(Vtop___024root* vlSelf, VerilatedFst::Buffer* bufp);

void Vtop___024root__trace_chg_top_0(void* voidSelf, VerilatedFst::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_top_0\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vtop___024root__trace_chg_sub_0((&vlSymsp->TOP), bufp);
}

void Vtop___024root__trace_chg_sub_0(Vtop___024root* vlSelf, VerilatedFst::Buffer* bufp) {
    if (false && vlSelf) {}  // Prevent unused
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_chg_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    bufp->chgBit(oldp+0,(vlSelf->CLK));
    bufp->chgBit(oldp+1,(vlSelf->RSTN));
    bufp->chgBit(oldp+2,(vlSelf->SAMPLE_IN));
    bufp->chgBit(oldp+3,(vlSelf->RISE_EDGE_OUT));
    bufp->chgBit(oldp+4,(vlSelf->FALL_EDGE_OUT));
    bufp->chgBit(oldp+5,(vlSelf->EDGE_DETECTOR__DOT__CLK));
    bufp->chgBit(oldp+6,(vlSelf->EDGE_DETECTOR__DOT__RSTN));
    bufp->chgBit(oldp+7,(vlSelf->EDGE_DETECTOR__DOT__SAMPLE_IN));
    bufp->chgBit(oldp+8,(vlSelf->EDGE_DETECTOR__DOT__RISE_EDGE_OUT));
    bufp->chgBit(oldp+9,(vlSelf->EDGE_DETECTOR__DOT__FALL_EDGE_OUT));
    bufp->chgBit(oldp+10,(vlSelf->EDGE_DETECTOR__DOT__rise_edge_out));
    bufp->chgBit(oldp+11,(vlSelf->EDGE_DETECTOR__DOT__fall_edge_out));
    bufp->chgCData(oldp+12,(vlSelf->EDGE_DETECTOR__DOT__sample_follower),2);
}

void Vtop___024root__trace_cleanup(void* voidSelf, VerilatedFst* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtop___024root__trace_cleanup\n"); );
    // Init
    Vtop___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtop___024root*>(voidSelf);
    Vtop__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VlUnpacked<CData/*0:0*/, 1> __Vm_traceActivity;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        __Vm_traceActivity[__Vi0] = 0;
    }
    // Body
    vlSymsp->__Vm_activity = false;
    __Vm_traceActivity[0U] = 0U;
}
