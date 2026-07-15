# 2>nul & @echo off & set "BAT_PATH=%~f0" & powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -Encoding UTF8 -LiteralPath '%~f0') -join [Environment]::NewLine)" & exit /b

# PowerShell code starts here...
Clear-Host

# Version & Credit info
$version = "A.00"
$credit = "Made by Duli Software & Antigravity"

# Set console title
$host.UI.RawUI.WindowTitle = "HỆ THỐNG KIỂM TRA BẢN QUYỀN WINDOWS / OFFICE CHÍNH HÃNG - chkwinlegit v$version"

# Check for Administrative Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host " YÊU CẦU QUYỀN ADMINISTRATOR / ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "Đang yêu cầu quyền Administrator để thực hiện quét sâu hệ thống..."
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$env:BAT_PATH`"" -Verb RunAs
    exit
}

# Mutual Dependency Check (If missing stage 2 script, do not run)
$scriptDir = Split-Path $env:BAT_PATH -Parent
$deepScriptPath = Join-Path $scriptDir "chkwinlegit_deep.bat"
if (-not (Test-Path $deepScriptPath)) {
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host " [LỖI THIẾU TỆP TIN] THIẾU TỆP TIN CHẨN ĐOÁN GIAI ĐOẠN 2" -ForegroundColor Red
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "Không tìm thấy tệp tin: chkwinlegit_deep.bat" -ForegroundColor Yellow
    Write-Host "Ứng dụng yêu cầu đầy đủ 2 tệp chkwinlegit.bat và chkwinlegit_deep.bat để hoạt động." -ForegroundColor Yellow
    Write-Host "Vui lòng tải lại đầy đủ bộ tệp tin chkwinlegit."
    Write-Host "Nhấn phím bất kỳ để thoát..."
    [void][System.Console]::ReadKey($true)
    exit
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "   HỆ THỐNG KIỂM TRA BẢN QUYỀN WINDOWS & OFFICE CHÍNH HÃNG (chkwinlegit)" -ForegroundColor White
Write-Host "   Phiên bản: $version | $credit" -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. SYSTEM METADATA
Write-Host "[1] THÔNG TIN HỆ THỐNG & THỜI GIAN CÀI ĐẶT" -ForegroundColor Blue
Write-Host "--------------------------------------------------------------------------------"
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$formattedDate = "Không xác định"
if ($os.InstallDate) {
    $formattedDate = $os.InstallDate.ToString("dd/MM/yyyy HH:mm")
}

# Get Device Identifiers
$uuid = "Không xác định"
$machineGuid = "Không xác định"
$computerProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
if ($computerProduct) {
    $uuid = $computerProduct.UUID
}
$cryptoKey = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -ErrorAction SilentlyContinue
if ($cryptoKey -and $cryptoKey.MachineGuid) {
    $machineGuid = $cryptoKey.MachineGuid
}

Write-Host " * Hệ điều hành  : $($os.Caption) ($($os.OSArchitecture))"
Write-Host " * Phiên bản     : $($os.Version)"
Write-Host " * Ngày cài đặt  : $formattedDate"
Write-Host " * Device UUID   : $uuid"
Write-Host " * Machine GUID  : $machineGuid"
Write-Host ""

# 2. WINDOWS ACTIVATION STATUS
Write-Host "[2] TRẠNG THÁI BẢN QUYỀN WINDOWS" -ForegroundColor Blue
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
        Write-Host $status -ForegroundColor $color
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
Write-Host "[3] TRẠNG THÁI BẢN QUYỀN MICROSOFT OFFICE" -ForegroundColor Blue
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
                    Write-Host "   $($line.Trim())" -ForegroundColor Green
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
Write-Host "[4] QUÉT SÂU HỆ THỐNG PHÁT HIỆN CAN THIỆP & BẢN QUYỀN LẬU" -ForegroundColor Blue
Write-Host "--------------------------------------------------------------------------------"
$tamperDetected = $false
$suspiciousDetected = $false
$suspiciousReasons = @()

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

# 4.9 BitLocker Encryption Status Check
Write-Host " [4.9] Kiểm tra trạng thái mã hóa BitLocker..."
$bitlockerActive = $false
$volumes = Get-BitLockerVolume -ErrorAction SilentlyContinue
if ($volumes) {
    foreach ($vol in $volumes) {
        $protection = if ($vol.ProtectionStatus -eq "On") {
            $bitlockerActive = $true
            "BẬT (Đã bảo vệ)"
        } else {
            "TẮT (Chưa bảo vệ)"
        }
        $color = if ($vol.ProtectionStatus -eq "On") { "Green" } else { "Yellow" }
        Write-Host "   * Ổ $($vol.MountPoint) ($($vol.VolumeType)) : " -NoNewline
        Write-Host $protection -ForegroundColor $color
    }
} else {
    Write-Host "   [+] Không tìm thấy ổ đĩa nào cấu hình BitLocker hoặc không được hỗ trợ trên ấn bản Windows này." -ForegroundColor Yellow
}

# 4.10 Windows Defender Tampering & Status Check
Write-Host " [4.10] Kiểm tra trạng thái và can thiệp Windows Defender..."
$defenderTampered = $false
$defReasons = @()

# Check Defender Service
$defService = Get-Service -Name WinDefender -ErrorAction SilentlyContinue
if ($defService) {
    if ($defService.Status -ne "Running") {
        $defenderTampered = $true
        $defReasons += "Dịch vụ WinDefender đang ở trạng thái: $($defService.Status) (Yêu cầu: Running)"
    }
} else {
    $defenderTampered = $true
    $defReasons += "Không tìm thấy dịch vụ WinDefender trên hệ thống!"
}

# Check MpComputerStatus (Real-Time Protection)
$mp = Get-MpComputerStatus -ErrorAction SilentlyContinue
if ($mp) {
    if (-not $mp.RealTimeProtectionEnabled) {
        $defenderTampered = $true
        $defReasons += "Bảo vệ thời gian thực (Real-Time Protection) đang bị TẮT"
    }
    if (-not $mp.AntivirusEnabled) {
        $defenderTampered = $true
        $defReasons += "Bảo vệ diệt virus (Antivirus Enabled) đang bị TẮT"
    }
} else {
    $defenderTampered = $true
    $defReasons += "Không thể kết nối đến trình quản lý trạng thái Windows Defender (MpComputerStatus)"
}

# Check Policies Registry (DisableAntiSpyware GPO)
$gpoDefPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
if (Test-Path $gpoDefPath) {
    $gpoKeys = Get-ItemProperty -Path $gpoDefPath -ErrorAction SilentlyContinue
    if ($gpoKeys -and $gpoKeys.DisableAntiSpyware -eq 1) {
        $defenderTampered = $true
        $defReasons += "Phát hiện DisableAntiSpyware = 1 trong Group Policy (Vô hiệu hóa Defender)"
    }
}

if ($defenderTampered) {
    Write-Host "   [!] Phát hiện can thiệp hoặc Windows Defender bị tắt không an toàn!" -ForegroundColor Red
    foreach ($reason in $defReasons) {
        Write-Host "      -> $reason" -ForegroundColor Red
    }
    $tamperDetected = $true
} else {
    Write-Host "   [+] Windows Defender đang hoạt động bình thường, bảo vệ thời gian thực BẬT." -ForegroundColor Green
}

# 4.11 Check for Adobe & Autodesk CAD Cracks
Write-Host " [4.11] Quét dấu vết phần mềm Adobe & Autodesk CAD bẻ khóa..."
$crackAppsFound = $false
$crackAppDetails = @()

# Check for old Adobe patch dll (amtlib.dll)
$adobePath = "$env:ProgramFiles\Adobe"
$adobePathX86 = "${env:ProgramFiles(x86)}\Adobe"
$amtlibFound = @()
if (Test-Path $adobePath) {
    $amtlibFound += Get-ChildItem -Path $adobePath -Filter "amtlib.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}
if (Test-Path $adobePathX86) {
    $amtlibFound += Get-ChildItem -Path $adobePathX86 -Filter "amtlib.dll" -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}

if ($amtlibFound.Count -gt 0) {
    $crackAppsFound = $true
    $tamperDetected = $true
    $crackAppDetails += "Phát hiện tệp tin crack cổ điển 'amtlib.dll' trong thư mục Adobe:"
    foreach ($path in $amtlibFound) {
        $crackAppDetails += "      -> $path"
    }
}

# Check Firewall block rules blocking Adobe & Autodesk outbound
$adobeRules = Get-NetFirewallRule -DisplayName "*Adobe*" -ErrorAction SilentlyContinue | Where-Object { $_.Action -eq "Block" }
if ($adobeRules) {
    $crackAppsFound = $true
    $tamperDetected = $true
    $crackAppDetails += "Phát hiện $($adobeRules.Count) quy tắc chặn Tường lửa (Firewall) đối với sản phẩm Adobe (Dấu hiệu Adobe GenP/Monkrus)."
}

$autodeskRules = Get-NetFirewallRule -DisplayName "*Autodesk*" -ErrorAction SilentlyContinue | Where-Object { $_.Action -eq "Block" }
if ($autodeskRules) {
    $crackAppsFound = $true
    $tamperDetected = $true
    $crackAppDetails += "Phát hiện $($autodeskRules.Count) quy tắc chặn Tường lửa đối với sản phẩm Autodesk CAD."
}

# Check hosts file for Adobe/Autodesk blocklist domains
if (Test-Path $hostsPath) {
    $blockedSoftwareDomains = "adobe.com|activate.adobe|lmlicenses.wip4.adobe.com|na1r.services.adobe.com|genuine-software.autodesk.com"
    $hostsTamperedSoftware = $hostsContent | Where-Object { $_ -notmatch "^\s*#" -and $_ -match $blockedSoftwareDomains }
    if ($hostsTamperedSoftware) {
        $crackAppsFound = $true
        $tamperDetected = $true
        $crackAppDetails += "Phát hiện cấu hình chặn máy chủ bản quyền Adobe/Autodesk trong tệp hosts:"
        foreach ($line in $hostsTamperedSoftware) {
            $crackAppDetails += "      -> $($line.Trim())"
        }
    }
}

if ($crackAppsFound) {
    Write-Host "   [!] Phát hiện dấu vết bẻ khóa hoặc can thiệp bản quyền phần mềm Adobe / Autodesk CAD!" -ForegroundColor Red
    foreach ($detail in $crackAppDetails) {
        Write-Host "      $detail" -ForegroundColor Red
    }
} else {
    Write-Host "   [+] Không phát hiện dấu vết bẻ khóa phổ biến đối với sản phẩm Adobe và Autodesk CAD." -ForegroundColor Green
}

# 4.12 Bypassed OS Requirements Check ("Vượt" Windows 11 Check)
Write-Host " [4.12] Kiểm tra thiết bị cài đặt 'vượt' yêu cầu hệ thống (Windows 11)..."
$isBypassedInstall = $false
$bypassReasons = @()

$versionParts = $os.Version.Split('.')
$buildNum = 0
if ($versionParts.Count -ge 3) {
    [void][int]::TryParse($versionParts[2], [ref]$buildNum)
}

if ($buildNum -ge 22000) {
    # It is Windows 11. Check hardware requirements.
    
    # 1. Check TPM
    $tpm = Get-Tpm -ErrorAction SilentlyContinue
    if (-not $tpm -or -not $tpm.TpmPresent) {
        $isBypassedInstall = $true
        $bypassReasons += "Không tìm thấy chip TPM (Yêu cầu TPM 2.0)"
    } else {
        $tpmWmi = Get-CimInstance -Namespace root\CIMV2\Security\MicrosoftTpm -ClassName Win32_Tpm -ErrorAction SilentlyContinue
        if ($tpmWmi) {
            $spec = $tpmWmi.SpecVersion.Split(',')[0].Trim()
            if ($spec -ne "2.0") {
                $isBypassedInstall = $true
                $bypassReasons += "Phiên bản TPM là $spec (Yêu cầu TPM 2.0)"
            }
        }
    }
    
    # 2. Check Secure Boot
    try {
        $sb = Confirm-SecureBootUEFI
        if (-not $sb) {
            $isBypassedInstall = $true
            $bypassReasons += "Secure Boot đang TẮT"
        }
    } catch {
        $isBypassedInstall = $true
        $bypassReasons += "Hệ thống chạy trên Legacy BIOS / Không hỗ trợ Secure Boot"
    }
    
    # 3. Check LabConfig bypasses in Registry
    $labConfigPath = "HKLM:\SYSTEM\Setup\LabConfig"
    if (Test-Path $labConfigPath) {
        $bypassKeys = Get-ItemProperty -Path $labConfigPath -ErrorAction SilentlyContinue
        $foundBypasses = @()
        if ($bypassKeys -and $bypassKeys.BypassTPMCheck -eq 1) { $foundBypasses += "BypassTPMCheck" }
        if ($bypassKeys -and $bypassKeys.BypassSecureBootCheck -eq 1) { $foundBypasses += "BypassSecureBootCheck" }
        if ($bypassKeys -and $bypassKeys.BypassRAMCheck -eq 1) { $foundBypasses += "BypassRAMCheck" }
        if ($bypassKeys -and $bypassKeys.BypassCPUCheck -eq 1) { $foundBypasses += "BypassCPUCheck" }
        if ($bypassKeys -and $bypassKeys.BypassStorageCheck -eq 1) { $foundBypasses += "BypassStorageCheck" }
        
        if ($foundBypasses.Count -gt 0) {
            $isBypassedInstall = $true
            $bypassReasons += "Phát hiện cấu hình bypass trong Registry: $($foundBypasses -join ', ')"
        }
    }
}

if ($isBypassedInstall) {
    Write-Host "   [!] Phát hiện thiết bị chạy Windows 11 'vượt' yêu cầu phần cứng cũ của Microsoft!" -ForegroundColor Yellow
    foreach ($reason in $bypassReasons) {
        Write-Host "      -> $reason" -ForegroundColor Yellow
    }
    $suspiciousDetected = $true
    $suspiciousReasons += "Thiết bị không đáp ứng tiêu chuẩn phần cứng Windows 11 nhưng đã cài đặt vượt."
} else {
    if ($buildNum -ge 22000) {
        Write-Host "   [+] Thiết bị đáp ứng đầy đủ tiêu chuẩn phần cứng Windows 11." -ForegroundColor Green
    } else {
        Write-Host "   [+] Phiên bản Windows cũ hơn Windows 11, không áp dụng kiểm tra vượt yêu cầu." -ForegroundColor Green
    }
}
Write-Host ""

# 5. FINAL ASSESSMENT
Write-Host "[5] ĐÁNH GIÁ CHUNG HỆ THỐNG / FINAL ASSESSMENT" -ForegroundColor Blue
Write-Host "--------------------------------------------------------------------------------"
Write-Host " Báo cáo chi tiết các thành phần hệ thống:"

# 5.1 Check domain join status
$isDomainJoined = $false
$compSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
if ($compSystem) {
    $isDomainJoined = $compSystem.PartOfDomain
}

# 5.2 Render component statuses
# Windows status
Write-Host "  * Hệ thống Windows : " -NoNewline
if ($winKms -or $winGuidKms -or ($channel -like "*KMSCLIENT*" -and -not $isDomainJoined -and $tamperDetected)) {
    Write-Host "PHÁT HIỆN CAN THIỆP (KMS/KMS38/Bypass)" -ForegroundColor Red
} elseif ($channel -like "*KMSCLIENT*" -and -not $isDomainJoined) {
    Write-Host "NGHI VẤN (KMS Volume cá nhân)" -ForegroundColor Yellow
} elseif ($winProducts -and $winProducts[0].LicenseStatus -eq 1) {
    Write-Host "CHÍNH HÃNG (Genuine - $channel)" -ForegroundColor Green
} else {
    Write-Host "CHƯA KÍCH HOẠT / HẾT HẠN" -ForegroundColor Red
}

# Office status
Write-Host "  * Microsoft Office : " -NoNewline
if ($ohookDetected) {
    Write-Host "PHÁT HIỆN CRACK (Bypass Ohook sppc.dll)" -ForegroundColor Red
} elseif ($officeKms -or $officeGuidKms) {
    Write-Host "PHÁT HIỆN CAN THIỆP (KMS Redirect)" -ForegroundColor Red
} elseif ($osppPaths.Count -gt 0) {
    Write-Host "ĐÃ CÀI ĐẶT (Cần xem chi tiết trạng thái ở mục [3])" -ForegroundColor Cyan
} else {
    Write-Host "KHÔNG PHÁT HIỆN CÀI ĐẶT" -ForegroundColor Gray
}

# Defender status
Write-Host "  * Trình bảo vệ     : " -NoNewline
if ($defenderTampered) {
    Write-Host "BÌ CAN THIỆP / VÔ HIỆU HÓA" -ForegroundColor Red
} else {
    Write-Host "BẢO VỆ TỐT (Hoạt động)" -ForegroundColor Green
}

# BitLocker status
Write-Host "  * Mã hóa BitLocker : " -NoNewline
if ($bitlockerActive) {
    Write-Host "ĐÃ KÍCH HOẠT (Bảo vệ dữ liệu)" -ForegroundColor Green
} else {
    Write-Host "TẮT (Chưa mã hóa)" -ForegroundColor Yellow
}

# Third-party Apps (Adobe & CAD)
Write-Host "  * Adobe & Autodesk : " -NoNewline
if ($crackAppsFound) {
    Write-Host "PHÁT HIỆN DẤU HIỆU BẺ KHÓA (Patch/Firewall/Hosts)" -ForegroundColor Red
} else {
    Write-Host "KHÔNG PHÁT HIỆN CAN THIỆP" -ForegroundColor Green
}

# Windows 11 Compatibility Bypass
Write-Host "  * Tiêu chuẩn Win 11: " -NoNewline
if ($isBypassedInstall) {
    Write-Host "ĐÃ VƯỢT YÊU CẦU (Bypassed Hardware)" -ForegroundColor Yellow
} else {
    Write-Host "ĐẠT TIÊU CHUẨN / KHÔNG ÁP DỤNG" -ForegroundColor Green
}
Write-Host ""

# 5.3 Final Assessment Classification
$assessment = "GENUINE"

if ($tamperDetected) {
    $assessment = "CRACKED"
} elseif ($suspiciousDetected) {
    $assessment = "SUSPICIOUS"
} else {
    if ($channel -like "*KMSCLIENT*" -and -not $isDomainJoined) {
        $assessment = "SUSPICIOUS"
        $suspiciousReasons += "Sử dụng khóa KMS Volume trên máy cá nhân không gia nhập miền doanh nghiệp."
    }
}

if ($assessment -eq "GENUINE") {
    Write-Host " ========================================================================" -ForegroundColor Green
    Write-Host "    KẾT QUẢ CHUNG: HỆ THỐNG HOÀN TOÀN CHÍNH HÃNG (GENUINE / CLEAN)" -ForegroundColor Green
    Write-Host " ========================================================================" -ForegroundColor Green
    Write-Host "  * Không phát hiện bất kỳ dấu vết can thiệp, tệp tin crack, dịch vụ lậu," -ForegroundColor Green
    Write-Host "  * hay cấu hình chuyển hướng KMS giả mạo nào trên thiết bị này." -ForegroundColor Green
    Write-Host "  * Trình bảo vệ Windows Defender hoạt động an toàn." -ForegroundColor Green
} elseif ($assessment -eq "SUSPICIOUS") {
    Write-Host " ========================================================================" -ForegroundColor Yellow
    Write-Host "    KẾT QUẢ CHUNG: PHÁT HIỆN DẤU HIỆU NGHI VẤN (SUSPICIOUS)" -ForegroundColor Yellow
    Write-Host " ========================================================================" -ForegroundColor Yellow
    Write-Host "  * Hệ thống phát hiện các cấu hình nghi vấn sau:" -ForegroundColor Yellow
    foreach ($reason in $suspiciousReasons) {
        Write-Host "      -> $reason" -ForegroundColor Yellow
    }
} else {
    Write-Host " ========================================================================" -ForegroundColor Red
    Write-Host "    KẾT QUẢ CHUNG: PHÁT HIỆN CAN THIỆP BẢN QUYỀN LẬU / BẢO MẬT BỊ TẮT" -ForegroundColor Red
    Write-Host " ========================================================================" -ForegroundColor Red
    Write-Host "  * Thiết bị phát hiện các vấn đề nghiêm trọng:" -ForegroundColor Red
    if ($winKms -or $winGuidKms) { 
        Write-Host "      - Windows bị can thiệp máy chủ KMS hoặc cấu hình KMS38." -ForegroundColor Red 
    }
    if ($ohookDetected -or $officeKms -or $officeGuidKms) { 
        Write-Host "      - Microsoft Office sử dụng cơ chế bypass Ohook hoặc cấu hình KMS lậu." -ForegroundColor Red 
    }
    if ($defenderTampered) { 
        Write-Host "      - Trình bảo vệ Windows Defender bị can thiệp/tắt bảo vệ thời gian thực." -ForegroundColor Red 
    }
    if ($crackAppsFound) { 
        Write-Host "      - Phát hiện dấu vết bẻ khóa hoặc cấu hình chặn tường lửa/hosts cho phần mềm Adobe / Autodesk CAD." -ForegroundColor Red 
    }
}
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Bạn có muốn tiến hành quét sâu Giai đoạn 2 (Quét tệp né check, cổng mạng, bảo mật)? [Y/N]: " -NoNewline
$response = Read-Host
if ($response -eq "Y" -or $response -eq "y") {
    Write-Host "Đang khởi chạy Giai đoạn 2..." -ForegroundColor Yellow
    cmd.exe /c "`"$deepScriptPath`""
} else {
    Write-Host "Đã hủy bỏ quét sâu Giai đoạn 2." -ForegroundColor Yellow
    Write-Host "Nhấn phím bất kỳ để thoát..."
    [void][System.Console]::ReadKey($true)
}
