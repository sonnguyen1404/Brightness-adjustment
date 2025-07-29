/******************************************************************************
*
*
*
* HIGH-RESOLUTION SUPPORT VERSION
*
******************************************************************************/

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xuartps.h"
#include "xuartps_hw.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xstatus.h"
#include "sleep.h"

/*
 * =============================================================================
 * PHẦN CẤU HÌNH - ĐÃ NÂNG CẤP
 * =============================================================================
 */

#define UART_DEVICE_ID         XPAR_XUARTPS_0_DEVICE_ID
#define UART_BAUD_RATE         115200
#define BRIGHTNESS_IP_BASEADDR XPAR_BRIGHTNESS_CONTROL_0_S00_AXI_BASEADDR

#define PIXEL_IN_OFFSET        0
#define FACTOR_OFFSET          4
#define PIXEL_OUT_OFFSET       8

// *** THAY ĐỔI QUAN TRỌNG: TĂNG KÍCH THƯỚC BUFFER ***
// Đặt giới hạn kích thước ảnh tối đa mà hệ thống có thể xử lý
#define MAX_IMG_WIDTH          320  // Ví dụ: hỗ trợ ảnh rộng tới 320px
#define MAX_IMG_HEIGHT         240  // Ví dụ: hỗ trợ ảnh cao tới 240px
// Buffer sẽ được cấp phát dựa trên kích thước tối đa này
#define MAX_BUFFER_SIZE        (MAX_IMG_WIDTH * MAX_IMG_HEIGHT * 3) // = 230,400 bytes

/*
 * =============================================================================
 * KHAI BÁO BIẾN TOÀN CỤC
 * =============================================================================
 */

static XUartPs UartInstance;
// Cấp phát một bộ đệm lớn hơn trong bộ nhớ
u8 image_in_buffer[MAX_BUFFER_SIZE];
u8 image_out_buffer[MAX_BUFFER_SIZE];

/*
 * =============================================================================
 * CÁC HÀM TIỆN ÍCH (Giữ nguyên)
 * =============================================================================
 */

int InitializeUart(XUartPs *UartInstPtr, u16 DeviceId) {
    XUartPs_Config *Config;
    int Status;
    Config = XUartPs_LookupConfig(DeviceId);
    if (NULL == Config) { return XST_FAILURE; }
    Status = XUartPs_CfgInitialize(UartInstPtr, Config, Config->BaseAddress);
    if (Status != XST_SUCCESS) { return XST_FAILURE; }
    XUartPs_SetBaudRate(UartInstPtr, UART_BAUD_RATE);
    return XST_SUCCESS;
}

void RecvData(u8* data, u32 length) {
    u32 ReceivedCount = 0;
    while (ReceivedCount < length) {
        ReceivedCount += XUartPs_Recv(&UartInstance, &data[ReceivedCount], length - ReceivedCount);
    }
}

void SendData(u8* data, u32 length) {
    u32 BaseAddress = UartInstance.Config.BaseAddress;
    for (u32 SentCount = 0; SentCount < length; SentCount++) {
        while (XUartPs_IsTransmitFull(BaseAddress));
        XUartPs_WriteReg(BaseAddress, XUARTPS_FIFO_OFFSET, data[SentCount]);
    }
    while (!(XUartPs_ReadReg(BaseAddress, XUARTPS_SR_OFFSET) & XUARTPS_SR_TXEMPTY));
}

u8 RecvByte() {
    u8 byte;
    RecvData(&byte, 1);
    return byte;
}

/*
 * =============================================================================
 * HÀM CHÍNH (MAIN FUNCTION) (Logic giữ nguyên)
 * =============================================================================
 */
int main()
{
    int Status;
    init_platform();

    Status = InitializeUart(&UartInstance, UART_DEVICE_ID);
    if (Status != XST_SUCCESS) { return XST_FAILURE; }

    xil_printf("--- High-Resolution Image Processor Ready ---\n\r");
    xil_printf("Waiting for commands from PC...\n\r");


    while (1) {
        if (RecvByte() == 'S' && RecvByte() == 'N' && RecvByte() == 'D') {

            u8 factor_buffer[2];
            RecvData(factor_buffer, 2);
            u16 brightness_factor = (factor_buffer[0] << 8) | factor_buffer[1];
            Xil_Out32(BRIGHTNESS_IP_BASEADDR + FACTOR_OFFSET, brightness_factor);

            u8 size_buffer[4];
            RecvData(size_buffer, 4);
            u16 width = (size_buffer[0] << 8) | size_buffer[1];
            u16 height = (size_buffer[2] << 8) | size_buffer[3];
            u32 total_bytes = width * height * 3;

            // KIỂM TRA LẠI VỚI BUFFER LỚN
            if (total_bytes > MAX_BUFFER_SIZE) {
                // Gửi tín hiệu lỗi về PC nếu ảnh quá lớn so với buffer đã cấp phát
                SendData((u8*)"ERR", 3);
                continue;
            }

            RecvData(image_in_buffer, total_bytes);

            // Xử lý ảnh bằng phần cứng
            for (u32 i = 0; i < total_bytes; i++) {
                Xil_Out32(BRIGHTNESS_IP_BASEADDR + PIXEL_IN_OFFSET, (u32)image_in_buffer[i]);
                usleep(1); // Giảm sleep vì AXI nhanh hơn nhiều so với xử lý ảnh lớn
                u32 result_from_hw = Xil_In32(BRIGHTNESS_IP_BASEADDR + PIXEL_OUT_OFFSET);
                u32 scaled_result = result_from_hw >> 8;
                image_out_buffer[i] = (scaled_result > 255) ? 255 : (u8)scaled_result;
            }

            SendData((u8*)"ACK", 3);
            SendData(image_out_buffer, total_bytes);
        }
    }

    cleanup_platform();
    return 0;
}
