# 2>nul & @echo off & set "BAT_PATH=%~f0" & powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -Encoding UTF8 -LiteralPath '%~f0') -join [Environment]::NewLine)" & exit /b

# PowerShell code starts here...
Clear-Host

# Set console title
$host.UI.RawUI.WindowTitle = "HỆ THỐNG KIỂM TRA BẢN QUYỀN WINDOWS / OFFICE CHÍNH HÃNG - chkwinlegit"

# Check for Administrative Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host " YÊU CẦU QUYỀN ADMINISTRATOR / ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Yellow -Bold
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "Đang yêu cầu quyền Administrator để thực hiện quét sâu hệ thống..."
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$env:BAT_PATH`"" -Verb RunAs
    exit
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "   HỆ THỐNG KIỂM TRA BẢN QUYỀN WINDOWS & OFFICE CHÍNH HÃNG (chkwinlegit)" -ForegroundColor White -Bold
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. SYSTEM METADATA
Write-Host "[1] THÔNG TIN HỆ THỐNG & THỜI GIAN CÀI ĐẶT" -ForegroundColor Blue -Bold
Write-Host "--------------------------------------------------------------------------------"
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$formattedDate = "Không xác định"
if ($os.InstallDate) {
    $formattedDate = $os.InstallDate.ToString("dd/MM/yyyy HH:mm")
}
Write-Host " * Hệ điều hành  : $($os.Caption) ($($os.OSArchitecture))"
Write-Host " * Phiên bản     : $($os.Version)"
Write-Host " * Ngày cài đặt  : $formattedDate"
Write-Host ""

# 2. WINDOWS ACTIVATION STATUS
Write-Host "[2] TRẠNG THÁI BẢN QUYỀN WINDOWS" -ForegroundColor Blue -Bold
Write-Host "--------------------------------------------------------------------------------"
$winProducts = Get-CimInstance -Namespace root\CIMV2 -ClassName SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -and $_.Description -like "*Windows*" }

$channel = "Không xác định"

if ($winProducts) {
    foreach ($product in $winProducts) {
        $status = switch ($product.LicenseStatus) {
            1 { "LICENSED (Đã kích hoạt chính thức)" }
            0 { "UNLICENSED (Chưa kích hoạt)" }
            2 { "OOB_GRACE (Dùng thử)" }
            3 { "OOT_GRACE (Hết hạn dùng thử)" }
            4 { "NON_GENUINE_GRACE (Không chính hãng)" }
            5 { "NOTIFICATION (Cảnh báo bản quyền)" }
            6 { "EXTENDED_GRACE (Gia hạn dùng thử)" }
            Default { "Không xác định" }
        }
        $color = if ($product.LicenseStatus -eq 1) { "Green" } else { "Red" }
        Write-Host " * Trạng thái    : " -NoNewline
        Write-Host $status -ForegroundColor $color -Bold
        Write-Host " * Mô tả bản dịch: $($product.Description)"
        
        # Get activation channel using slmgr
        $slmgrDli = cscript //nologo C:\Windows\System32\slmgr.vbs /dli 2>$null
        $channelLine = $slmgrDli | Where-Object { $_ -like "*channel*" }
        if ($channelLine) {
            $channel = $channelLine.Trim()
        }
        Write-Host " * Kênh kích hoạt: $channel"
    }
} else {
    Write-Host " * Trạng thái    : Không tìm thấy thông tin bản quyền Windows." -ForegroundColor Red
}
Write-Host ""

# 3. OFFICE ACTIVATION STATUS
Write-Host "[3] TRẠNG THÁI BẢN QUYỀN MICROSOFT OFFICE" -ForegroundColor Blue -Bold
Write-Host "--------------------------------------------------------------------------------"

$programFiles = [Environment]::GetFolderPath("ProgramFiles")
$programFilesX86 = [Environment]::GetFolderPath("ProgramFilesX86")
$osppPaths = @()
if (Test-Path "$programFiles\Microsoft Office") {
    $osppPaths += Get-ChildItem -Path "$programFiles\Microsoft Office" -Filter "ospp.vbs" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}
if (Test-Path "$programFilesX86\Microsoft Office") {
    $osppPaths += Get-ChildItem -Path "$programFilesX86\Microsoft Office" -Filter "ospp.vbs" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}

$osppPaths = $osppPaths | Select-Object -Unique

if ($osppPaths.Count -eq 0) {
    Write-Host " * Không tìm thấy cài đặt Office truyền thống (Click-to-Run hoặc UWP)." -ForegroundColor Yellow
} else {
    foreach ($osppPath in $osppPaths) {
        Write-Host " * Tìm thấy OSPP.vbs tại: $osppPath"
        $osppOutput = cscript //nologo "$osppPath" /dstatus 2>$null
        $relevantLines = $osppOutput | Where-Object { $_ -match "LICENSE STATUS:|LICENSE NAME:|PRODUCT ID:|Description:|KEY:" }
        if ($relevantLines) {
            foreach ($line in $relevantLines) {
                if ($line -match "LICENSED") {
                    Write-Host "   $($line.Trim())" -ForegroundColor Green -Bold
                } elseif ($line -match "NOT LICENSED") {
                    Write-Host "   $($line.Trim())" -ForegroundColor Red
                } else {
                    Write-Host "   $($line.Trim())"
                }
            }
        } else {
            Write-Host "   Không trích xuất được thông tin bản quyền từ OSPP.vbs." -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# 4. DEEP PIRACY SCAN & TAMPERING DETECTION
Write-Host "[4] QUÉT SÂU HỆ THỐNG PHÁT HIỆN CAN THIỆP & BẢN QUYỀN LẬU" -ForegroundColor Blue -Bold
Write-Host "--------------------------------------------------------------------------------"
$tamperDetected = $false

# 4.1 Check Windows KMS Host Registry
Write-Host " [4.1] Kiểm tra cấu hình KMS Host của Windows..."
$sppKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
$winKms = $null
$winGuidKms = $null

if (Test-Path $sppKey) {
    $winKms = (Get-ItemProperty -Path $sppKey -Name KeyManagementServiceServer -ErrorAction SilentlyContinue).KeyManagementServiceServer
    $guidKey = "$sppKey\55c92734-d682-4d71-983e-d6ec3f16059f"
    if (Test-Path $guidKey) {
        $winGuidKms = (Get-ItemProperty -Path $guidKey -Name KeyManagementServiceServer -ErrorAction SilentlyContinue).KeyManagementServiceServer
    }
}

if ($winKms) {
    Write-Host "   [!] Phát hiện Windows KMS Host Registry: $winKms" -ForegroundColor Red
    $tamperDetected = $true
} else {
    Write-Host "   [+] Cấu hình Windows KMS mặc định (Không bị ghi đè)." -ForegroundColor Green
}

if ($winGuidKms) {
    Write-Host "   [!] Phát hiện Windows Client KMS GUID Registry: $winGuidKms" -ForegroundColor Red
    if ($winGuidKms -eq "127.0.0.2") {
        Write-Host "      [-] Địa chỉ 127.0.0.2 là đặc trưng của kích hoạt KMS38 (đến năm 2038)." -ForegroundColor Yellow
    }
    $tamperDetected = $true
}

# 4.2 Check Office KMS Host Registry
Write-Host " [4.2] Kiểm tra cấu hình KMS Host của Office..."
$officeSppKey = "HKLM:\SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
$officeKms = $null
$officeGuidKms = $null

if (Test-Path $officeSppKey) {
    $officeKms = (Get-ItemProperty -Path $officeSppKey -Name KeyManagementServiceServer -ErrorAction SilentlyContinue).KeyManagementServiceServer
}
$officeGuidKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform\0ff1ce15-a989-47d8-bc5f-7265743b10f5"
if (Test-Path $officeGuidKey) {
    $officeGuidKms = (Get-ItemProperty -Path $officeGuidKey -Name KeyManagementServiceServer -ErrorAction SilentlyContinue).KeyManagementServiceServer
}

if ($officeKms) {
    Write-Host "   [!] Phát hiện Office KMS Host Registry: $officeKms" -ForegroundColor Red
    $tamperDetected = $true
} else {
    Write-Host "   [+] Cấu hình Office KMS mặc định (Không bị ghi đè)." -ForegroundColor Green
}

if ($officeGuidKms) {
    Write-Host "   [!] Phát hiện Office Client KMS GUID Registry: $officeGuidKms" -ForegroundColor Red
    $tamperDetected = $true
}

# 4.3 Check for Ohook DLL
Write-Host " [4.3] Quét tệp Ohook (Sppc.dll Bypass) trong thư mục Office..."
$ohookDetected = $false
$ohookPaths = @(
    "$env:ProgramFiles\Microsoft Office\root\vfs\System\sppc.dll",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\vfs\System\sppc.dll",
    "$env:ProgramFiles\Microsoft Office\root\Office16\sppc.dll",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\sppc.dll"
)
foreach ($path in $ohookPaths) {
    if (Test-Path $path) {
        Write-Host "   [!] Phát hiện tệp Bypass Ohook tại: $path" -ForegroundColor Red
        $ohookDetected = $true
        $tamperDetected = $true
    }
}
if (-not $ohookDetected) {
    Write-Host "   [+] Không phát hiện tệp bypass Ohook trong các thư mục Office." -ForegroundColor Green
}

# 4.4 Check for Known Crack Files
Write-Host " [4.4] Quét các tệp crack/activator phổ biến trên hệ thống..."
$crackFileFound = $false
$crackPaths = @(
    "$env:ProgramFiles\KMSpico\KMSELDI.exe",
    "$env:ProgramFiles\KMSpico\AutoPico.exe",
    "${env:ProgramFiles(x86)}\KMSpico\KMSELDI.exe",
    "${env:ProgramFiles(x86)}\KMSpico\AutoPico.exe",
    "$env:windir\System32\SppExtComObjHook.dll",
    "$env:windir\SysWOW64\SppExtComObjHook.dll",
    "$env:windir\SECOH-QAD.exe",
    "$env:windir\SECOH-QAD.dll",
    "$env:ProgramData\Microsoft\Windefender\KMSAuto.exe",
    "$env:ProgramData\KMSAutoS\KMSAuto.exe"
)
foreach ($path in $crackPaths) {
    if (Test-Path $path) {
        Write-Host "   [!] Phát hiện tệp tin của công cụ Crack: $path" -ForegroundColor Red
        $crackFileFound = $true
        $tamperDetected = $true
    }
}
if (-not $crackFileFound) {
    Write-Host "   [+] Không phát hiện tệp tin crack phổ biến (KMSpico, KMSAuto, KMS VL ALL...)." -ForegroundColor Green
}

# 4.5 Check for Pirate Services
Write-Host " [4.5] Kiểm tra dịch vụ hệ thống nghi vấn..."
$serviceFound = $false
$pirateServices = @("AutoKMS", "KMSpicoService", "KMS-Service")
foreach ($service in $pirateServices) {
    $srv = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($srv) {
        Write-Host "   [!] Phát hiện dịch vụ crack đang chạy/tồn tại: $service" -ForegroundColor Red
        $serviceFound = $true
        $tamperDetected = $true
    }
}
if (-not $serviceFound) {
    Write-Host "   [+] Không tìm thấy dịch vụ crack (AutoKMS, KMSpicoService, KMS-Service)." -ForegroundColor Green
}

# 4.6 Check for Pirate Scheduled Tasks
Write-Host " [4.6] Kiểm tra tác vụ tự động (Scheduled Tasks) khả nghi..."
$taskFound = $false
$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -match "AutoKMS|KMSAuto|KMSVLALL|MAS_|KMS_" }
if ($tasks) {
    foreach ($task in $tasks) {
        Write-Host "   [!] Phát hiện tác vụ tự động nghi vấn: $($task.TaskName) (Đường dẫn: $($task.TaskPath))" -ForegroundColor Red
        $taskFound = $true
        $tamperDetected = $true
    }
}
if (-not $taskFound) {
    Write-Host "   [+] Không tìm thấy tác vụ tự động nào liên quan đến crack." -ForegroundColor Green
}

# 4.7 Check Hosts File for Redirection
Write-Host " [4.7] Kiểm tra tệp tin hosts (chặn/điều hướng máy chủ Microsoft)..."
$hostsTampered = $false
$hostsPath = "$env:windir\System32\drivers\etc\hosts"
if (Test-Path $hostsPath) {
    $hostsContent = Get-Content $hostsPath
    $pirateDomains = "kms.microsoft.com|activation.microsoft.com|validation.microsoft.com|licensing.microsoft.com|massgrave"
    $tamperLines = $hostsContent | Where-Object { $_ -notmatch "^\s*#" -and $_ -match $pirateDomains }
    if ($tamperLines) {
        Write-Host "   [!] Phát hiện dòng can thiệp máy chủ bản quyền trong tệp hosts:" -ForegroundColor Red
        foreach ($line in $tamperLines) {
            Write-Host "      -> $($line.Trim())" -ForegroundColor Red
        }
        $hostsTampered = $true
        $tamperDetected = $true
    }
}
if (-not $hostsTampered) {
    Write-Host "   [+] Tệp tin hosts sạch (Không chứa các cấu hình chặn kích hoạt)." -ForegroundColor Green
}

# 4.8 Image File Execution Options (IFEO) Hijacks Check
Write-Host " [4.8] Kiểm tra IFEO Registry Hijacks..."
$ifeoHijacked = $false
$ifeoPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sppsvc.exe",
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\osppsvc.exe",
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\slmgr.vbs"
)
foreach ($path in $ifeoPaths) {
    if (Test-Path $path) {
        $debugger = (Get-ItemProperty -Path $path -Name Debugger -ErrorAction SilentlyContinue).Debugger
        if ($debugger) {
            Write-Host "   [!] Phát hiện tiến trình $(Split-Path $path -Leaf) bị hijack trong IFEO Registry: Debugger = $debugger" -ForegroundColor Red
            $ifeoHijacked = $true
            $tamperDetected = $true
        }
    }
}
if (-not $ifeoHijacked) {
    Write-Host "   [+] Không phát hiện can thiệp IFEO đối với các tiến trình bản quyền." -ForegroundColor Green
}
Write-Host ""

# 5. FINAL ASSESSMENT
Write-Host "[5] ĐÁNH GIÁ CHUNG HỆ THỐNG / FINAL ASSESSMENT" -ForegroundColor Blue -Bold
Write-Host "--------------------------------------------------------------------------------"

$isDomainJoined = $false
$compSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
if ($compSystem) {
    $isDomainJoined = $compSystem.PartOfDomain
}
$assessment = "GENUINE"

if ($tamperDetected) {
    $assessment = "CRACKED"
} else {
    if ($channel -like "*KMSCLIENT*" -and -not $isDomainJoined) {
        Write-Host " [!] Cảnh báo: Windows sử dụng kênh KMS nhưng máy tính không thuộc Domain doanh nghiệp." -ForegroundColor Yellow
        $assessment = "SUSPICIOUS"
    }
}

if ($assessment -eq "GENUINE") {
    Write-Host " ========================================================================" -ForegroundColor Green -Bold
    Write-Host "    KẾT QUẢ: HỆ THỐNG HOÀN TOÀN CHÍNH HÃNG (GENUINE / CLEAN)" -ForegroundColor Green -Bold
    Write-Host " ========================================================================" -ForegroundColor Green -Bold
    Write-Host "  * Không phát hiện bất kỳ dấu vết can thiệp, tệp tin crack, dịch vụ lậu," -ForegroundColor Green
    Write-Host "  * hay cấu hình chuyển hướng KMS giả mạo nào trên thiết bị này." -ForegroundColor Green
} elseif ($assessment -eq "SUSPICIOUS") {
    Write-Host " ========================================================================" -ForegroundColor Yellow -Bold
    Write-Host "    KẾT QUẢ: PHÁT HIỆN DẤU HIỆU NGHI VẤN (SUSPICIOUS)" -ForegroundColor Yellow -Bold
    Write-Host " ========================================================================" -ForegroundColor Yellow -Bold
    Write-Host "  * Hệ thống sử dụng cơ chế cấp phép KMS dành cho doanh nghiệp nhưng thiết bị" -ForegroundColor Yellow
    Write-Host "  * hiện tại là cá nhân (không gia nhập miền). Bản quyền có thể đã được nạp" -ForegroundColor Yellow
    Write-Host "  * bằng các khóa generic (GVLK) mà không có máy chủ KMS nội bộ hợp lệ." -ForegroundColor Yellow
} else {
    Write-Host " ========================================================================" -ForegroundColor Red -Bold
    Write-Host "    KẾT QUẢ: PHÁT HIỆN CAN THIỆP BẢN QUYỀN LẬU (CRACKED / TAMPERED)" -ForegroundColor Red -Bold
    Write-Host " ========================================================================" -ForegroundColor Red -Bold
    Write-Host "  * Hệ thống phát hiện các cấu hình máy chủ KMS nội bộ (loopback), các tệp tin" -ForegroundColor Red
    Write-Host "  * bypass dll (Ohook sppc.dll), tệp tin crack hoặc dịch vụ kích hoạt không" -ForegroundColor Red
    Write-Host "  * chính thức của bên thứ ba (KMSpico, KMSAuto, MAS, v.v.)." -ForegroundColor Red
}
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Nhấn phím bất kỳ để thoát..."
[void][System.Console]::ReadKey($true)
