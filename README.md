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

1. **Thông tin phần cứng & hệ thống**
   - Hệ điều hành, phiên bản, kiến trúc.
   - Thời gian cài đặt hệ điều hành gốc.
   - Trích xuất định danh thiết bị độc bản (**Device UUID** và **Machine GUID**).

2. **Kiểm tra bản quyền Windows**
   - Trạng thái bản quyền hiện tại qua WMI (`root\CIMV2`).
   - Kênh kích hoạt (Retail, OEM, Volume:GVLK, Volume:MAK).

3. **Kiểm tra bản quyền Microsoft Office** *(nâng cấp A.02)*
   - Nhận diện loại cài đặt **Click-to-Run (C2R)** qua registry.
   - Phát hiện **Microsoft 365 / Office 365 Subscription** kích hoạt qua tài khoản (không phụ thuộc OSPP SPP).
   - Đọc email tài khoản Microsoft đã đăng nhập bằng 4 phương pháp fallback (Identity registry, Entra root key, license token files, Windows Credential Manager).
   - Phân loại màu sắc thông minh cho trạng thái OSPP: `LICENSED` (xanh), `OOB_GRACE` bản subscription (cyan + giải thích), `NOTIFICATIONS` (vàng/đỏ tùy ngữ cảnh).

4. **Phát hiện can thiệp bản quyền Windows & Office** *(mở rộng A.02)*
   - **Ohook**: Phát hiện tệp tin chuyển hướng `sppc.dll` trong các thư mục cài đặt Microsoft Office.
   - **KMS Host (Windows)**: Phát hiện các máy chủ KMS lậu được ghi đè trong Registry.
   - **KMS Host (Office)** `[4.13]`: Kiểm tra `OfficeSoftwareProtectionPlatform`, blacklist host nghi vấn (loopback, msguides, kmsauto...), phát hiện cổng KMS bị thay đổi khỏi 1688.
   - **KMS38**: Nhận diện cơ chế kích hoạt KMS giả lập kéo dài tới năm 2038.
   - **Retail → Volume GVLK** `[4.14]`: Phát hiện Office dùng kênh `VOLUME_KMSCLIENT` (Generic Volume License Key) trên máy cá nhân không thuộc domain doanh nghiệp.
   - **Chữ ký số DLL Office** `[4.15]`: Kiểm tra `Get-AuthenticodeSignature` các DLL bảo vệ bản quyền (`mso.dll`, `sppc.dll`, `mso30win32client.dll`...) — phát hiện DLL bị patch hoặc ký sai.
   - **License file inject** `[4.16]`: Quét `.xrm-ms` blob và `tokens.dat` trong `%ProgramData%\Microsoft\OfficeSoftwareProtectionPlatform\Cache` — phát hiện timestamp bất thường.
   - **Scheduled Task KMS Office** `[4.17]`: Phát hiện tác vụ tự động gia hạn KMS lậu với whitelist đầy đủ các task Microsoft hợp lệ (Office Automatic Updates, ClickToRun...).
   - **Tệp tin Crack phổ biến**: Quét các tệp đặc trưng của KMSpico, KMSAuto, KMS VL ALL, v.v.
   - **Services & Tasks**: Kiểm tra dịch vụ hệ thống và tác vụ tự động nghi vấn (như `AutoKMS`).
   - **Chặn máy chủ bản quyền**: Kiểm tra tệp tin `hosts` và quy tắc Firewall chặn Adobe / Autodesk CAD.
   - **IFEO Hijacks**: Phát hiện can thiệp tiến trình quản lý bản quyền (`sppsvc.exe`, `osppsvc.exe`).

5. **Kiểm tra cấu hình bảo mật**
   - Kiểm tra **BitLocker** có được kích hoạt bảo vệ dữ liệu hay không.
   - Kiểm tra can thiệp **Windows Defender** (Bảo vệ thời gian thực, GPO DisableAntiSpyware, SecurityCenter2 WMI).

6. **Kiểm tra cài đặt "Vượt" yêu cầu (Windows 11 Bypasses)**
   - Dò quét `LabConfig` bypass phần cứng trong Registry.
   - Kiểm tra TPM 2.0, Secure Boot thực tế trên thiết bị.

7. **Kiểm tra bản quyền OEM (laptop mới)** `[4.18]` *(mới A.02)*
   - Hiển thị thông tin nhà sản xuất, model máy, phiên bản BIOS/UEFI.
   - Nhận diện thương hiệu OEM (Dell, HP, Lenovo, Asus, Acer, MSI, Samsung, LG, Huawei, Razer...).
   - Phát hiện khóa **OA3 nhúng trong UEFI firmware** (`SoftwareLicensingService.OA3xOriginalProductKey`).
   - Nhận diện kênh kích hoạt Windows OEM: `OEM_SLP`, `OEM_DM`, `OEM_NONSLP`, `OEMTA`.
   - Nhận diện **Digital License / HWID Entitlement** (phương thức OEM phổ biến nhất trên Windows 10/11).
   - Cảnh báo nếu khóa OA3 trong UEFI **không khớp** với khóa Windows hiện tại (dấu hiệu cài lại bằng key ngoài).
   - Phát hiện **Office OEM Perpetual** (Home & Student, Home & Business) pre-install đi kèm máy.

---

### Giai Đoạn 2: Quét Sâu Bảo Mật & Mạng (`chkwinlegit_deep.bat`)

8. **Quét sâu tệp tin né check**
   - Dò quét sâu trong các thư mục người dùng (Downloads, Desktop, AppData, Temp, Program Files) để tìm các tệp tin chứa ký tự ẩn/né tránh chẩn đoán: `@`, `thuoc`, `thuốc`, `unlock`, `crack`, `patch`, `keygen`, `bypass`, `activator`.
   - Hiển thị tiến trình trực quan dạng thanh tiến độ (Progress Bar) chạy ngay trên giao diện console.
   - **Xóa tệp tin crack/can thiệp** sau khi xác nhận `Y/N` từ người dùng (không tự động xóa).

9. **Quét sâu cổng kết nối (Port & Connections)**
   - Phát hiện các tiến trình đang lắng nghe hoặc kết nối qua cổng KMS truyền thống `1688`.
   - Dò quét DNS Client Cache để phát hiện định tuyến tên miền bản quyền về địa chỉ IP loopback.

10. **Kiểm tra sâu cấu hình an toàn hệ thống**
    - Kiểm tra trạng thái **UAC** trong registry.
    - Kiểm tra dịch vụ **Windows Update (wuauserv)** xem có bị vô hiệu hóa trái phép.
    - Kiểm tra chế độ **Test Signing** (ký thử nghiệm driver).

---

## Cơ Chế Phiên Bản (Versioning Scheme)

Phiên bản có định dạng: `[Loại bản vá].[Số bản sửa]` (Ví dụ: `A.02`)

*   **A** - Bản vá nặng, thay đổi lớn về mặt kiến trúc hoặc bổ sung mô-đun quan trọng.
*   **B** - Bản vá vừa, nâng cấp tính năng chẩn đoán.
*   **C** - Bản vá ít, tinh chỉnh độ ổn định, sửa lỗi nhỏ.
*   **D** - Cập nhật bảo mật hoặc tối ưu hóa hiệu suất định kỳ.
*   `0` (Số bản sửa) - Số lượng bản vá sửa đổi nhỏ được tích lũy.

---

## Lịch Sử Phiên Bản (Version History)

*   **vA.02** *(hiện tại)*:
    - **Phát hiện Microsoft 365 Subscription**: Nhận diện đúng kích hoạt qua tài khoản Microsoft (M365/O365) — không còn báo nhầm `OOB_GRACE` là lỗi. Đọc email tài khoản bằng 4 phương pháp fallback.
    - **5 mục kiểm tra Office chuyên sâu mới** `[4.13]`–`[4.17]`: KMS server giả lập, chuyển đổi Retail→Volume GVLK, chữ ký số DLL, license file inject, scheduled task KMS lậu. Tất cả có whitelist để tránh false positive với các task/file Microsoft hợp lệ.
    - **Kiểm tra OEM** `[4.18]`: Nhận diện đầy đủ OA3 UEFI key, kênh OEM_SLP/OEM_DM/Digital License, Office OEM Perpetual, cảnh báo OA3 key mismatch.
    - **Sửa lỗi logic**: `sppc.dll` (Ohook) nay được đưa vào `$detectedCrackFiles` để hiển thị đúng trong danh sách xóa giai đoạn 2.
    - **Sửa false positive** `[4.17]`: Loại bỏ `"Auto"` và `"Activat"` khỏi keyword match; thêm whitelist cho `"Office Automatic Updates"`, `"Office ClickToRun"`, `"OfficeBackgroundTask"`...

*   **vA.01**:
    - Thêm tính năng định dạng và dịch dữ liệu thô JSON sang giao diện Console (UI) trực quan, có màu sắc thân thiện và dễ đọc.
    - Cập nhật số phiên bản đồng bộ lên `A.01` trong cả hai tệp kịch bản và tài liệu.

*   **vA.00**:
    - **Tách kiến trúc hai tệp tin**: Bổ sung `chkwinlegit_deep.bat` để đảm nhận Giai đoạn 2 (Quét sâu).
    - Cấu hình ràng buộc hai chiều: Không cho phép chạy nếu thiếu bất kỳ tệp tin nào.
    - Thêm quét tệp tin né check chứa ký tự đặc biệt (`@`, `thuoc`, `thuốc`, `unlock`).
    - Thêm tính năng đo lường tiến độ và hiển thị thanh tiến trình trực quan ngay trên Console.
    - Thêm quét sâu cổng mạng (Netstat 1688, DNS Cache) và kiểm tra suy giảm bảo mật hệ thống (UAC, Windows Update, Test Signing).

*   **vC.02**:
    - Nâng cấp phần **Đánh giá chung hệ thống (Final Assessment)** với bảng phân tích chi tiết trạng thái của từng thành phần.
    - Cập nhật phần kết luận chi tiết để liệt kê cụ thể các lỗi bảo mật và bản quyền phát hiện được.
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
