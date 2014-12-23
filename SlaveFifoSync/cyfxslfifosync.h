//----------------------------------------------------------------------------------
// Slave FIFO Synchronous mode
// CYUSB3014 Stream In/Out with Auto or Manual DMA Channels
// This file contains the constants and definitions used by the Slave FIFO app
//----------------------------------------------------------------------------------
#ifndef _INCLUDED_CYFXSLFIFOASYNC_H_
#define _INCLUDED_CYFXSLFIFOASYNC_H_
#include "cyu3externcstart.h"
#include "cyu3types.h"
#include "cyu3usbconst.h"
//----------------------------------------------------------------------------------
// 16/32 bit GPIF Configuration select (0/1)
//----------------------------------------------------------------------------------
#define CY_FX_SLFIFO_GPIF_16_32BIT_CONF_SELECT (0)
//----------------------------------------------------------------------------------
// Define DMA AUTO/MANUAL Channel
//----------------------------------------------------------------------------------
//#define MANUAL_DMA (1)
#define AUTO_DMA (1)
//----------------------------------------------------------------------------------
// Define transmission mode
//----------------------------------------------------------------------------------
//#define LOOPBACK (1)
#define STREAM_IN_OUT (1)
//----------------------------------------------------------------------------------
// Set mode constants
//----------------------------------------------------------------------------------
#ifdef LOOPBACK
	#define BURST_LEN 1
	#define DMA_BUF_SIZE						  (1)
	#define CY_FX_SLFIFO_DMA_BUF_COUNT_P_2_U      (2) // Slave FIFO P_2_U channel buffer count - Used with AUTO DMA channel 
	#define CY_FX_SLFIFO_DMA_BUF_COUNT_U_2_P 	  (2) // Slave FIFO U_2_P channel buffer count - Used with AUTO DMA channel 
#else
	#define BURST_LEN 16
	#define DMA_BUF_SIZE						 (16) 
	#define CY_FX_SLFIFO_DMA_BUF_COUNT_P_2_U      (8) // Slave FIFO P_2_U channel buffer count 
	#define CY_FX_SLFIFO_DMA_BUF_COUNT_U_2_P 	  (4) // Slave FIFO U_2_P channel buffer count 
#endif
//----------------------------------------------------------------------------------
// Set DMA constants
//----------------------------------------------------------------------------------
#define CY_FX_SLFIFO_DMA_BUF_COUNT      (2)                   /* Slave FIFO channel buffer count - This is used with MANUAL DMA channel */
#define CY_FX_SLFIFO_DMA_TX_SIZE        (0)	                  /* DMA transfer size is set to infinite */
#define CY_FX_SLFIFO_DMA_RX_SIZE        (0)	                  /* DMA transfer size is set to infinite */
#define CY_FX_SLFIFO_THREAD_STACK       (0x0400)              /* Slave FIFO application thread stack size */
#define CY_FX_SLFIFO_THREAD_PRIORITY    (8)                   /* Slave FIFO application thread priority */
//----------------------------------------------------------------------------------
// Endpoint and socket definitions for the Slave FIFO application
//----------------------------------------------------------------------------------
#define CY_FX_EP_PRODUCER               0x01    /* EP 1 OUT */
#define CY_FX_EP_CONSUMER               0x81    /* EP 1 IN */
#define CY_FX_PRODUCER_USB_SOCKET    CY_U3P_UIB_SOCKET_PROD_1    /* USB Socket 1 is producer */
#define CY_FX_CONSUMER_USB_SOCKET    CY_U3P_UIB_SOCKET_CONS_1    /* USB Socket 1 is consumer */
#define CY_FX_PRODUCER_PPORT_SOCKET    CY_U3P_PIB_SOCKET_0    /* P-port Socket 0 is producer */
#define CY_FX_CONSUMER_PPORT_SOCKET    CY_U3P_PIB_SOCKET_3    /* P-port Socket 3 is consumer */
//----------------------------------------------------------------------------------
// Extern definitions for the USB Descriptors
//----------------------------------------------------------------------------------
extern const uint8_t CyFxUSB20DeviceDscr[];
extern const uint8_t CyFxUSB30DeviceDscr[];
extern const uint8_t CyFxUSBDeviceQualDscr[];
extern const uint8_t CyFxUSBFSConfigDscr[];
extern const uint8_t CyFxUSBHSConfigDscr[];
extern const uint8_t CyFxUSBBOSDscr[];
extern const uint8_t CyFxUSBSSConfigDscr[];
extern const uint8_t CyFxUSBStringLangIDDscr[];
extern const uint8_t CyFxUSBManufactureDscr[];
extern const uint8_t CyFxUSBProductDscr[];
#include "cyu3externcend.h"
#endif
