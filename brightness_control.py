import serial
import time
from PIL import Image
import numpy as np
import sys
# import struct

# =============================================================================
# PHẦN CẤU HÌNH
# =============================================================================
SERIAL_PORT = 'COM4' 
BAUD_RATE = 115200
DEFAULT_IMAGE_PATH = 'input.jpg' 
OUTPUT_IMAGE_PATH_TEMPLATE = 'output-{factor:.1f}x.jpg'

# =============================================================================
# HÀM XỬ LÝ ẢNH
# =============================================================================
def process_image_with_factor(ser, image_path, factor):
    """
    Gửi ảnh và hệ số sáng tới Zynq, sau đó nhận lại kết quả.
    """
    # --- 1. Chuẩn bị dữ liệu ---
    try:
        print(f"\n--- Bắt đầu xử lý ảnh GỐC '{image_path}' với hệ số sáng {factor:.2f}x ---")
        with Image.open(image_path) as img:
            # *** THAY ĐỔI QUAN TRỌNG: KHÔNG RESIZE ẢNH NỮA ***
            # Chỉ chuyển sang định dạng RGB
            img_rgb = img.convert('RGB')
            img_data = np.array(img_rgb, dtype=np.uint8).flatten().tobytes()
            width, height = img_rgb.size
            total_bytes = len(img_data)
            print(f"Ảnh GỐC có kích thước: {width}x{height}, {total_bytes} bytes.")
            
            # Kiểm tra xem ảnh có quá lớn không
            # Kích thước này phải khớp với MAX_BUFFER_SIZE trong code C
            if total_bytes > (320 * 240 * 3):
                print(f"Lỗi: Ảnh quá lớn ({width}x{height}) để xử lý. Vui lòng chọn ảnh nhỏ hơn.")
                return

    except FileNotFoundError:
        print(f"Lỗi: Không tìm thấy file ảnh '{image_path}'.")
        return

    # Chuyển đổi hệ số sáng (float) sang số nguyên 16-bit
    factor_int = int(factor * 256)
    if not (0 <= factor_int <= 65535):
        print("Lỗi: Hệ số sáng nằm ngoài phạm vi.")
        return
    factor_bytes = factor_int.to_bytes(2, 'big')

    # --- 2. Gửi dữ liệu theo giao thức ---
    try:
        start_time = time.time()
        print("Bắt đầu gửi dữ liệu. Việc này có thể mất một lúc...")

        ser.write(b'SND')
        ser.write(factor_bytes)
        ser.write(width.to_bytes(2, 'big'))
        ser.write(height.to_bytes(2, 'big'))

        print(f"Đang gửi {total_bytes} bytes dữ liệu ảnh...")
        ser.write(img_data)
        
        print("Đã gửi xong. Đang chờ ACK...")
        ack = ser.read(3)
        if ack == b'ERR':
            print("Lỗi từ Zynq: Ảnh quá lớn so với bộ đệm trên bo mạch!")
            return
        if ack != b'ACK':
            print(f"Lỗi: Không nhận được ACK hợp lệ. Nhận được: {ack}")
            return
        
        print(f"Đã nhận ACK. Đang nhận {total_bytes} bytes kết quả...")
        processed_data = ser.read(total_bytes)
        
        end_time = time.time()
        print(f"Thời gian truyền và xử lý: {end_time - start_time:.2f} giây.")

        if len(processed_data) != total_bytes:
            print(f"Lỗi: Nhận thiếu dữ liệu!")
            return
            
        # --- 4. Lưu kết quả ---
        output_path = OUTPUT_IMAGE_PATH_TEMPLATE.format(factor=factor)
        processed_array = np.frombuffer(processed_data, dtype=np.uint8).reshape((height, width, 3))
        processed_img = Image.fromarray(processed_array, 'RGB')
        processed_img.save(output_path)
        print(f"=> THÀNH CÔNG! Đã lưu ảnh kết quả vào '{output_path}'")
        processed_img.show()

    except serial.SerialTimeoutException:
        print("Lỗi: Zynq không phản hồi (timeout). Có thể ảnh quá lớn hoặc quá trình xử lý quá lâu.")
    except Exception as e:
        print(f"Một lỗi không xác định đã xảy ra: {e}")

# =============================================================================
# CHƯƠNG TRÌNH CHÍNH
# =============================================================================
def main():
    try:
        # Tăng timeout lên 120 giây để đủ thời gian cho ảnh lớn
        with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=120) as ser:
            print(f"Đã mở cổng {SERIAL_PORT} ở tốc độ {BAUD_RATE}")
            time.sleep(2)
            ser.flushInput()

            while True:
                factor_str = input(f"\nNhập hệ số sáng hoặc 'q' để thoát: ")
                if factor_str.lower() == 'q':
                    break
                try:
                    brightness_float = float(factor_str)
                    if brightness_float < 0:
                        print("Hệ số sáng không thể âm.")
                        continue
                    
                    image_path = input(f"Nhập đường dẫn ảnh (Enter để dùng '{DEFAULT_IMAGE_PATH}'): ")
                    if not image_path:
                        image_path = DEFAULT_IMAGE_PATH

                    process_image_with_factor(ser, image_path, brightness_float)
                except ValueError:
                    print("Đầu vào không hợp lệ.")

    except serial.SerialException:
        print(f"LỖI NGHIÊM TRỌNG: Không thể mở cổng {SERIAL_PORT}.")
        sys.exit(1)
    
    print("\nĐã đóng chương trình.")

if __name__ == "__main__":
    main()
