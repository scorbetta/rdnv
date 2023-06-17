#ifndef __QSPI_FLASH_H__
#define __QSPI_FLASH_H__

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "platform.h"
#include "xparameters.h"
#include "xintc.h"
#include "xspi.h"
#include "xil_types.h"
#include "xil_cache.h"
#include "xil_printf.h"

/*
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are only defined here such that a user can easily
 * change all the needed parameters in one place.
 */
//#define INTC_DEVICE_ID		XPAR_INTC_0_DEVICE_ID
//#define INTC_DEVICE_ID		XPAR_INTC_0_DEVICE_ID
//#define INTC_BASEADDR 		XPAR_INTC_0_BASEADDR
//#define UART_CLOCK_HZ		XPAR_UARTNS550_0_CLOCK_FREQ_HZ
//#define UART_DEVICE_ID		XPAR_UARTNS550_0_DEVICE_ID
//#define UART_IRPT_INTR		XPAR_INTC_0_UARTNS550_0_VEC_ID
//#define	UART_INTR			XPAR_MICROBLAZE_0_AXI_INTC_AXI_UART16550_0_IP2INTC_IRPT_INTR
//#define UART_INTR_MASK 		XPAR_AXI_UART16550_0_IP2INTC_IRPT_MASK
//#define UART_BASEADDR		XPAR_UARTNS550_0_BASEADDR
//#define TMRCTR_DEVICE_ID	XPAR_TMRCTR_0_DEVICE_ID
//#define TIMER_INTR			XPAR_MICROBLAZE_0_AXI_INTC_AXI_TIMER_0_INTERRUPT_INTR
//#define TMRCTR_INTERRUPT_ID	XPAR_INTC_0_TMRCTR_0_VEC_ID
//#define TIMER_INTR_MASK 	XPAR_AXI_TIMER_0_INTERRUPT_MASK
//#define	TIMER_BASEADDR		XPAR_TMRCTR_0_BASEADDR
//#define SPI_DEVICE_ID		XPAR_SPI_0_DEVICE_ID
//#define SPI_INTR_ID			XPAR_INTC_0_SPI_0_VEC_ID
//#define	SPI_INTR			XPAR_MICROBLAZE_0_AXI_INTC_AXI_QUAD_SPI_0_IP2INTC_IRPT_INTR
//#define SPI_INTR_MASK 		XPAR_AXI_QUAD_SPI_0_IP2INTC_IRPT_MASK
//#define SPI_BASEADDR		XPAR_SPI_0_BASEADDR
/*****************************************************************************************/
//#define INTC		    	static XIntc
//#define INTC_HANDLER		XIntc_InterruptHandler
//#define TIMER_BASE_ADDR		XPAR_AXI_TIMER_0_BASEADDR
//#define TIMER_CNTR_0	 	0
//#define RESET_VALUE	 		0x00000000
//#define UART_BAUDRATE		115200
//#define STDOUT_BASEADDR XPAR_AXI_UART16550_0_BASEADDR
/*****************************************************************************************/
//#define STDOUT_IS_16550
//#ifndef ENABLE_ICACHE
//#define ENABLE_ICACHE()		Xil_ICacheEnable()
//#endif
//#ifndef	ENABLE_DCACHE
//#define ENABLE_DCACHE()		Xil_DCacheEnable()
//#endif
//#ifndef	DISABLE_ICACHE
//#define DISABLE_ICACHE()	Xil_ICacheDisable()
//#endif
//#ifndef DISABLE_DCACHE
//#define DISABLE_DCACHE()	Xil_DCacheDisable()
//#endif
/*************************************************************************************************/
//#define SPI_SELECT 									0x01

#define COMMAND_WRITE_STATUS_REGISTER  				0x01 /* Write Status registers */
#define COMMAND_STATUSREG_READ						0x05 /* Read Status register */
#define	COMMAND_WRITE_ENABLE						0x06 /* Write enable command */
#define COMMAND_ENTER_QUAD_MODE						0x35 /* Enter QUAD mode */
#define COMMAND_EXIT_QUAD_MODE						0xF5 /* Leave QUAD mode */
#define COMMAND_ENTER_4BYTE_ADDRESS_MODE			0xB7 /* Enter 4-Byte addressing mode */
#define COMMAND_EXIT_4BYTE_ADDRESS_MODE				0xE9 /* Leave 4-Byte addressing mode */
#define COMMAND_READ_FLAG_STATUS 					0x70
#define	COMMAND_CLEAR_FLAG_STATUS					0x50
#define	COMMAND_WRITE_DISABLE						0x04 /* Write disable command */
#define COMMAND_READ_EXTENDED_ADDRESS				0xC8
#define COMMAND_WRITE_EXTENDED_ADDRESS				0xC5
#define COMMAND_PAGE_PROGRAM						0x02 /* Page Program command */
#define COMMAND_QUAD_WRITE							0x32 /* Quad Input Fast Program */
#define COMMAND_4BYTE_PAGE_PROGRAM 					0x12
#define COMMAND_READ_ID								0x9E /* READ ID 9E/9Fh  */
#define COMMAND_EXTENDED_QUAD_INPUT_FAST_PROGRAM	0x32 //32, 12h 38h note SUPPORTED
#define COMMAND_READ_DISCOVERY						0x5A /* READ SERIAL FLASH DISCOVERY PARAMETER 5Ah */
#define COMMAND_RANDOM_READ							0x03 /* Random read command */
#define COMMAND_DUAL_READ							0x3B /* Dual Output Fast Read */
#define COMMAND_DUAL_IO_READ						0xBB /* Dual IO Fast Read */
#define COMMAND_QUAD_READ							0x6B /* Quad Output Fast Read */
#define COMMAND_QUAD_IO_READ						0xEB /* Quad IO Fast Read */
#define COMMAND_4BYTE_READ							0x13 /* 4-BYTE READ */
#define COMMAND_4BYTE_FAST_READ 					0x0C /* 4-BYTE FAST READ */
#define COMMAND_4BYTE_DUAL_OUTPUT_FAST_READ			0x3C /* 4-BYTE DUAL OUTPUT FAST READ */
#define COMMAND_4BYTE_DUAL_INPUTOUTPUT_FAST_READ	0XBC /* 4-BYTE DUAL INPUT/OUTPUT FAST READ*/
#define COMMAND_4BYTE_QUAD_OUTPUT_FAST_READ			0x6C /* 4-BYTE QUAD OUTPUT FAST READ */
#define COMMAND_4BYTE_QUAD_INPUTOUTPUT_FASTREAD		0xEC /* 4-BYTE QUAD INPUT/OUTPUT FASTREAD*/
#define COMMAND_SECTOR_ERASE						0xD8 /* Sector Erase command */
//#define COMMAND_BULK_ERASE							0xC7 /* Bulk Erase command */
#define COMMAND_DIE_ERASE							0xc4
#define COMMAND_SUBSECTOR_ERASE 					0x20 /* SUBSECTOR ERASE 20h */
#define COMMAND_4BYTE_SUBSECTOR_ERASE 				0x21 /* 4-BYTE SUBSECTOR ERASE 21h */

/**
 * This definitions specify the EXTRA bytes in each of the command
 * transactions. This count includes Command byte, address bytes and any don't care bytes needed.
 */
#define READ_WRITE_EXTRA_BYTES		4 /* Read/Write extra bytes */
#define	WRITE_ENABLE_BYTES			1 /* Write Enable bytes */
#define SECTOR_ERASE_BYTES			4 /* Sector erase extra bytes */
#define BULK_ERASE_BYTES			1 /* Bulk erase extra bytes */
#define STATUS_READ_BYTES			2 /* Status read bytes count */
#define STATUS_WRITE_BYTES			2 /* Status write bytes count */
#define FLASH_SR_IS_READY_MASK		0x01 /* Ready mask */

/*
 * Number of bytes per page in the flash device.
 */
#define PAGE_SIZE					256
#define NUMB_SECTORS				512
#define	BYTE_PER_SECTOR				65536
#define	NUMB_SUBSECTORS				8192
#define	BYTE_PER_SUBSECTOR			4096
#define NOB_PAGES					131072


/*
 * Address of the page to perform Erase, Write and Read operations.
 */
//#define FLASH_TEST_ADDRESS0			0x00000000
//#define FLASH_TEST_ADDRESS1			0x00F50000
//#define BINFILESIZE					2242764
/*
 * Byte Positions.
 */
#define BYTE1						0 /* Byte 1 position */
#define BYTE2						1 /* Byte 2 position */
#define BYTE3						2 /* Byte 3 position */
#define BYTE4						3 /* Byte 4 position */
#define BYTE5						4 /* Byte 5 position */
#define BYTE6						5 /* Byte 6 position */
#define BYTE7						6 /* Byte 7 position */
#define BYTE8						7 /* Byte 8 position */
#define DUAL_READ_DUMMY_BYTES		2
#define QUAD_READ_DUMMY_BYTES		4
#define DUAL_IO_READ_DUMMY_BYTES	2
#define QUAD_IO_READ_DUMMY_BYTES	5

/**
 * Enable Writes to an SPI Flash device
 *
 * \param [in] SpiPtr A pointer to the XSpi device
 * \return XST_SUCCESS on success, XST_FAILURE otherwise
 */
int SpiFlashWriteEnable(XSpi *SpiPtr);

/**
 * Write data to an SPI Flash device
 *
 * \param [in] SpiPtr A pointer to the XSpi device
 * \param [in] Addr The target address
 * \param [in] ByteCount The number of Bytes to Write
 * \param [in] WriteCmd The Write command to send (see SPI Flash device specs)
 * \param [in] DataBuffer A pointer to the buffer containing the data to write
 * \return XST_SUCCESS on success, XST_FAILURE otherwise
 */
int SpiFlashWrite(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 WriteCmd, unsigned char *DataBuffer);
int QSpiFlashProgram(XSpi *SpiPtr, u32 StartAddr,u32 NoOfPage, unsigned char *data_buffer);
int  DownloadSerialDataToQSPIFlash(XSpi *SpiPtr, u32 StartAddr, u32 NoByteToRead, unsigned char *data_buffer);

/**
 * Erase an entire sector in Flash
 *
 * \param [in] SpiPtr A pointer to the XSpi device
 * \param [in] Addr Any address within a valid sector to be erased
 * \return XST_SUCCESS on success, XST_FAILURE otherwise
 */
int SpiFlashSectorErase(XSpi *SpiPtr, u32 Addr);
int QSpiFlashSectorErase(XSpi *SpiPtr, u32 OfsetAddr, u32 SectCount);

/**
 * Read the status register of an SPI Flash device
 *
 * \param [in] SpiPtr A pointer to the XSpi device
 * \return XST_SUCCESS on success, XST_FAILURE otherwise
 */
int SpiFlashGetStatus(XSpi *SpiPtr);

/**
 * Wait for an SPI device to be ready
 *
 * \param [in] SpiPtr A pointer to an SPI Flash device
 * return XST_SUCCESS when the SPI device is ready, XST_FAILURE upon failure
 */
int SpiFlashWaitForFlashReady(XSpi *SpiPtr);

void SpiHandler(void *CallBackRef, u32 StatusEvent, unsigned int ByteCount);

/**
 * Read the identifier register of an SPI Flash device, and try to decode it
 *
 * \param [in] SpiPtr A pointer to an SPI Flash device
 * \return XST_SUCCESS on success, XST_FAILURE otherwise
 */
int SpiFlashReadID(XSpi *SpiPtr);


int QSpiFlashReadout(XSpi *SpiPtr, u32 StartAddr, u32 NoByteToRead, unsigned char *target_buffer);

/**
 * Force the SPI Flash device leaving the 4-Byte address state
 *
 * return XST_SUCCESS on success, XST_FAILURE otherwise
 */
int SpiFlash4byteExit(XSpi *SpiPtr);

int SpiFlashRead(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 ReadCmd, unsigned char *DDR_MEMB1);

int SpiFlashQuadEnable(XSpi *SpiPtr);

int QSpiFlashBulkErase(XSpi *SpiPtr);

int SpiFlashBulkErase(XSpi *SpiPtr);

#endif /* __QSPI_FLASH_H__ */


//int qspi_ease_entire_flash (void);