#include "qspi_flash.h"

// Reused
extern volatile int TransferInProgress;
extern volatile int ErrorCount;
extern volatile u8 ReadBuffer[1024];
extern volatile u8 WriteBuffer[1024];

int QSpiFlashSectorErase(XSpi *SpiPtr, u32 OfsetAddr, u32 SectCount)
{
	int Status;

	//@SC// Sanity checks
	//@SCif(SectCount > NUMB_SECTORS) {
	//@SC	xil_printf("erro: Invalid number of sectors selected: %d (expected <= %d)\r\n", SectCount, NUMB_SECTORS);
	//@SC	return XST_FAILURE;
	//@SC}

	xil_printf("QSPI erase starts in range: (0x%08x, 0x%08x)\r\n", OfsetAddr, (OfsetAddr + (BYTE_PER_SECTOR * SectCount)));

	Status = SpiFlashWriteEnable(SpiPtr);
	if(Status != XST_SUCCESS) {
		xil_printf("erro: QSpiFlashSectorErase() failed\n\r");
		return XST_FAILURE;
	}

	XSpi_Start(SpiPtr);
	Status = SpiFlashWriteEnable(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	for(int Count_int=0; Count_int< SectCount; Count_int++) {
		Status = SpiFlashWriteEnable(SpiPtr);
		if(Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		Status = SpiFlashSectorErase(SpiPtr, OfsetAddr);
		if(Status != XST_SUCCESS) {
			return XST_FAILURE;
		}
		else {
			OfsetAddr = (OfsetAddr + BYTE_PER_SECTOR);
		}
	}

	xil_printf("QSPI erase done\r\n");
	return XST_SUCCESS;
}

int  DownloadSerialDataToQSPIFlash(XSpi *SpiPtr, u32 StartAddr, u32 NoByteToRead, unsigned char *data_buffer)
{
		int quq_int, remaind_int, FileByteCount, NoOfSector, NoOfPage;
		FileByteCount = PAGE_SIZE;

		  NoOfSector = (FileByteCount/BYTE_PER_SECTOR);
		  NoOfPage = (FileByteCount/PAGE_SIZE);

		  quq_int = (FileByteCount / BYTE_PER_SECTOR);
		  remaind_int = (FileByteCount - (quq_int * BYTE_PER_SECTOR));

		  if (remaind_int != 0) {
				  NoOfSector = (NoOfSector +1);
				  }
		  quq_int = (FileByteCount / PAGE_SIZE);
		  remaind_int = (FileByteCount - ( quq_int * PAGE_SIZE));

		  if (remaind_int != 0) {
				   NoOfPage = (NoOfPage+1);
				}

		  xil_printf("Programming QSPI flash starts @0x%08x\r\n", StartAddr);
		  QSpiFlashProgram(SpiPtr, StartAddr, NoOfPage, data_buffer);
		  xil_printf("Programming QSPI flash ends\r\n");
		  return XST_SUCCESS;
	}



int QSpiFlashReadout(XSpi *SpiPtr, u32 StartAddr, u32 NoByteToRead, unsigned char *target_buffer)
{
	int quq_int, remaind_int, FileByteCount, NoOfSector, NoOfPage;
	FileByteCount = NoByteToRead;

	  NoOfSector = (FileByteCount/BYTE_PER_SECTOR);
	  NoOfPage = (FileByteCount/PAGE_SIZE);

	  quq_int = (FileByteCount / BYTE_PER_SECTOR);
	  remaind_int = (FileByteCount - (quq_int * BYTE_PER_SECTOR));

	  if (remaind_int != 0) {
			  NoOfSector = (NoOfSector +1);
			  }
	  quq_int = (FileByteCount / PAGE_SIZE);
	  remaind_int = (FileByteCount - ( quq_int * PAGE_SIZE));

	  if (remaind_int != 0) {
			   NoOfPage = (NoOfPage+1);
			}

	  print ("\r\nNoOfSector= "); putnum(NoOfSector);
	  print ("\r\nNoOfPage= "); putnum(NoOfPage);
	  print ("\r\nProgramming QSPI flash Start");




	u32 ddrvector=0;
		int Status;
		//if (qspi_init_flag ==0)
		//			{
		//				Status = System_init_startup ();
		//				if (Status != XST_SUCCESS) {
		//							return XST_FAILURE;
		//						} else qspi_init_flag=1;
		//
		//				}
		//Status = XSpi_SetSlaveSelect(SpiPtr, SpiPtr->SlaveSelectReg);
		//if(Status != XST_SUCCESS) {
		//	return XST_FAILURE;
		//}

		XSpi_Start(SpiPtr);

		while (NoOfPage !=0)
				{
					Status = SpiFlashRead(SpiPtr, StartAddr, PAGE_SIZE, COMMAND_4BYTE_READ, target_buffer);
										if(Status != XST_SUCCESS) {
											return XST_FAILURE;
										} else
										{
												NoOfPage--;
												StartAddr = (StartAddr + PAGE_SIZE);
												ddrvector = (ddrvector + PAGE_SIZE);
										}
			}
		return XST_SUCCESS;
}

void SpiHandler(void *CallBackRef, u32 StatusEvent, unsigned int ByteCount)
{
	TransferInProgress = FALSE;
	if (StatusEvent != XST_SPI_TRANSFER_DONE) {
		ErrorCount++;
	}
}

int SpiFlashWriteEnable(XSpi *SpiPtr)
{
	int Status;
	Status = SpiFlashWaitForFlashReady(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	WriteBuffer[BYTE1] = COMMAND_WRITE_ENABLE;
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, WRITE_ENABLE_BYTES);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}

int SpiFlashSectorErase(XSpi *SpiPtr, u32 Addr)
{
	int Status;
	Status = SpiFlash4bytemodeEnable(SpiPtr);
		if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	//Status = SpiReadExtendedAddressRegister(&Spi[0]);
	//	if(Status != XST_SUCCESS) {
	//		return XST_FAILURE;
	//	}

	Status = SpiFlashWriteEnable(SpiPtr);
			if(Status != XST_SUCCESS) {
				return XST_FAILURE;
			}
	Status = SpiFlashWaitForFlashReady(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
#	if 0
	WriteBuffer[BYTE1] = COMMAND_WRITE_EXTENDED_ADDRESS;
	WriteBuffer[BYTE2] = (u8) (0xFF);
	WriteBuffer[BYTE3] = COMMAND_SECTOR_ERASE;
	WriteBuffer[BYTE4] = (u8) (Addr >> 24);
	WriteBuffer[BYTE5] = (u8) (Addr >> 16);
	WriteBuffer[BYTE6] = (u8) (Addr >> 8);
	WriteBuffer[BYTE7] = (u8) (Addr);
#	else
	WriteBuffer[BYTE1] = COMMAND_SECTOR_ERASE;
	WriteBuffer[BYTE2] = (u8) (Addr >> 24);
	WriteBuffer[BYTE3] = (u8) (Addr >> 16);
	WriteBuffer[BYTE4] = (u8) (Addr >> 8);
	WriteBuffer[BYTE5] = (u8) (Addr);
#	endif

	TransferInProgress = TRUE;
	//Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, SECTOR_ERASE_BYTES+3);
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, SECTOR_ERASE_BYTES+1);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}

int QSpiFlashProgram(XSpi *SpiPtr, u32 StartAddr, u32 NoOfPage, unsigned char *data_buffer)
{
		u32 ddrvector=0;
		int Status;
		//if (qspi_init_flag ==0)
		//			{
		//				Status = System_init_startup ();
		//				if (Status != XST_SUCCESS) {
		//							return XST_FAILURE;
		//						} else qspi_init_flag=1;
		//
		//				}
		//Status = XSpi_SetSlaveSelect(SpiPtr, SpiPtr->SlaveSelectReg);
		//if(Status != XST_SUCCESS) {
		//	return XST_FAILURE;
		//}

		XSpi_Start(SpiPtr);
		Status = SpiFlashWriteEnable(SpiPtr);
		if(Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		while (NoOfPage !=0)
				{
						Status = SpiFlashWriteEnable(SpiPtr);
							if(Status != XST_SUCCESS) {
								return XST_FAILURE;
							}
					Status = SpiFlashWrite(SpiPtr, StartAddr, PAGE_SIZE, COMMAND_PAGE_PROGRAM, data_buffer);
										if(Status != XST_SUCCESS) {
											return XST_FAILURE;
										} else
										{
												NoOfPage--;
												StartAddr = (StartAddr + PAGE_SIZE);
												ddrvector = (ddrvector + PAGE_SIZE);
										}
			}
		return XST_SUCCESS;
}


int SpiFlashRead(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 ReadCmd, unsigned char *DDR_MEMB1)
{

	int Status;
	//unsigned char *DDR_MEMB1 = (unsigned char *)DDR_ADDR0;
	Status = SpiFlash4bytemodeEnable(SpiPtr);
				if (Status != XST_SUCCESS) {
				return XST_FAILURE;
			}
		Status = SpiFlashWriteEnable(SpiPtr);
			if(Status != XST_SUCCESS) {
				return XST_FAILURE;
		}

	Status = SpiFlashWaitForFlashReady(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	WriteBuffer[BYTE1] = ReadCmd;
	WriteBuffer[BYTE2] = (u8) (Addr >> 24);
	WriteBuffer[BYTE3] = (u8) (Addr >> 16);
	WriteBuffer[BYTE4] = (u8) (Addr >> 8);
	WriteBuffer[BYTE5] = (u8) Addr;

	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, DDR_MEMB1,
				(ByteCount + READ_WRITE_EXTRA_BYTES +1));
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}
	Status = SpiFlash4byteExit(SpiPtr);
		if (Status != XST_SUCCESS) {
				return XST_FAILURE;
		}
	return XST_SUCCESS;
}

int SpiFlashReadID(XSpi *SpiPtr)
{
	int 	Status;
	Status = SpiFlashWaitForFlashReady(SpiPtr);
		if(Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

	WriteBuffer[BYTE1] = COMMAND_READ_ID;
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, ReadBuffer,
			READ_WRITE_EXTRA_BYTES);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}
		 if ( (ReadBuffer[1] == 0x20))
		 {
			 xil_printf("\n\rManufacturer ID:\t0x%x\t:= MICRON\n\r", ReadBuffer[1]);
			 if ( (ReadBuffer[2] == 0xBA))
			 {
				 xil_printf("Memory Type:\t\t0x%x\t:= N25Q 3V0\n\r", ReadBuffer[2]);
			 }
			 else
			 {
				 if ((ReadBuffer[2] == 0xBB))
				 	 {
					 	 xil_printf("Memory Type:\t\t0x%x\t:= N25Q 1V8\n\r", ReadBuffer[2]);
				 	 } else xil_printf("Memory Type:\t\t0x%x\t:= QSPI Data\n\r", ReadBuffer[2]);
			 }
			 if ((ReadBuffer[3] == 0x18))
			 	 {
				 xil_printf("Memory Capacity:\t0x%x\t:=\t128Mbit\n\r", ReadBuffer[3]);
			 	 }
			 	 else if ( (ReadBuffer[3] == 0x19))
			 	 	 {
			 		 	 xil_printf("Memory Capacity:\t0x%x\t:= 256Mbit\n\r", ReadBuffer[3]);
			 	 	 }
			 	 	 else if ((ReadBuffer[3] == 0x20))
			 	 	 	 {
				 	 	 	 xil_printf("Memory Capacity:\t0x%x\t:= 512Mbit\n\r", ReadBuffer[3]);
			 			 }
			 	 	 	 else if ((ReadBuffer[3] == 0x21))
			 			 	 {
			 	 	 		 	 xil_printf("Memory Capacity:\t0x%x\t:= 1024Mbit\n\r", ReadBuffer[3]);
			 			 	 	 }
		 }
		 else if ((ReadBuffer[1] == 0x01))
		 {
			 xil_printf("\n\rManufacturer ID: \tSPANSION\n\r");
			 if ((ReadBuffer[3] == 0x18))
			  	 {
			 	 	 xil_printf("Memory Capacity\t=\t256Mbit\n\r");
			  	 }
			  	 else if ((ReadBuffer[3] == 0x19))
			  	 	 {
			  	 	 	 xil_printf("Memory Capacity\t=\t512Mbit\n\r");
			 		 }
			  	 	 else if ((ReadBuffer[3] == 0x20))
				 		{
			  	 	 	 	 xil_printf("Memory Capacity\t=\t1024Mbit\n\r");

				 			 	 }
		 }
		 else if ((ReadBuffer[1] == 0xEF))
		 		 {
		 			 xil_printf("\n\rManufacturer ID\t=\tWINBOND\n\r");
		 			 if ((ReadBuffer[3] == 0x18))
		 			  	 {
		 			 	 	 xil_printf("Memory Capacity\t=\t128Mbit\n\r");
		 			  	 }
		 }

	return XST_SUCCESS;
}

int SpiFlashWaitForFlashReady(XSpi *SpiPtr)
{
	int Status;
	u8 StatusReg;

	while(1) {

		Status = SpiFlashGetStatus(SpiPtr);
		if(Status != XST_SUCCESS) {
			return XST_FAILURE;
		}
		StatusReg = ReadBuffer[1];
		if((StatusReg & FLASH_SR_IS_READY_MASK) == 0) {
			break;
		} else xil_printf("%c%c%c%c%c%c",95,8,92,8,47,8);

	}
 return XST_SUCCESS;
}

int SpiFlash4bytemodeEnable(XSpi *SpiPtr)
{
	int Status;

	Status = SpiFlashWriteEnable(SpiPtr);
		if(Status != XST_SUCCESS) {
			return XST_FAILURE;
		}
	/*
	 * Wait while the Flash is busy.
	 */
	Status = SpiFlashWaitForFlashReady(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Prepare the COMMNAD_ENTER_4BYTE_ADDRESS_MODE.
	 */
	WriteBuffer[BYTE1] = COMMAND_ENTER_4BYTE_ADDRESS_MODE;

	/*
	 * Initiate the Transfer.
	 */
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL,
				WRITE_ENABLE_BYTES);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Wait till the Transfer is complete and check if there are any errors
	 * in the transaction..
	 */
	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

int SpiFlashWrite(XSpi *SpiPtr, u32 Addr, u32 ByteCount, u8 WriteCmd, unsigned char *DataBuffer)
{
	u32 Index;
	int Status;
	Status = SpiFlash4bytemodeEnable(SpiPtr);
				if (Status != XST_SUCCESS) {
				return XST_FAILURE;
			}
		Status = SpiFlashWriteEnable(SpiPtr);
			if(Status != XST_SUCCESS) {
				return XST_FAILURE;
		}

	Status = SpiFlashWaitForFlashReady(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	WriteBuffer[BYTE1] = WriteCmd;
	WriteBuffer[BYTE2] = (u8) (Addr >> 24);
	WriteBuffer[BYTE3] = (u8) (Addr >> 16);
	WriteBuffer[BYTE4] = (u8) (Addr >> 8);
	WriteBuffer[BYTE5] = (u8) Addr;

	for(Index = 5; Index < (ByteCount + READ_WRITE_EXTRA_BYTES +1); Index++) {
			WriteBuffer[Index] = DataBuffer[Index-5];
		}

	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, (ByteCount + READ_WRITE_EXTRA_BYTES +1));
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}
	Status = SpiFlash4byteExit(SpiPtr);
		if (Status != XST_SUCCESS) {
				return XST_FAILURE;
		}
	return XST_SUCCESS;
}

int SpiFlash4byteExit(XSpi *SpiPtr)
{
	int Status;

	Status = SpiFlashWriteEnable(SpiPtr);
	if(Status != XST_SUCCESS) {
			return XST_FAILURE;
	}
		/*
		 * Wait while the Flash is busy.
		 */
		Status = SpiFlashWaitForFlashReady(SpiPtr);
		if(Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		/*
		 * Prepare the WriteBuffer.
		 */
		WriteBuffer[BYTE1] = COMMAND_EXIT_4BYTE_ADDRESS_MODE;

		/*
		 * Initiate the Transfer.
		 */
		TransferInProgress = TRUE;
		Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL,
					WRITE_ENABLE_BYTES);
		if(Status != XST_SUCCESS) {
			return XST_FAILURE;
		}

		/*
		 * Wait till the Transfer is complete and check if there are any errors
		 * in the transaction..
		 */
		while(TransferInProgress);
		if(ErrorCount != 0) {
			ErrorCount = 0;
			return XST_FAILURE;
		}
		return XST_SUCCESS;
}
int SpiFlashGetStatus(XSpi *SpiPtr)
{
	int Status;

	WriteBuffer[BYTE1] = COMMAND_STATUSREG_READ;

	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, ReadBuffer,
						STATUS_READ_BYTES);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

int SpiFlashQuadEnable(XSpi *SpiPtr)
{
	int Status;
	Status = SpiFlashWriteEnable(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	Status = SpiFlashWaitForFlashReady(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	WriteBuffer[BYTE1] = 0x01;
	WriteBuffer[BYTE2] = 0x01;
	WriteBuffer[BYTE3] = 0x01; /* QE = 1 */
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, 3);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}
	Status = SpiFlashWaitForFlashReady(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	WriteBuffer[BYTE1] = COMMAND_ENTER_QUAD_MODE; //0x35;
	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, ReadBuffer,
						STATUS_READ_BYTES);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}

int QSpiFlashBulkErase(XSpi *SpiPtr)
{
	int Status;

	Status = SpiFlashWriteEnable(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = SpiFlashBulkErase(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = SpiFlashQuadEnable(SpiPtr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

int SpiFlashBulkErase(XSpi *SpiPtr)
{
	int Status;
	Status = SpiFlashWaitForFlashReady(SpiPtr);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	//WriteBuffer[BYTE1] = COMMAND_BULK_ERASE;
	WriteBuffer[BYTE1] = COMMAND_DIE_ERASE;

	TransferInProgress = TRUE;
	Status = XSpi_Transfer(SpiPtr, WriteBuffer, NULL, BULK_ERASE_BYTES+1);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	while(TransferInProgress);
	if(ErrorCount != 0) {
		ErrorCount = 0;
		return XST_FAILURE;
	}
	return XST_SUCCESS;
}