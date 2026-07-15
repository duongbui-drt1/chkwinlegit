# chkwinlegit

**chkwinlegit** là một công cụ mã nguồn mở (Open Source) chạy dưới dạng kịch bản hỗn hợp (hybrid) Batch/PowerShell giúp kiểm tra sâu hệ thống Windows và Microsoft Office để xác định xem thiết bị đang sử dụng bản quyền chính hãng (genuine) hay các phương thức kích hoạt lậu (pirated/tampered).

Công cụ này yêu cầu quyền quản trị viên (Administrator) để truy cập sâu vào Registry hệ thống, trạng thái dịch vụ, cấu hình mạng và tệp tin bảo mật của thiết bị.

> [!IMPORTANT]
> **Cấu trúc Độc lập & Ràng buộc (Dual-File Architecture)**:
> Kể từ phiên bản `A.00`, công cụ được chia làm 2 tệp kịch bản song hành:
> 1. `chkwinlegit.bat` (Giai đoạn 1: Quét nhanh & đánh giá chung).
> 2. `chkwinlegit_deep.bat` (Giai đoạn 2: Quét sâu cổng mạng & tệp tin ẩn).
> **Cả 2 tệp bắt buộc phải nằm cùng thư mục.** Nếu thiếu bất kỳ tệp nào, ứng dụng sẽ từ chối khởi chạy để đảm bảo tính toàn vẹn của dữ liệu chẩn đoán.

---

## Tính Năng Chính (Diagnostic Features)

### Giai Đoạn 1: Quét Nhanh & Đánh Giá Chung (`chkwinlegit.bat`)
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

### Giai Đoạn 2: Quét Sâu Bảo Mật & Mạng (`chkwinlegit_deep.bat`)
7. **Quét sâu tệp tin né check**:
   - Dò quét sâu trong các thư mục người dùng (Downloads, Desktop, AppData, Temp, Program Files) để tìm các tệp tin chứa ký tự ẩn/né tránh chẩn đoán: `@`, `thuoc`, `thuốc`, `unlock`, `crack`, `patch`, `keygen`, `bypass`, `activator`.
   - Hiển thị tiến trình trực quan dạng thanh tiến độ (Progress Bar) chạy ngay trên giao diện console.
8. **Quét sâu cổng kết nối (Port & Connections)**:
   - Phát hiện các tiến trình đang lắng nghe hoặc kết nối qua cổng KMS truyền thống `1688` (phát hiện KMSpico/KMSAuto cục bộ đang chạy ngầm).
   - Dò quét DNS Client Cache để phát hiện hành vi định tuyến tên miền bản quyền về địa chỉ IP loopback (`127.0.0.1`, `127.0.0.2`).
9. **Kiểm tra sâu cấu hình an toàn hệ thống**:
   - Kiểm tra trạng thái **UAC (User Account Control)** trong registry để xem có bị vô hiệu hóa hoặc tự động cấp quyền mà không hỏi người dùng không.
   - Kiểm tra dịch vụ cập nhật hệ thống **Windows Update (wuauserv)** xem có bị vô hiệu hóa trái phép.
   - Kiểm tra chế độ **Test Signing** (ký thử nghiệm driver) có đang mở hay không (nguy cơ bảo mật nghiêm trọng).

---

## Cơ Chế Phiên Bản (Versioning Scheme)

Phiên bản có định dạng: `[Loại bản vá].[Số bản sửa]` (Ví dụ: `A.00`)

*   **A** - Bản vá nặng, thay đổi lớn về mặt kiến trúc hoặc bổ sung mô-đun quan trọng (như chia tách tệp tin, thêm Giai đoạn quét sâu).
*   **B** - Bản vá vừa, nâng cấp tính năng chẩn đoán.
*   **C** - Bản vá ít, tinh chỉnh độ ổn định, sửa lỗi nhỏ.
*   **D** - Cập nhật bảo mật hoặc tối ưu hóa hiệu suất định kỳ.
*   `0` (Số bản sửa) - Số lượng bản vá sửa đổi nhỏ được tích lũy.

---

## Lịch Sử Phiên Bản (Version History)

*   **vA.00**:
    - **Tách kiến trúc hai tệp tin**: Bổ sung `chkwinlegit_deep.bat` để đảm nhận Giai đoạn 2 (Quét sâu) nhằm giảm tải cho kịch bản chính.
    - Cấu hình ràng buộc hai chiều: Không cho phép chạy nếu thiếu bất kỳ tệp tin nào.
    - Thêm quét tệp tin né check chứa ký tự đặc biệt (`@`, `thuoc`, `thuốc`, `unlock`).
    - Thêm tính năng đo lường tiến độ và hiển thị thanh tiến trình trực quan ngay trên Console.
    - Thêm quét sâu cổng mạng (Netstat 1688, DNS Cache) và kiểm tra suy giảm bảo mật hệ thống (UAC, Windows Update, Test Signing).
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
