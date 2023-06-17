//---- INCLUDES ---------------------------------------------------------------

// Standard includes
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include "xil_printf.h"
#include <string.h>
#include <ctype.h>

// BSP
#include "platform.h"
#include "xparameters.h"
#include "xintc.h"
#include "xspi.h"

#if XPAR_XHWICAP_NUM_INSTANCES
#include "xhwicap.h"
#endif /* XPAR_XHWICAP_NUM_INSTANCES */

// QSPI Flash library
#include "qspi_flash.h"

// Xilinx additionals
#include "xil_exception.h"
#include "xil_types.h"
#include "sleep.h"


//---- DEFINES ----------------------------------------------------------------

u8 BUFFER_CHECK[550];
u8 BUFFER_WRITE[550];

// Commands for the Firmware Upgrade controller
#define FWU_NOP				0x00000000
#define FWU_ERASE_SECTOR	0xffff1111
#define FWU_FLASH_TEST		0x22222222
#define FWU_PROGRAM_PAGE	0xffff2222
#define FWU_READ_PAGE		0xffff3333
#define FWU_BOOT			0xffb001ee

// Location of RAM contents for message passing
#define SHAMEM_PENDING_CMD 		0
#define SHAMEM_CMD_ARGUMENT_1	1
#define SHAMEM_CMD_ARGUMENT_2	2
#define SHAMEM_CMD_STATUS		3
#define SHAMEM_CMD_RESULT		4
#define SHAMEM_INIT_STATUS		5
#define SHAMEM_RESERVED			6
#define SHAMEM_WATERMARK		7
#define SHAMEM_FIRST_BYTE		8

// Versioning
#define VERSION_STRING 		"ni_fwu_1.0"
#define LATEST_BUILD_STRING	"2022/10/25"


//---- UTILITIES --------------------------------------------------------------

#if XPAR_XHWICAP_NUM_INSTANCES
#define HWICAP_EXAMPLE_BITSTREAM_LENGTH     8

// Force an FPGA reboot at the desired address (physical address within the Flash)
void ForceRebootICAP(u32 address);
#endif /* XPAR_XHWICAP_NUM_INSTANCES */

// Perform a simple Erase/Write/Read test on both Flashes
void FwUpdateRunFlashTest(XSpi *spi, uint32_t StartAddr);

uint32_t FwUpdateProgramPage(XSpi *spi, uint32_t StartAddr, uint32_t NumOfPages);

// Setup interrupts and connect the SPI device
int SetupInterruptSystem(XIntc *IntcPtr, XSpi *SpiPtr);

// Write to shared memory
#define CFG_MEM_WRITE(index, data) \
	Xil_Out32(XPAR_AXI_BRAM_CTRL_1_S_AXI_BASEADDR + (index * 4), data)

// Read from shared memory
#define CFG_MEM_READ(index) \
	Xil_In32(XPAR_AXI_BRAM_CTRL_1_S_AXI_BASEADDR + (index * 4))

// An error intercepted at the main level will force the processor
// stuck at a given location, waiting for reset. No grace error is
// supported at this moment
#define STUCK_ON_ERROR(err) \
	xil_printf("dead: An error occurred\n\r"); \
	xil_printf("dead: I'm stuck @L%d\n\r", __LINE__); \
	xil_printf("dead: Latest unexpected value: %d\n\r", err); \
 	CFG_MEM_WRITE(SHAMEM_CMD_STATUS, 0xdeadbeef); \
	while(1) { }


//---- GLOBALS ----------------------------------------------------------------

// From the SPI library
volatile int ErrorCount;
volatile int TransferInProgress;
volatile u8 ReadBuffer[1024];
volatile u8 WriteBuffer[1024];

// Devices
XSpi Spi;
XSpi_Config* SpiCfg;
XIntc InterruptController;

#if XPAR_XHWICAP_NUM_INSTANCES
XHwIcap Icap;
XHwIcap_Config IcapCfg;
#endif /* XPAR_XHWICAP_NUM_INSTANCES */


//---- BODY -------------------------------------------------------------------

int main()
{
	uint32_t status;
    uint32_t cmd;
	uint32_t temp_data;
	uint32_t temp_addr;
	uint32_t init_status;


	////// PREAMBLE ///////////////////////////////////////////////////////////

	// Very early status is nihil
	init_status = 0x00000000;
	CFG_MEM_WRITE(SHAMEM_INIT_STATUS, init_status);
	CFG_MEM_WRITE(SHAMEM_WATERMARK, 0xdeadbeef);

	// Banner
	xil_printf("--------------------------------------------------------------------------------\n\r");
    xil_printf("---- Nuclear Instruments Firmware Upgrade utility\n\r");
    xil_printf("---- Version: %s\n\r", VERSION_STRING);
    xil_printf("---- Latest build: %s\n\r", LATEST_BUILD_STRING);
    xil_printf("--------------------------------------------------------------------------------\n\r");


    ////// INITIALIZATION /////////////////////////////////////////////////////

    // Initialize platform
    xil_printf("info: Initializing platform\n\r");
	init_platform();
	init_status = CFG_MEM_READ(SHAMEM_INIT_STATUS) | (1 << 0);
	CFG_MEM_WRITE(SHAMEM_INIT_STATUS, init_status);

#	if XPAR_XHWICAP_NUM_INSTANCES
	// Initialize ICAP device
    xil_printf("info: Initializing ICAP device\n\r");
	XHwIcap_CfgInitialize(&Icap, &IcapCfg, XPAR_AXI_HWICAP_0_BASEADDR);
	XHwIcap_GetConfigReg(&Icap, 22, &status);
	if(status != 1) {
		STUCK_ON_ERROR(status);
	}
#	endif /* XPAR_XHWICAP_NUM_INSTANCES */
	init_status = CFG_MEM_READ(SHAMEM_INIT_STATUS) | (1 << 4);
	CFG_MEM_WRITE(SHAMEM_INIT_STATUS, init_status);

	// Initialize SPI device
    xil_printf("info: Initializing SPI device\n\r");
    xil_printf("info:    Assumed QSPI Flash configuration: PAGE_SIZE=%d, BYTE_PER_SECTOR=%d\r\n", PAGE_SIZE, BYTE_PER_SECTOR);
	SpiCfg = XSpi_LookupConfig(XPAR_AXI_QUAD_SPI_0_DEVICE_ID);
	if(SpiCfg == NULL) {
		STUCK_ON_ERROR(SpiCfg);
	}
	status = XSpi_CfgInitialize(&Spi, SpiCfg, SpiCfg->BaseAddress);
	init_status = CFG_MEM_READ(SHAMEM_INIT_STATUS) | (1 << 8);
	CFG_MEM_WRITE(SHAMEM_INIT_STATUS, init_status);

	// Initialize interrupts
    xil_printf("info: Initializing interrupts\n\r");
	status = SetupInterruptSystem(&InterruptController, &Spi);
	if(status != XST_SUCCESS) {
		STUCK_ON_ERROR(status);
	}
	init_status = CFG_MEM_READ(SHAMEM_INIT_STATUS) | (1 << 12);
	CFG_MEM_WRITE(SHAMEM_INIT_STATUS, init_status);

	// Miscellanea
	XSpi_SetStatusHandler(&Spi, &Spi, (XSpi_StatusHandler)SpiHandler);
	status = XSpi_SetOptions(&Spi, XSP_MASTER_OPTION | XSP_MANUAL_SSELECT_OPTION);
	if(status != XST_SUCCESS) {
		STUCK_ON_ERROR(status);
	}
	init_status = CFG_MEM_READ(SHAMEM_INIT_STATUS) | (1 << 16);
	CFG_MEM_WRITE(SHAMEM_INIT_STATUS, init_status);

	// Start SPI controller driver
	XSpi_Start(&Spi);
	init_status = CFG_MEM_READ(SHAMEM_INIT_STATUS) | (1 << 20);
	CFG_MEM_WRITE(SHAMEM_INIT_STATUS, init_status);

	// Initialize Flashes
	XSpi_SetSlaveSelect(&Spi, 1);
	SpiFlashQuadEnable(&Spi);
	SpiFlashWriteEnable(&Spi);
	if(status != XST_SUCCESS) {
		STUCK_ON_ERROR(status);
	}
	init_status = CFG_MEM_READ(SHAMEM_INIT_STATUS) | (1 << 24);
	CFG_MEM_WRITE(SHAMEM_INIT_STATUS, init_status);

	// All SPI devices are initialized. Mark the end of the Control section
    xil_printf("info: Initialization completed\n\r");
    CFG_MEM_WRITE(SHAMEM_WATERMARK, 0x0d15ea5e);


    ////// CONTROL LOOP ///////////////////////////////////////////////////////

    // Control loop will wait for any pending command
    CFG_MEM_WRITE(SHAMEM_PENDING_CMD, 0);
	while(1) {
		usleep(100);
		cmd = CFG_MEM_READ(SHAMEM_PENDING_CMD);

     	switch(cmd) {
     		case FWU_NOP :
     			break;

     		case FWU_ERASE_SECTOR :
     			// Read address to erase
 				temp_addr = CFG_MEM_READ(SHAMEM_CMD_ARGUMENT_1);
 				// Read number of sectors to erase
 				temp_data = CFG_MEM_READ(SHAMEM_CMD_ARGUMENT_2);

 				// Erase selected sectors starting at given address
 				QSpiFlashSectorErase(&Spi, temp_addr, temp_data);

 				CFG_MEM_WRITE(SHAMEM_PENDING_CMD, 0);
 	 	 		CFG_MEM_WRITE(SHAMEM_CMD_STATUS, 1);
     			break;

     		case FWU_FLASH_TEST :
     			// Read test base address
 				temp_data = CFG_MEM_READ(SHAMEM_CMD_ARGUMENT_1);

 				// Run test
 				FwUpdateRunFlashTest(&Spi, temp_data);

 		     	CFG_MEM_WRITE(SHAMEM_PENDING_CMD, 0);
     			CFG_MEM_WRITE(SHAMEM_CMD_STATUS, 1);
 				break;

     		case FWU_PROGRAM_PAGE :
     			// Read Flash start address
 				temp_addr = CFG_MEM_READ(SHAMEM_CMD_ARGUMENT_1);
 				// Read number of pages to program
 				temp_data = CFG_MEM_READ(SHAMEM_CMD_ARGUMENT_2);

 				// Program one page at a time
 				temp_data = FwUpdateProgramPage(&Spi, temp_addr, temp_data);
 				CFG_MEM_WRITE(SHAMEM_CMD_RESULT, temp_data);

 				CFG_MEM_WRITE(SHAMEM_PENDING_CMD, 0);
 	 	 		CFG_MEM_WRITE(SHAMEM_CMD_STATUS, 1);
     			break;

     		case FWU_READ_PAGE :
     			// Read starting address
 				temp_addr = CFG_MEM_READ(SHAMEM_CMD_ARGUMENT_1);

 				// Read one page at a time
 				QSpiFlashReadout(&Spi, temp_addr, PAGE_SIZE, ReadBuffer);

 				CFG_MEM_WRITE(SHAMEM_PENDING_CMD, 0);
 	 	 		CFG_MEM_WRITE(SHAMEM_CMD_STATUS, 1);
     			break;

#			ifdef XPAR_XHWICAP_NUM_INSTANCES
     		case FWU_BOOT :
     			// Read boot address
     			temp_addr = CFG_MEM_READ(SHAMEM_CMD_ARGUMENT_1);
     			ForceRebootICAP(temp_addr);

 				CFG_MEM_WRITE(SHAMEM_PENDING_CMD, 0);
     			CFG_MEM_WRITE(SHAMEM_CMD_STATUS, 1);
     			break;
#			endif /* XPAR_XHWICAP_NUM_INSTANCES */

 	 		default :
 	 			// Unsupported command, inform the user and do not reset the
 	 			// pending command
 	 			CFG_MEM_WRITE(SHAMEM_CMD_STATUS, 0xdeadbeef);
 	 			break;
     	}//end_switch(cmd)
     }//end_while(1)


    ////// TAIL ///////////////////////////////////////////////////////////////

 	// Shall never reach this point
 	xil_printf("erro: Unexpected behavior @[%s:L%d]\r\n", __FILE__, __LINE__);
 	CFG_MEM_WRITE(SHAMEM_CMD_STATUS, 0xdeadbeef);
 	while(1) { }

 	cleanup_platform();
    return XST_FAILURE;
}

uint32_t FwUpdateProgramPage(XSpi *spi, uint32_t StartAddr, uint32_t NumOfPages)
{
	unsigned char *data_buffer;
	unsigned char *source_ptr;

	// Prepare data buffer
	data_buffer = malloc(PAGE_SIZE * sizeof(unsigned char));
	if(data_buffer == NULL) {
		return XST_FAILURE;
	}

	for(uint32_t pdx = 0; pdx < NumOfPages; pdx++) {
		// Point to the first Byte
		source_ptr = (unsigned char *)(XPAR_AXI_BRAM_CTRL_1_S_AXI_BASEADDR + (SHAMEM_FIRST_BYTE * 4) + (pdx * PAGE_SIZE / 4));

		// Copy data from BRAM to local buffer
		memcpy(data_buffer, source_ptr, PAGE_SIZE);

		// Download data to Flash
		DownloadSerialDataToQSPIFlash(spi, StartAddr, PAGE_SIZE, data_buffer);
	}//end_for(pdx)

	free(data_buffer);
	return XST_SUCCESS;
}

void FwUpdateRunFlashTest(XSpi *spi, uint32_t StartAddr)
{
	// Data buffer
	unsigned char *data_buffer;
	uint32_t temp_data;

	data_buffer = (unsigned char *)malloc(PAGE_SIZE * sizeof(unsigned char));
	for(int bdx = 0; bdx < PAGE_SIZE; bdx++) {
		data_buffer[bdx] = bdx;
	}

	// Reset the result vector
	CFG_MEM_WRITE(SHAMEM_CMD_RESULT, 0);

	// Write to NOR Flash can happen only after an Erase
	XSpi_SetSlaveSelect(spi, 1);

	// Erase entire sector
	if(QSpiFlashSectorErase(spi, StartAddr, 1) != XST_SUCCESS) {
		return XST_FAILURE;
	}
	temp_data = CFG_MEM_READ(SHAMEM_CMD_STATUS) | 0x00000010;
	CFG_MEM_WRITE(SHAMEM_CMD_STATUS, temp_data);

	QSpiFlashReadout(spi, StartAddr, PAGE_SIZE, ReadBuffer);
	temp_data = CFG_MEM_READ(SHAMEM_CMD_STATUS) | 0x00000100;
	CFG_MEM_WRITE(SHAMEM_CMD_STATUS, temp_data);

	// After an Erase command, the target page shall contain all 1's
	temp_data = 0;
	for(int bdx = 0; bdx < PAGE_SIZE; bdx++) {
		temp_data += (ReadBuffer[bdx] == 0xff ? 0 : 1);
	}
	CFG_MEM_WRITE(SHAMEM_CMD_RESULT, temp_data);

	DownloadSerialDataToQSPIFlash(spi, StartAddr, PAGE_SIZE, data_buffer);
	temp_data = CFG_MEM_READ(SHAMEM_CMD_STATUS) | 0x00001000;
	CFG_MEM_WRITE(SHAMEM_CMD_STATUS, temp_data);

	QSpiFlashReadout(spi, StartAddr, PAGE_SIZE, ReadBuffer);
	temp_data = CFG_MEM_READ(SHAMEM_CMD_STATUS) | 0x00010000;
	CFG_MEM_WRITE(SHAMEM_CMD_STATUS, temp_data);

	// After a Program command, the target page shall contain valid data
	temp_data = 0;
	for(int bdx = 0; bdx < PAGE_SIZE; bdx++) {
		temp_data += (ReadBuffer[bdx] == data_buffer[bdx] ? 0 : 1);
	}
	CFG_MEM_WRITE(SHAMEM_CMD_RESULT, temp_data);

	free(data_buffer);
}

int SetupInterruptSystem(XIntc *IntcPtr, XSpi *SpiPtr)
{

	int Status;

	// Register interrupts
	Status = XIntc_Initialize(IntcPtr, XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_DEVICE_ID);
	if(Status == XST_DEVICE_NOT_FOUND) {
		return Status;
	}

	// Connect SPI source
	Status = XIntc_Connect(IntcPtr, XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_DEVICE_ID, (XInterruptHandler)XSpi_InterruptHandler, SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Start interrupt controller
	Status = XIntc_Start(IntcPtr, XIN_REAL_MODE);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	// Enable interrupt source
	XIntc_Enable(IntcPtr, XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_DEVICE_ID);

	// Init
	Xil_ExceptionInit();

	// Register handler
	Xil_ExceptionRegisterHandler(XPAR_UBLAZE_HIER_MICROBLAZE_0_AXI_INTC_DEVICE_ID, (Xil_ExceptionHandler)XIntc_InterruptHandler, IntcPtr);

	// Enable
	Xil_ExceptionEnable();

	return XST_SUCCESS;
}

#ifdef XPAR_XHWICAP_NUM_INSTANCES
void ForceRebootICAP(u32 address)
{
	u32 Index;

	// Taken from IPROG Using ICAPE section in Chapter 11 of UG570
	u32 iprog_data [HWICAP_EXAMPLE_BITSTREAM_LENGTH] =
	{
	        0xFFFFFFFF, /* @0 Dummy Word */
	        0xAA995566, /* @1 Sync Word */
	        0x20000000, /* @2 Type 1 NOOP */
	        0x30020001, /* @3 Type 1 Write 1 words to WBSTAR */
	        0xdeadbeef, /* @4 Warm boot start address (Load the desired address) */
	        0x30008001, /* @5 Type 1 Write 1 words to CMD */
	        0x0000000F, /* @6 IPROG command */
	        0x20000000  /* @7 Type 1 NOOP  */
	};

	//??while(Index > XHwIcap_ReadReg(XPAR_AXI_HWICAP_0_BASEADDR, XHI_WFV_OFFSET));

	// Update WBSTAR with desired one
	iprog_data[4] = address ;
	for(Index = 0; Index < HWICAP_EXAMPLE_BITSTREAM_LENGTH; Index++) {
                XHwIcap_WriteReg(XPAR_AXI_HWICAP_0_BASEADDR, XHI_WF_OFFSET, iprog_data[Index]);
	}

    XHwIcap_WriteReg(XPAR_AXI_HWICAP_0_BASEADDR, XHI_CR_OFFSET, XHI_CR_WRITE_MASK);

	 while ((XHwIcap_ReadReg(HWICAP_EXAMPLE_BITSTREAM_LENGTH,XHI_CR_OFFSET)) & XHI_CR_WRITE_MASK);

	 while (((XHwIcap_ReadReg(HWICAP_EXAMPLE_BITSTREAM_LENGTH, XHI_SR_OFFSET) & XHI_SR_DONE_MASK) ? 0 : 1) != 0);
	 while (XHwIcap_ReadReg(HWICAP_EXAMPLE_BITSTREAM_LENGTH, XHI_CR_OFFSET) & XHI_CR_WRITE_MASK);
}
#endif /* XPAR_XHWICAP_NUM_INSTANCES */