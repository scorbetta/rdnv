
/*******************************************************************
*
* CAUTION: This file is automatically generated by HSI.
* Version: 2021.2
* DO NOT EDIT.
*
* Copyright (C) 2010-2022 Xilinx, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT 

* 
* Description: Driver configuration
*
*******************************************************************/

#include "xparameters.h"
#include "xintc.h"


extern void XNullHandler (void *);

/*
* The configuration table for devices
*/

XIntc_Config XIntc_ConfigTable[] =
{
	{
		XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_DEVICE_ID,
		XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_BASEADDR,
		XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_KIND_OF_INTR,
		XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_HAS_FAST,
		XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_IVAR_RESET_VALUE,
		XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_NUM_INTR_INPUTS,
		XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_ADDR_WIDTH,
		XIN_SVC_SGL_ISR_OPTION,
		XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_TYPE,
		{
			{
				XNullHandler,
				(void *) XNULL
			},
			{
				XNullHandler,
				(void *) XNULL
			}
		},
		XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_NUM_SW_INTR
	}
};

