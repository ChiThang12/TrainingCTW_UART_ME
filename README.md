# UART Implementation

## 📌 Giới thiệu

UART (Universal Asynchronous Receiver–Transmitter) là giao thức truyền thông nối tiếp **không đồng bộ**, thường dùng để truyền dữ liệu giữa các thiết bị điện tử.
Thiết kế này bao gồm đầy đủ **bộ truyền (TX)** và **bộ nhận (RX)**, kết hợp **FIFO buffer** giúp truyền nhận dữ liệu liên tục, ổn định.

---

## 🚀 Tính năng chính

### UART Transmitter (TX)
<img width="846" height="583" alt="image" src="https://github.com/user-attachments/assets/4b93ff82-4b31-46c5-a18e-81f025526165" />

* Quản lý dữ liệu tự động thông qua FIFO.
* Hỗ trợ truyền liên tục nhiều byte.
* Đóng gói dữ liệu theo chuẩn UART frame.
* Cảnh báo trạng thái FIFO đầy/rỗng, TX bận/rảnh.

### UART Receiver (RX)
<img width="969" height="694" alt="image" src="https://github.com/user-attachments/assets/62c3ab18-acdb-40b0-8ba8-f2b48657560b" />

* Tự động phát hiện và lấy mẫu dữ liệu từ đường truyền.
* Đồng bộ hóa tín hiệu để tránh **metastability**.
* Lấy mẫu chính xác ở giữa bit (**16× oversampling**).
* Phát hiện lỗi stop bit.
* Cảnh báo tràn FIFO khi nhận quá nhanh.

---

## 🏗️ Kiến trúc hệ thống

Hệ thống gồm 4 thành phần chính:

1. **Bộ sinh Baud Rate**
<img width="448" height="393" alt="image" src="https://github.com/user-attachments/assets/03d289d7-973d-4d5e-ac2d-a9809f96878a" />

   * Tạo tick chính xác cho cả TX/RX.
   * Hỗ trợ oversampling ×16 để tối ưu độ chính xác.
   * Tự động tính toán từ clock hệ thống (ví dụ: Clock 100 MHz → Baud 115200 → tick mỗi 54 cycles).

2. **TX Core**
<img width="353" height="436" alt="image" src="https://github.com/user-attachments/assets/32adcba9-ea62-4486-b31f-a5d6dfe6c216" />


   * Tạo frame UART: Start bit → Data bits → Stop bit.
   * Truyền dữ liệu theo **LSB first**.
   * State machine điều khiển thời điểm truyền từng bit chính xác.

4. **RX Core**
<img width="352" height="445" alt="image" src="https://github.com/user-attachments/assets/6483a7d4-8b32-442f-9c0c-6b790edf9678" />

   * Phát hiện cạnh xuống của start bit.
   * Xác nhận start bit ở giữa bit để tránh nhiễu.
   * Lấy mẫu **8 data bits** tại vị trí 15/16 chu kỳ.
   * Kiểm tra stop bit trước khi ghi vào FIFO.
   * Tích hợp bộ đồng bộ 2 tầng.

5. **FIFO Buffer**
<img width="430" height="439" alt="image" src="https://github.com/user-attachments/assets/1eb490c1-7fac-4709-be47-977589897464" />

   * Lưu trữ tạm dữ liệu để truyền/nhận liên tục.
   * Độ sâu mặc định: 16 bytes (có thể cấu hình).
   * Ngăn mất dữ liệu khi tốc độ xử lý không đều.

---

## 🔄 Luồng hoạt động

### TX Flow

1. Người dùng ghi byte vào FIFO-TX.
2. TX core tự động lấy dữ liệu khi rảnh.
3. Truyền từng bit theo UART frame.
4. Lặp lại cho đến khi FIFO trống.

### RX Flow

1. RX giám sát đường truyền liên tục.
2. Phát hiện và xác thực start bit.
3. Lấy mẫu 8 data bits theo baud tick.
4. Kiểm tra stop bit.
5. Ghi dữ liệu vào FIFO-RX để người dùng đọc.

---

## ⚙️ Finite State Machine
### TX Flow
<img width="977" height="258" alt="image" src="https://github.com/user-attachments/assets/a558bdd3-b341-4501-9dc9-4a12ddb5a757" />

### RX Flow
<img width="1151" height="312" alt="image" src="https://github.com/user-attachments/assets/27183106-3e00-4ad0-bb69-bfa7c9883152" />

---

## 📡 UART Frame Format

Mỗi byte gồm:

* **Start bit:** 1 (mức 0)
* **Data bits:** 8 (LSB → MSB)
* **Stop bit:** 1 (mức 1)

➡️ Tổng cộng **10 bits/byte**
Với baud rate 9600 → thời gian truyền 1 byte ≈ **65 µs**.

---

## 🎯 Ứng dụng

* Giao tiếp PC ↔ FPGA / MCU
* Truyền dữ liệu cho module GPS, Bluetooth, WiFi
* Debug UART trên FPGA
* Giao tiếp sensor/actuator
* Trao đổi dữ liệu giữa các board điện tử


