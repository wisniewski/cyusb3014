//----------------------------------------------------------------------------------
// Slave FIFO Synchronous mode
// CYUSB3014 Stream In/Out with Auto or Manual DMA Channels
//----------------------------------------------------------------------------------
#include "cyu3system.h"
#include "cyu3os.h"
#include "cyu3dma.h"
#include "cyu3error.h"
#include "cyu3usb.h"
#include "cyfxslfifosync.h"
#include "cyu3gpif.h"
#include "cyu3pib.h"
#include "pib_regs.h"
#include "cyfxgpif2config.h" // GPIF II Designer

CyU3PThread slFifoAppThread;  // Slave FIFO application thread structure
CyU3PDmaChannel glChHandleSlFifoUtoP; // DMA Channel handle for U2P transfer.
CyU3PDmaChannel glChHandleSlFifoPtoU; // DMA Channel handle for P2U transfer.

uint32_t glDMARxCount = 0; // Counter to track the number of buffers received from USB.
uint32_t glDMATxCount = 0; // Counter to track the number of buffers sent to USB.
CyBool_t glIsApplnActive = CyFalse; // Whether the loopback application is active or not.

//----------------------------------------------------------------------------------
// Application Error Handler
//----------------------------------------------------------------------------------
void CyFxAppErrorHandler(CyU3PReturnStatus_t apiRetStatus) 
{
	while(1)
	{
        CyU3PThreadSleep(100);
    }
}

//----------------------------------------------------------------------------------
// DMA callback function to handle the produce events for U to P transfers.
//----------------------------------------------------------------------------------
void CyFxSlFifoUtoPDmaCallback(CyU3PDmaChannel *chHandle, CyU3PDmaCbType_t type,
		CyU3PDmaCBInput_t *input)
{
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	if (type == CY_U3P_DMA_CB_PROD_EVENT)
	{
		/* This is a produce event notification to the CPU. This notification is
		 * received upon reception of every buffer. The buffer will not be sent
		 * out unless it is explicitly committed. The call shall fail if there
		 * is a bus reset / usb disconnect or if there is any application error. */
		status = CyU3PDmaChannelCommitBuffer(chHandle, input->buffer_p.count, 0);

		/* Increment the counter. */
		glDMARxCount++;
	}
}
//----------------------------------------------------------------------------------
// DMA callback function to handle the produce events for P to U transfers.
//----------------------------------------------------------------------------------
void CyFxSlFifoPtoUDmaCallback(CyU3PDmaChannel *chHandle, CyU3PDmaCbType_t type,
		CyU3PDmaCBInput_t *input)
{
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;

	if (type == CY_U3P_DMA_CB_PROD_EVENT)
	{
		/* This is a produce event notification to the CPU. This notification is
		 * received upon reception of every buffer. The buffer will not be sent
		 * out unless it is explicitly committed. The call shall fail if there
		 * is a bus reset / usb disconnect or if there is any application error. */
		status = CyU3PDmaChannelCommitBuffer(chHandle, input->buffer_p.count, 0);

		/* Increment the counter. */
		glDMATxCount++;
	}
}

//----------------------------------------------------------------------------------
// This function starts the slave FIFO loop application. This is called
// when a SET_CONF event is received from the USB host. The endpoints
// are configured and the DMA pipe is setup in this function.
//----------------------------------------------------------------------------------
void CyFxSlFifoApplnStart(void)
{
	uint16_t size = 0;
	uint8_t burst_length = 0;
	CyU3PEpConfig_t epCfg;
	CyU3PDmaChannelConfig_t dmaCfg;
	CyU3PReturnStatus_t apiRetStatus = CY_U3P_SUCCESS;
	CyU3PUSBSpeed_t usbSpeed = CyU3PUsbGetSpeed();

	/* First identify the usb speed. Once that is identified,
	 * create a DMA channel and start the transfer on this. */

	/* Based on the Bus Speed configure the endpoint packet size */
	switch (usbSpeed)
	{
    	case CY_U3P_FULL_SPEED:
    		size = 64;
    		burst_length = 1;
    		break;

    	case CY_U3P_HIGH_SPEED:
    		size = 512;
    		burst_length = 1;
    		break;

    	case CY_U3P_SUPER_SPEED:
    		size = 1024;
    		burst_length = 16;
    		break;

    	default:
    		CyFxAppErrorHandler(CY_U3P_ERROR_FAILURE);
    		break;
	}

	CyU3PMemSet((uint8_t *) &epCfg, 0, sizeof(epCfg));
	epCfg.enable = CyTrue;
	epCfg.epType = CY_U3P_USB_EP_BULK;

	// Choose between 2 types
#ifdef STREAM_IN_OUT
	epCfg.burstLen = burst_length;
#else
	epCfg.burstLen = 1;
#endif

	epCfg.streams = 0;
	epCfg.pcktSize = size;

	/* Producer endpoint configuration */
	apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_PRODUCER, &epCfg);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* Consumer endpoint configuration */
	apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_CONSUMER, &epCfg);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

#ifdef MANUAL_DMA
//----------------------------------------------------------------------------------
// Create a DMA MANUAL channel for U2P transfer. 
//----------------------------------------------------------------------------------
    dmaCfg.size = DMA_BUF_SIZE * size;
    dmaCfg.count = CY_FX_SLFIFO_DMA_BUF_COUNT_U_2_P;
    dmaCfg.prodSckId = CY_FX_PRODUCER_USB_SOCKET;
    dmaCfg.consSckId = CY_FX_CONSUMER_PPORT_SOCKET;
    dmaCfg.prodAvailCount = 0;
    dmaCfg.prodHeader = 0;
    dmaCfg.prodFooter = 0;
    dmaCfg.consHeader = 0;
    dmaCfg.dmaMode = CY_U3P_DMA_MODE_BYTE;
    dmaCfg.notification = CY_U3P_DMA_CB_PROD_EVENT;
    dmaCfg.cb = CyFxSlFifoUtoPDmaCallback;
    apiRetStatus = CyU3PDmaChannelCreate(&glChHandleSlFifoUtoP, CY_U3P_DMA_TYPE_AUTO, &dmaCfg);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);
//----------------------------------------------------------------------------------
// Create a DMA MANUAL channel for P2U transfer. 
//----------------------------------------------------------------------------------
	dmaCfg.size = DMA_BUF_SIZE * size;
    dmaCfg.count = CY_FX_SLFIFO_DMA_BUF_COUNT_P_2_U;
    dmaCfg.prodSckId = CY_FX_PRODUCER_PPORT_SOCKET;
    dmaCfg.consSckId = CY_FX_CONSUMER_USB_SOCKET;
    dmaCfg.prodAvailCount = 0;
    dmaCfg.prodHeader = 0;
    dmaCfg.prodFooter = 0;
    dmaCfg.consHeader = 0;
    dmaCfg.dmaMode = CY_U3P_DMA_MODE_BYTE;
    dmaCfg.notification = CY_U3P_DMA_CB_PROD_EVENT;
    dmaCfg.cb = CyFxSlFifoPtoUDmaCallback;
    apiRetStatus = CyU3PDmaChannelCreate(&glChHandleSlFifoUtoP, CY_U3P_DMA_TYPE_AUTO, &dmaCfg);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);
#else
//----------------------------------------------------------------------------------
// Create a DMA AUTO channel for U2P transfer. 
//----------------------------------------------------------------------------------
	dmaCfg.size = DMA_BUF_SIZE * size;
	dmaCfg.count = CY_FX_SLFIFO_DMA_BUF_COUNT_U_2_P;
	dmaCfg.prodSckId = CY_FX_PRODUCER_USB_SOCKET;
	dmaCfg.consSckId = CY_FX_CONSUMER_PPORT_SOCKET;
	dmaCfg.prodAvailCount = 0;
	dmaCfg.prodHeader = 0;
	dmaCfg.prodFooter = 0;
	dmaCfg.consHeader = 0;
	dmaCfg.dmaMode = CY_U3P_DMA_MODE_BYTE;
	dmaCfg.notification = 0;
	dmaCfg.cb = NULL;
	apiRetStatus = CyU3PDmaChannelCreate(&glChHandleSlFifoUtoP, CY_U3P_DMA_TYPE_AUTO, &dmaCfg);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);
//----------------------------------------------------------------------------------
// Create a DMA AUTO channel for P2U transfer. 
//----------------------------------------------------------------------------------
	dmaCfg.size = DMA_BUF_SIZE * size;
	dmaCfg.count = CY_FX_SLFIFO_DMA_BUF_COUNT_P_2_U;
	dmaCfg.prodSckId = CY_FX_PRODUCER_PPORT_SOCKET;
	dmaCfg.consSckId = CY_FX_CONSUMER_USB_SOCKET;
	dmaCfg.prodAvailCount = 0;
	dmaCfg.prodHeader = 0;
	dmaCfg.prodFooter = 0;
	dmaCfg.consHeader = 0;
	dmaCfg.dmaMode = CY_U3P_DMA_MODE_BYTE;
	dmaCfg.notification = 0;
	dmaCfg.cb = NULL;
	apiRetStatus = CyU3PDmaChannelCreate(&glChHandleSlFifoPtoU, CY_U3P_DMA_TYPE_AUTO, &dmaCfg);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);
#endif

	/* Flush the Endpoint memory */
	CyU3PUsbFlushEp(CY_FX_EP_PRODUCER);
	CyU3PUsbFlushEp(CY_FX_EP_CONSUMER);

	/* Set DMA channel transfer size. */
	apiRetStatus = CyU3PDmaChannelSetXfer(&glChHandleSlFifoUtoP, CY_FX_SLFIFO_DMA_TX_SIZE);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	apiRetStatus = CyU3PDmaChannelSetXfer(&glChHandleSlFifoPtoU, CY_FX_SLFIFO_DMA_RX_SIZE);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* Update the status flag. */
	glIsApplnActive = CyTrue;
}
//----------------------------------------------------------------------------------
// This function stops the slave FIFO loop application (RESET or DISCONNECT).
//----------------------------------------------------------------------------------
void CyFxSlFifoApplnStop(void)
{
	CyU3PEpConfig_t epCfg;
	CyU3PReturnStatus_t apiRetStatus = CY_U3P_SUCCESS;

	/* Update the flag. */
	glIsApplnActive = CyFalse;

	/* Flush the endpoint memory */
	CyU3PUsbFlushEp(CY_FX_EP_PRODUCER);
	CyU3PUsbFlushEp(CY_FX_EP_CONSUMER);

	/* Destroy the channel */
	CyU3PDmaChannelDestroy(&glChHandleSlFifoUtoP);
	CyU3PDmaChannelDestroy(&glChHandleSlFifoPtoU);

	/* Disable endpoints. */
	CyU3PMemSet((uint8_t *) &epCfg, 0, sizeof(epCfg));
	epCfg.enable = CyFalse;

	/* Producer endpoint configuration. */
	apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_PRODUCER, &epCfg);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* Consumer endpoint configuration. */
	apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_CONSUMER, &epCfg);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);
}

//----------------------------------------------------------------------------------
// Callback to handle the USB setup requests.
//----------------------------------------------------------------------------------
CyBool_t CyFxSlFifoApplnUSBSetupCB(uint32_t setupdat0, uint32_t setupdat1)
{
	/* Fast enumeration is used. Only requests addressed to the interface, class,
	 * vendor and unknown control requests are received by this function.
	 * This application does not support any class or vendor requests. */

	uint8_t bRequest, bReqType;
	uint8_t bType, bTarget;
	uint16_t wValue, wIndex;
	CyBool_t isHandled = CyFalse;

	/* Decode the fields from the setup request. */
	bReqType = (setupdat0 & CY_U3P_USB_REQUEST_TYPE_MASK);
	bType = (bReqType & CY_U3P_USB_TYPE_MASK);
	bTarget = (bReqType & CY_U3P_USB_TARGET_MASK);
	bRequest =
			((setupdat0 & CY_U3P_USB_REQUEST_MASK) >> CY_U3P_USB_REQUEST_POS);
	wValue = ((setupdat0 & CY_U3P_USB_VALUE_MASK) >> CY_U3P_USB_VALUE_POS);
	wIndex = ((setupdat1 & CY_U3P_USB_INDEX_MASK) >> CY_U3P_USB_INDEX_POS);

	if (bType == CY_U3P_USB_STANDARD_RQT)
	{
		/* Handle SET_FEATURE(FUNCTION_SUSPEND) and CLEAR_FEATURE(FUNCTION_SUSPEND)
		 * requests here. It should be allowed to pass if the device is in configured
		 * state and failed otherwise. */
		if ((bTarget == CY_U3P_USB_TARGET_INTF)
				&& ((bRequest == CY_U3P_USB_SC_SET_FEATURE)
						|| (bRequest == CY_U3P_USB_SC_CLEAR_FEATURE))
				&& (wValue == 0))
		{
			if (glIsApplnActive)
				CyU3PUsbAckSetup();
			else
				CyU3PUsbStall(0, CyTrue, CyFalse);

			isHandled = CyTrue;
		}

		/* CLEAR_FEATURE request for endpoint is always passed to the setup callback
		 * regardless of the enumeration model used. When a clear feature is received,
		 * the previous transfer has to be flushed and cleaned up. This is done at the
		 * protocol level. Since this is just a loopback operation, there is no higher
		 * level protocol. So flush the EP memory and reset the DMA channel associated
		 * with it. If there are more than one EP associated with the channel reset both
		 * the EPs. The endpoint stall and toggle / sequence number is also expected to be
		 * reset. Return CyFalse to make the library clear the stall and reset the endpoint
		 * toggle. Or invoke the CyU3PUsbStall (ep, CyFalse, CyTrue) and return CyTrue.
		 * Here we are clearing the stall. */
		if ((bTarget == CY_U3P_USB_TARGET_ENDPT)
				&& (bRequest == CY_U3P_USB_SC_CLEAR_FEATURE)
				&& (wValue == CY_U3P_USBX_FS_EP_HALT))
		{
			if (glIsApplnActive)
			{
				if (wIndex == CY_FX_EP_PRODUCER)
				{
					CyU3PDmaChannelReset(&glChHandleSlFifoUtoP);
					CyU3PUsbFlushEp(CY_FX_EP_PRODUCER);
					CyU3PUsbResetEp(CY_FX_EP_PRODUCER);
					CyU3PDmaChannelSetXfer(&glChHandleSlFifoUtoP, CY_FX_SLFIFO_DMA_TX_SIZE);
				}

				if (wIndex == CY_FX_EP_CONSUMER)
				{
					CyU3PDmaChannelReset(&glChHandleSlFifoPtoU);
					CyU3PUsbFlushEp(CY_FX_EP_CONSUMER);
					CyU3PUsbResetEp(CY_FX_EP_CONSUMER);
					CyU3PDmaChannelSetXfer(&glChHandleSlFifoPtoU, CY_FX_SLFIFO_DMA_RX_SIZE);
				}

				CyU3PUsbStall(wIndex, CyFalse, CyTrue);

				//CyU3PUsbAckSetup();
				isHandled = CyTrue;
			}
		}
	}

	return isHandled;
}
//----------------------------------------------------------------------------------
// This is the callback function to handle the USB events.
//----------------------------------------------------------------------------------
void CyFxSlFifoApplnUSBEventCB(CyU3PUsbEventType_t evtype, uint16_t evdata)
{
	switch (evtype)
	{
	case CY_U3P_USB_EVENT_SETCONF:
		/* Stop the application before re-starting. */
		if (glIsApplnActive)
		{
			CyFxSlFifoApplnStop();
		}
        CyU3PUsbLPMDisable();
		/* Start the loop back function. */
		CyFxSlFifoApplnStart();
		break;

	case CY_U3P_USB_EVENT_RESET:
	case CY_U3P_USB_EVENT_DISCONNECT:
		/* Stop the loop back function. */
		if (glIsApplnActive)
		{
			CyFxSlFifoApplnStop();
		}
		break;

	default:
		break;
	}
}
//----------------------------------------------------------------------------------
//  Callback function to handle LPM requests from the USB 3.0 host.
// This application does not have any state in which we should not allow U1/U2 transitions
// and therefore the function always return CyTrue.
//----------------------------------------------------------------------------------
CyBool_t CyFxApplnLPMRqtCB(CyU3PUsbLinkPowerMode link_mode)
{
	return CyTrue;
}
//----------------------------------------------------------------------------------
// This function initializes the GPIF interface and initializes the USB interface.
//----------------------------------------------------------------------------------
void CyFxSlFifoApplnInit(void)
{
	CyU3PPibClock_t pibClock;
	CyU3PReturnStatus_t apiRetStatus = CY_U3P_SUCCESS;

	/* Initialize the p-port block. */
	pibClock.clkDiv = 2;
	pibClock.clkSrc = CY_U3P_SYS_CLK;
	pibClock.isHalfDiv = CyFalse;
	/* Disable DLL for sync GPIF */
	pibClock.isDllEnable = CyFalse;
	apiRetStatus = CyU3PPibInit(CyTrue, &pibClock);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* Load the GPIF configuration for Slave FIFO sync mode. */
	apiRetStatus = CyU3PGpifLoad(&CyFxGpifConfig);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	CyU3PGpifSocketConfigure(0, CY_U3P_PIB_SOCKET_0, 3, CyFalse, 1);
	CyU3PGpifSocketConfigure(3, CY_U3P_PIB_SOCKET_3, 3, CyFalse, 1);

	/* Start the state machine. */
	apiRetStatus = CyU3PGpifSMStart(RESET, ALPHA_RESET);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* Start the USB functionality. */
	apiRetStatus = CyU3PUsbStart();
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* The fast enumeration is the easiest way to setup a USB connection,
	 * where all enumeration phase is handled by the library. Only the
	 * class / vendor requests need to be handled by the application. */
	CyU3PUsbRegisterSetupCallback(CyFxSlFifoApplnUSBSetupCB, CyTrue);

	/* Setup the callback to handle the USB events. */
	CyU3PUsbRegisterEventCallback(CyFxSlFifoApplnUSBEventCB);

	/* Register a callback to handle LPM requests from the USB 3.0 host. */
	CyU3PUsbRegisterLPMRequestCallback(CyFxApplnLPMRqtCB);

	/* Set the USB Enumeration descriptors */

	/* Super speed device descriptor. */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_SS_DEVICE_DESCR, NULL,
			(uint8_t *) CyFxUSB30DeviceDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* High speed device descriptor. */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_HS_DEVICE_DESCR, NULL,
			(uint8_t *) CyFxUSB20DeviceDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* BOS descriptor */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_SS_BOS_DESCR, NULL,
			(uint8_t *) CyFxUSBBOSDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* Device qualifier descriptor */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_DEVQUAL_DESCR, NULL,
			(uint8_t *) CyFxUSBDeviceQualDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* Super speed configuration descriptor */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_SS_CONFIG_DESCR, NULL,
			(uint8_t *) CyFxUSBSSConfigDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* High speed configuration descriptor */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_HS_CONFIG_DESCR, NULL,
			(uint8_t *) CyFxUSBHSConfigDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* Full speed configuration descriptor */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_FS_CONFIG_DESCR, NULL,
			(uint8_t *) CyFxUSBFSConfigDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* String descriptor 0 */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 0,
			(uint8_t *) CyFxUSBStringLangIDDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* String descriptor 1 */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 1,
			(uint8_t *) CyFxUSBManufactureDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* String descriptor 2 */
	apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 2,
			(uint8_t *) CyFxUSBProductDscr);
    if (apiRetStatus != CY_U3P_SUCCESS)
        CyFxAppErrorHandler(apiRetStatus);

	/* Connect the USB Pins with super speed operation enabled. */
	apiRetStatus = CyU3PConnectState(CyTrue, CyTrue);
	if (apiRetStatus != CY_U3P_SUCCESS)
		CyFxAppErrorHandler(apiRetStatus);
}
//----------------------------------------------------------------------------------
// Entry function for the slFifoAppThread.
//----------------------------------------------------------------------------------
void SlFifoAppThread_Entry(uint32_t input)
{
	/* Initialize the slave FIFO application */
	CyFxSlFifoApplnInit();

	for (;;)
	{
		CyU3PThreadSleep(1000);
		if (glIsApplnActive)
		{
			;
		}
	}
}
//----------------------------------------------------------------------------------
// Application define function which creates the threads.
//----------------------------------------------------------------------------------
void CyFxApplicationDefine(void)
{
	void *ptr = NULL;
	uint32_t retThrdCreate = CY_U3P_SUCCESS;

	/* Allocate the memory for the thread */
	ptr = CyU3PMemAlloc(CY_FX_SLFIFO_THREAD_STACK);

	/* Create the thread for the application */
	retThrdCreate = CyU3PThreadCreate (&slFifoAppThread, /* Slave FIFO app thread structure */
			"21:Slave_FIFO_sync", /* Thread ID and thread name */
			SlFifoAppThread_Entry, /* Slave FIFO app thread entry function */
			0, /* No input parameter to thread */
			ptr, /* Pointer to the allocated thread stack */
			CY_FX_SLFIFO_THREAD_STACK, /* App Thread stack size */
			CY_FX_SLFIFO_THREAD_PRIORITY, /* App Thread priority */
			CY_FX_SLFIFO_THREAD_PRIORITY, /* App Thread pre-emption threshold */
			CYU3P_NO_TIME_SLICE, /* No time slice for the application thread */
			CYU3P_AUTO_START /* Start the thread immediately */
	);

	/* Check the return code */
	if (retThrdCreate != 0)
	{
		/* Thread Creation failed with the error code retThrdCreate */

		/* Add custom recovery or debug actions here */

		/* Application cannot continue */
		/* Loop indefinitely */
		while (1)
			;
	}
}
//----------------------------------------------------------------------------------
// Main Function
//----------------------------------------------------------------------------------
int main(void)
{
	CyU3PIoMatrixConfig_t io_cfg;
	CyU3PReturnStatus_t status = CY_U3P_SUCCESS;
	CyU3PSysClockConfig_t clockConfig;

    clockConfig.setSysClk400 = CyTrue;
	clockConfig.cpuClkDiv = 2;
	clockConfig.dmaClkDiv = 2;
	clockConfig.mmioClkDiv = 2;
	clockConfig.useStandbyClk = CyFalse;
	clockConfig.clkSrc = CY_U3P_SYS_CLK;
	status = CyU3PDeviceInit(&clockConfig);
	if (status != CY_U3P_SUCCESS)
	{
		goto handle_fatal_error;
	}

	/* Initialize the caches. Enable both Instruction and Data Caches. */
	status = CyU3PDeviceCacheControl(CyTrue, CyTrue, CyTrue);
	if (status != CY_U3P_SUCCESS)
	{
		goto handle_fatal_error;
	}

	/* Configure the IO matrix for the device. On the FX3 DVK board, the COM port
	 * is connected to the IO(53:56). This means that either DQ32 mode should be
	 * selected or lppMode should be set to UART_ONLY. Here we are choosing
	 * UART_ONLY configuration for 16 bit slave FIFO configuration and setting
	 * isDQ32Bit for 32-bit slave FIFO configuration. */

    io_cfg.useUart   = CyTrue;
    io_cfg.useI2C    = CyFalse;
    io_cfg.useI2S    = CyFalse;
    io_cfg.useSpi    = CyFalse;
#if (CY_FX_SLFIFO_GPIF_16_32BIT_CONF_SELECT == 0)
    io_cfg.isDQ32Bit = CyFalse;
    io_cfg.lppMode   = CY_U3P_IO_MATRIX_LPP_UART_ONLY;
#else
    io_cfg.isDQ32Bit = CyTrue;
    io_cfg.lppMode   = CY_U3P_IO_MATRIX_LPP_DEFAULT;
#endif
    /* No GPIOs are enabled. */
    io_cfg.gpioSimpleEn[0]  = 0;
    io_cfg.gpioSimpleEn[1]  = 0x08000000; /* GPIO 59 */
    io_cfg.gpioComplexEn[0] = 0;
    io_cfg.gpioComplexEn[1] = 0;
    status = CyU3PDeviceConfigureIOMatrix (&io_cfg);
    if (status != CY_U3P_SUCCESS)
    {
        goto handle_fatal_error;
    }

	/* This is a non returnable call for initializing the RTOS kernel */CyU3PKernelEntry();

	/* Dummy return to make the compiler happy */
	return 0;

	handle_fatal_error:

	/* Cannot recover from this error. */
	while (1);
}
