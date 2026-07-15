# chkwinlegit

**chkwinlegit** là một công cụ mã nguồn mở (Open Source) chạy dưới dạng kịch bản hỗn hợp (hybrid) Batch/PowerShell giúp kiểm tra sâu hệ thống Windows và Microsoft Office để xác định xem thiết bị đang sử dụng bản quyền chính hãng (genuine) hay các phương thức kích hoạt lậu (pirated/tampered).

Công cụ này yêu cầu quyền quản trị viên (Administrator) để truy cập sâu vào Registry hệ thống, trạng thái dịch vụ, cấu hình mạng và tệp tin bảo mật của thiết bị.

---

## Tính Năng Chính (Diagnostic Features)

1. **Thông tin phần cứng & hệ thống**:
   - Hệ điều hành, phiên bản, kiến trúc.
   - Thời gian cài đặt hệ điều hành gốc.
   - Trích xuất định danh thiết bị độc bản (**Device UUID** và **Machine GUID**).
2. **Kiểm tra bản quyền Windows**:
   - Trạng thái bản quyền hiện tại qua WMI (`root\CIMV2`).
   - Kênh kích hoạt (Retail, OEM, Volume:GVLK, Volume:MAK).
3. **Kiểm tra bản quyền Microsoft Office**:
   - Dò quét vị trí `ospp.vbs` trong hệ thống.
   - Kiểm tra trạng thái cấp phép và một phần mã khóa sản phẩm.
4. **Phát hiện can thiệp bản quyền lậu**:
   - **Ohook**: Phát hiện tệp tin chuyển hướng `sppc.dll` trong các thư mục cài đặt Microsoft Office.
   - **KMS Host**: Phát hiện các máy chủ KMS lậu được ghi đè trong Registry cho cả Windows và Office.
   - **KMS38**: Nhận diện cơ chế kích hoạt KMS giả lập kéo dài tới năm 2038 (sử dụng loopback `127.0.0.2`).
   - **Tệp tin Crack phổ biến**: Quét các tệp đặc trưng của KMSpico, KMSAuto, KMS VL ALL, v.v.
   - **Services & Tasks**: Kiểm tra dịch vụ hệ thống và tác vụ tự động nghi vấn (như `AutoKMS`).
   - **Chặn máy chủ bản quyền**: Kiểm tra tệp tin `hosts` và các quy tắc chặn của Windows Firewall để phát hiện can thiệp ngăn ứng dụng Adobe / Autodesk CAD xác thực bản quyền trực tuyến.
   - **IFEO Hijacks**: Phát hiện can thiệp tiến trình quản lý bản quyền (`sppsvc.exe`, `osppsvc.exe`).
5. **Kiểm tra cấu hình bảo mật**:
   - Kiểm tra xem **BitLocker** có được kích hoạt để bảo vệ dữ liệu trên các ổ đĩa hay không.
   - Kiểm tra can thiệp bật/tắt trái phép **Windows Defender** (Bảo vệ thời gian thực và Dịch vụ hệ thống).
6. **Kiểm tra cài đặt "Vượt" yêu cầu (Windows 11 Bypasses)**:
   - Dò quét cấu hình bypass phần cứng cũ trong Registry (`LabConfig` bypasses).
   - Kiểm tra sự tương thích thực tế của thiết bị với Windows 11 (yêu cầu Secure Boot, TPM 2.0).

---

## Cơ Chế Phiên Bản (Versioning Scheme)

Phiên bản có định dạng: `[Loại bản vá].[Số bản sửa]` (Ví dụ: `C.02`)

*   **A** - Bản vá nặng, thay đổi lớn về mặt kiến trúc hoặc bổ sung mô-đun quan trọng.
*   **B** - Bản vá vừa, nâng cấp tính năng chẩn đoán.
*   **C** - Bản vá ít, tinh chỉnh độ ổn định, sửa lỗi nhỏ.
*   **D** - Cập nhật bảo mật hoặc tối ưu hóa hiệu suất định kỳ.
*   `0` (Số bản sửa) - Số lượng bản vá sửa đổi nhỏ được tích lũy.

---

## Lịch Sử Phiên Bản (Version History)

*   **vC.02**:
    - Nâng cấp phần **Đánh giá chung hệ thống (Final Assessment)** với bảng phân tích chi tiết trạng thái của từng thành phần (Windows, Office, Defender, BitLocker, Adobe/Autodesk, Tiêu chuẩn Win 11).
    - Cập nhật phần kết luận chi tiết để liệt kê cụ thể các lỗi bảo mật và bản quyền phát hiện được trên thiết bị.
    - Sửa lỗi xung đột tham số của lệnh `Get-NetFirewallRule` trên các phiên bản Windows/PowerShell cũ.
*   **vC.01**:
    - Thêm kiểm tra trạng thái **Windows Defender** và các can thiệp tắt bảo vệ.
    - Thêm kiểm tra cấu hình mã hóa **BitLocker**.
    - Thêm kiểm tra **Adobe và Autodesk CAD bẻ khóa** (quét `amtlib.dll`, quy tắc chặn tường lửa, chặn tên miền trong tệp `hosts`).
    - Thêm kiểm tra cài đặt "Vượt" (Bypasses) phần cứng trên Windows 11.
    - Bổ sung Device UUID và Machine GUID vào thông tin hệ thống.
*   **vC.00**:
    - Khởi tạo dự án kiểm tra bản quyền Windows & Office cơ bản bằng hybrid kịch bản Batch/PowerShell.

---

## Bản Quyền & Phát Triển (Credits & License)

- **Mã nguồn mở**: Dự án được phát triển dưới dạng mã nguồn mở công khai, cho phép cộng đồng kiểm tra tính minh bạch và an toàn của mã nguồn.
- **Phát triển bởi**: **Duli Software** & **Antigravity**.
