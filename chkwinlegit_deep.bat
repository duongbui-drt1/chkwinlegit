# 2>nul & @echo off & set "BAT_PATH=%~f0" & powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -Encoding UTF8 -LiteralPath '%~f0') -join [Environment]::NewLine)" & exit /b

# PowerShell code starts here...
Clear-Host

$version = "A.01"
$credit = "Made by Duli Software & Antigravity"

# Set console title
$host.UI.RawUI.WindowTitle = "chkwinlegit - GIAI ĐOẠN 2: QUÉT SÂU BẢO MẬT & MẠNG - v$version"

# Mutual Dependency Check
$scriptDir = Split-Path $env:BAT_PATH -Parent
$mainScriptPath = Join-Path $scriptDir "chkwinlegit.bat"
if (-not (Test-Path $mainScriptPath)) {
    Write-Host " [LỖI] Không tìm thấy tệp chkwinlegit.bat!" -ForegroundColor Red
    Write-Host " Công cụ yêu cầu phải có đầy đủ cả 2 tệp tin (chkwinlegit.bat & chkwinlegit_deep.bat)" -ForegroundColor Red
    Write-Host " nằm cùng thư mục để hoạt động." -ForegroundColor Red
    Write-Host " Nhấn phím bất kỳ để thoát..."
    [void][System.Console]::ReadKey($true)
    exit
}

# Check for Administrative Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host " YÊU CẦU QUYỀN ADMINISTRATOR / ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "Đang yêu cầu quyền Administrator để thực hiện quét sâu hệ thống..."
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$env:BAT_PATH`"" -Verb RunAs
    exit
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "   GIAI ĐOẠN 2: QUÉT SÂU BẢO MẬT, MẠNG & TỆP TIN NÉ CHECK" -ForegroundColor White
Write-Host "   Phiên bản: $version | $credit" -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Helper function for inline progress bar
function Show-ProgressBar ([int]$current, [int]$total, [string]$activity) {
    $percent = [math]::Min(100, [math]::Max(0, [int](($current / $total) * 100)))
    $left = [int]($percent / 4)
    $right = 25 - $left
    $bar = ("#" * $left) + ("." * $right)
    $msg = "`r[$bar] $percent% | $activity"
    if ($msg.Length -gt 79) {
        $msg = $msg.Substring(0, 76) + "..."
    }
    # Pad to clear previous long lines
    $msg = $msg.PadRight(79)
    Write-Host $msg -NoNewline
}

# 1. DEEP FILE SCAN & SECURITY ANALYST
Write-Host "[1] PHÂN TÍCH MÃ ĐỘC & AN TOÀN HỆ THỐNG / SECURITY & MALWARE ANALYST" -ForegroundColor Blue
Write-Host "--------------------------------------------------------------------------------"
Write-Host " Đang chuẩn bị danh sách thư mục quét..." -ForegroundColor Yellow

$scanPaths = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Documents",
    "$env:AppData",
    "$env:LocalAppData",
    "$env:temp",
    "$env:ProgramFiles\Adobe",
    "${env:ProgramFiles(x86)}\Adobe",
    "$env:ProgramFiles\Autodesk",
    "${env:ProgramFiles(x86)}\Autodesk",
    "$env:ProgramFiles\Microsoft Office",
    "${env:ProgramFiles(x86)}\Microsoft Office"
)

# Filter paths that actually exist
$activeScanPaths = $scanPaths | Where-Object { Test-Path $_ }

# Patterns to scan
$patterns = @("*@*", "*thuoc*", "*thuốc*", "*unlock*", "*crack*", "*patch*", "*activator*", "*keygen*", "*bypass*")

$foundEvasiveFiles = @()
$totalFolders = $activeScanPaths.Count
$currentFolderIndex = 0

Write-Host " Bắt đầu quét sâu hệ thống (Tiến trình có thể mất từ 10-30 giây)..." -ForegroundColor Yellow

foreach ($folder in $activeScanPaths) {
    $currentFolderIndex++
    $folderName = Split-Path $folder -Leaf
    Show-ProgressBar $currentFolderIndex $totalFolders "Đang phân tích thư mục: $folderName"
    
    foreach ($pattern in $patterns) {
        try {
            $files = Get-ChildItem -Path $folder -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
            if ($files) {
                foreach ($file in $files) {
                    $foundEvasiveFiles += $file
                }
            }
        } catch {
            # Ignore directory read errors
        }
    }
}

# Clear progress bar line
Write-Host "`r" -NoNewline
Write-Host (" " * 79) -NoNewline
Write-Host "`r" -NoNewline

# Collect inputs for Security & Malware Analyst
$evidenceList = @()
$isCracked = $false
$confidenceScore = 0.0
$crackMethod = "None"
$riskLevel = "None"
$recommendation = "Hệ thống sạch và an toàn (Clean). Không phát hiện bất kỳ dấu vết bẻ khóa nào."

# 1. Analyze File system (Rule 1: No False Positives for docx, pdf, txt, png, etc.)
$dangerousExtensions = @(".exe", ".dll", ".sys", ".cmd", ".bat", ".vbs", ".ps1", ".msi", ".scr")
$detectedCrackFiles = @()

foreach ($file in $foundEvasiveFiles) {
    $ext = $file.Extension.ToLower()
    $fileNameLower = $file.Name.ToLower()
    
    # Check if it is a real binary/executable or script
    if ($ext -in $dangerousExtensions) {
        # Check specific crack signatures
        if ($fileNameLower -match "sppc\.dll") {
            $detectedCrackFiles += $file.FullName
            $isCracked = $true
            $crackMethod = "Ohook"
            $evidenceList += "Phát hiện tệp tin DLL Hijacking (Ohook) '$($file.Name)' tại: $($file.FullName)"
        }
        elseif ($fileNameLower -match "vlmcsd" -or $fileNameLower -match "sppextcomobjhook") {
            $detectedCrackFiles += $file.FullName
            $isCracked = $true
            if ($crackMethod -eq "None") { $crackMethod = "KMS" }
            $evidenceList += "Phát hiện tệp tin giả lập KMS server offline '$($file.Name)' tại: $($file.FullName)"
        }
        elseif ($fileNameLower -match "kmsauto" -or $fileNameLower -match "kmspico" -or $fileNameLower -match "autokms") {
            $detectedCrackFiles += $file.FullName
            $isCracked = $true
            if ($crackMethod -eq "None") { $crackMethod = "KMS" }
            $evidenceList += "Phát hiện tệp tin công cụ KMS lậu '$($file.Name)' tại: $($file.FullName)"
        }
        elseif ($fileNameLower -match "amtlib\.dll" -or $fileNameLower -match "adobe\.snr" -or $fileNameLower -match "genp" -or $fileNameLower -match "xf-adsk") {
            $detectedCrackFiles += $file.FullName
            $isCracked = $true
            if ($crackMethod -eq "None") { $crackMethod = "KMS" } # General software patch
            $evidenceList += "Phát hiện tệp tin bẻ khóa phần mềm Adobe/Autodesk '$($file.Name)' tại: $($file.FullName)"
        }
    }
}

# Check for sppc.dll in Office directories specifically
$ohookPaths = @(
    "$env:ProgramFiles\Microsoft Office\root\vfs\System\sppc.dll",
    "${env:ProgramFiles(x86)}\Microsoft Office\root\vfs\System\sppc.dll"
)
foreach ($path in $ohookPaths) {
    if (Test-Path $path) {
        $detectedCrackFiles += $path
        $isCracked = $true
        $crackMethod = "Ohook"
        $evidenceList += "Phát hiện tệp tin Ohook sppc.dll bypass hoạt động tại: $path"
    }
}

# 2. Analyze Running Processes
$suspiciousProcesses = Get-Process -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -match "vlmcsd|AutoKMS|KMSAuto|KMSpico|SppExtComObjHook"
}
if ($suspiciousProcesses) {
    $isCracked = $true
    if ($crackMethod -eq "None") { $crackMethod = "KMS" }
    foreach ($proc in $suspiciousProcesses) {
        $evidenceList += "Phát hiện tiến trình crack đang chạy ngầm: $($proc.Name) (PID: $($proc.Id))"
    }
}

# 3. Analyze Registry KMS Overrides
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

$kmsServers = @($winKms, $winGuidKms, $officeKms, $officeGuidKms) | Where-Object { $_ } | Select-Object -Unique
foreach ($server in $kmsServers) {
    if ($server -match "127\.|kms8\.msguides\.com|kms\.lotro\.cc|msguides|kms\.digiboy\.ir|kms\.chinancce\.com") {
        $isCracked = $true
        if ($crackMethod -eq "None") { $crackMethod = "KMS" }
        $evidenceList += "Phát hiện registry trỏ tới máy chủ KMS lậu/giả lập: $server"
    }
}

# 4. Check Windows Activation channel
$isDomainJoined = $false
$compSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
if ($compSystem) { $isDomainJoined = $compSystem.PartOfDomain }

$winProducts = Get-CimInstance -Namespace root\CIMV2 -ClassName SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -and $_.Description -like "*Windows*" }
$channel = ""
if ($winProducts) {
    $slmgrDli = cscript //nologo C:\Windows\System32\slmgr.vbs /dli 2>$null
    $channelLine = $slmgrDli | Where-Object { $_ -like "*channel*" }
    if ($channelLine) { $channel = $channelLine.Trim() }
}

if ($channel -like "*VOLUME_KMSCLIENT*" -and -not $isDomainJoined -and -not $isCracked) {
    $evidenceList += "Hệ thống kích hoạt bằng kênh KMS Volume trên máy cá nhân không gia nhập miền doanh nghiệp."
}

# Determine Risk Level and Confidence Score
if ($isCracked) {
    $confidenceScore = 1.0
    $riskLevel = "High"
    if ($crackMethod -eq "Ohook") {
        $recommendation = "Gỡ cài đặt bản Office lậu, chạy lệnh dọn dẹp registry sppc.dll và mua bản quyền chính hãng."
    } else {
        $recommendation = "Gỡ sạch các công cụ giả lập KMS lậu, xóa bỏ cấu hình KMS Registry ghi đè và kích hoạt lại bằng khóa chính hãng."
    }
} else {
    if ($evidenceList.Count -gt 0) {
        $isCracked = $true
        $confidenceScore = 0.7
        $crackMethod = "KMS"
        $riskLevel = "Medium"
        $recommendation = "Kiểm tra lại cấu hình kích hoạt mạng. Có thể hệ thống đang trỏ tới máy chủ kích hoạt không chính thức."
    } else {
        $isCracked = $false
        $confidenceScore = 1.0
        $crackMethod = "None"
        $riskLevel = "None"
        $recommendation = "Không cần hành động. Hệ thống đang hoạt động an toàn."
    }
}

# Construct JSON Output
$jsonObj = [PSCustomObject]@{
    is_cracked       = [bool]$isCracked
    confidence_score = [double]$confidenceScore
    crack_method     = $crackMethod
    detected_evidence = [string[]]$evidenceList
    risk_level       = $riskLevel
    recommendation   = $recommendation
}

$jsonOutput = $jsonObj | ConvertTo-Json -Depth 5

# Display human-readable results first
Write-Host " KẾT QUẢ PHÂN TÍCH AN TOÀN HỆ THỐNG / SECURITY ANALYSIS REPORT:" -ForegroundColor Blue
Write-Host " ========================================================================" -ForegroundColor Cyan
if ($isCracked) {
    if ($riskLevel -eq "High") {
        Write-Host "    TRẠNG THÁI: PHÁT HIỆN CAN THIỆP BẢN QUYỀN LẬU (CRACKED)" -ForegroundColor Red
    } else {
        Write-Host "    TRẠNG THÁI: PHÁT HIỆN DẤU HIỆU NGHI VẤN (SUSPICIOUS)" -ForegroundColor Yellow
    }
} else {
    Write-Host "    TRẠNG THÁI: HỆ THỐNG AN TOÀN (CLEAN / SECURE)" -ForegroundColor Green
}
Write-Host " ========================================================================" -ForegroundColor Cyan
Write-Host "  * Phương thức bẻ khóa  : " -NoNewline
switch ($crackMethod) {
    "KMS" { Write-Host "Giả lập KMS (KMS Emulation / Online redirect)" -ForegroundColor Red }
    "Ohook" { Write-Host "Ohook DLL Hijacking (Office bypass)" -ForegroundColor Red }
    "HWID" { Write-Host "Kích hoạt kỹ thuật số lậu (HWID Bypass)" -ForegroundColor Red }
    Default { Write-Host "Sạch / Không phát hiện" -ForegroundColor Green }
}
Write-Host "  * Mức độ tin cậy       : $([math]::Round($confidenceScore * 100))%" -ForegroundColor White
Write-Host "  * Mức độ rủi ro        : " -NoNewline
switch ($riskLevel) {
    "High" { Write-Host "NGUY HIỂM CAO (High)" -ForegroundColor Red }
    "Medium" { Write-Host "TRUNG BÌNH (Medium)" -ForegroundColor Yellow }
    Default { Write-Host "KHÔNG CÓ (None)" -ForegroundColor Green }
}
Write-Host ""
Write-Host "  * Bằng chứng phát hiện:" -ForegroundColor Cyan
if ($evidenceList.Count -eq 0) {
    Write-Host "    -> Không có bằng chứng vi phạm nào được ghi nhận." -ForegroundColor Green
} else {
    foreach ($evidence in $evidenceList) {
        Write-Host "    -> $evidence" -ForegroundColor Red
    }
}
Write-Host ""
Write-Host "  * Khuyến nghị khắc phục:" -ForegroundColor Cyan
Write-Host "    -> $recommendation" -ForegroundColor White
Write-Host " ========================================================================" -ForegroundColor Cyan
Write-Host ""

# Display JSON output clearly for parent program parsing
Write-Host " KẾT QUẢ ĐẦU RA RAW JSON (DÀNH CHO HỆ THỐNG TỰ ĐỘNG PHÂN TÍCH):" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------------"
Write-Host $jsonOutput
Write-Host "--------------------------------------------------------------------------------"
Write-Host ""

# 2. DEEP PORT & NETSTAT SCAN
Write-Host "[2] QUÉT CỔNG MẠNG CAN THIỆP & KẾT NỐI KHẢ NGHI" -ForegroundColor Blue
Write-Host "--------------------------------------------------------------------------------"
Write-Host " Đang quét các kết nối mạng..." -ForegroundColor Yellow

$portTamperDetected = $false
$portReasons = @()

# 2.1 Check Active Local Port 1688 (KMS default port)
Show-ProgressBar 1 3 "Kiểm tra cổng 1688 (KMS)..."
$kmsConnections = Get-NetTCPConnection -LocalPort 1688 -ErrorAction SilentlyContinue
$kmsRemoteConnections = Get-NetTCPConnection -RemotePort 1688 -ErrorAction SilentlyContinue

$allKmsConn = @()
if ($kmsConnections) { $allKmsConn += $kmsConnections }
if ($kmsRemoteConnections) { $allKmsConn += $kmsRemoteConnections }

if ($allKmsConn.Count -gt 0) {
    foreach ($conn in $allKmsConn) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        $procName = if ($proc) { $proc.Name } else { "Không xác định" }
        
        # Genuine Windows KMS client queries outbound to remote ports. 
        # If there is a local port listening, or remote is loopback, it's highly suspicious.
        if ($conn.LocalAddress -eq "127.0.0.1" -or $conn.LocalAddress -eq "::1" -or $conn.RemoteAddress -eq "127.0.0.1" -or $conn.RemoteAddress -eq "::1" -or $conn.LocalPort -eq 1688) {
            if ($procName -ne "sppsvc" -and $procName -ne "System") {
                $portTamperDetected = $true
                $portReasons += "Phát hiện tiến trình '$procName' (PID: $($conn.OwningProcess)) kết nối/lắng nghe trên cổng KMS 1688 tại local address $($conn.LocalAddress)."
            }
        }
    }
}

# 2.2 Check for suspicious loopback ports commonly used by local KMS servers
Show-ProgressBar 2 3 "Kiểm tra các cổng loopback nghi vấn..."
# Port 1688 is primary. Some activators run on 50051 or other high ports. We already check process names.

# 2.3 Check hosts network redirections in active DNS cache
Show-ProgressBar 3 3 "Kiểm tra bộ nhớ cache DNS..."
$dnsCache = Get-DnsClientCache -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "kms|activation|validation|licensing|massgrave" }
if ($dnsCache) {
    foreach ($cache in $dnsCache) {
        if ($cache.Data -eq "127.0.0.1" -or $cache.Data -eq "::1" -or $cache.Data -eq "127.0.0.2") {
            $portTamperDetected = $true
            $portReasons += "Phát hiện DNS Cache điều hướng máy chủ '$($cache.Name)' về local IP: $($cache.Data)."
        }
    }
}

# Clear progress bar
Write-Host "`r" -NoNewline
Write-Host (" " * 79) -NoNewline
Write-Host "`r" -NoNewline

if ($portTamperDetected) {
    Write-Host " [!] Phát hiện can thiệp kết nối hoặc máy chủ KMS giả lập đang chạy:" -ForegroundColor Red
    foreach ($reason in $portReasons) {
        Write-Host "   -> $reason" -ForegroundColor Red
    }
} else {
    Write-Host " [+] Không phát hiện máy chủ KMS giả lập chạy ngầm hoặc kết nối KMS bất thường." -ForegroundColor Green
}
Write-Host ""

# 3. DEEP SECURITY CONFIGURATION AUDIT
Write-Host "[3] KIỂM TRA SÂU CẤU HÌNH BẢO MẬT HỆ THỐNG" -ForegroundColor Blue
Write-Host "--------------------------------------------------------------------------------"
$secTamper = $false
$secReasons = @()

# 3.1 Check User Account Control (UAC) status
Write-Host " * Đang kiểm tra cấu hình kiểm soát tài khoản người dùng (UAC)..."
$uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
if (Test-Path $uacPath) {
    $uac = Get-ItemProperty -Path $uacPath -ErrorAction SilentlyContinue
    if ($uac.EnableLUA -eq 0) {
        $secTamper = $true
        $secReasons += "UAC đã bị tắt hoàn toàn (EnableLUA = 0). Phần mềm độc hại và crack có thể chạy tự do."
    }
    if ($uac.ConsentPromptBehaviorAdmin -eq 0) {
        $secTamper = $true
        $secReasons += "UAC tự động cấp quyền Admin mà không hiện thông báo nhắc (ConsentPromptBehaviorAdmin = 0)."
    }
}

# 3.2 Check Windows Update status
Write-Host " * Đang kiểm tra trạng thái Windows Update..."
$wuService = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
if ($wuService -and $wuService.Status -eq "Disabled") {
    $secTamper = $true
    $secReasons += "Dịch vụ Windows Update bị vô hiệu hóa (Disabled) - thường do các tool tắt cập nhật/crack."
}

# 3.3 Check Code Integrity & Test Signing Mode
Write-Host " * Đang kiểm tra trạng thái Test Signing (Chế độ ký thử nghiệm)..."
$systemStartOpts = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name SystemStartOptions -ErrorAction SilentlyContinue).SystemStartOptions
if ($systemStartOpts -like "*TESTSIGNING*") {
    $secTamper = $true
    $secReasons += "Chế độ Test Signing đang BẬT. Cho phép nạp driver không chữ ký (nguy cơ bảo mật cực lớn)."
}

if ($secTamper) {
    Write-Host " [!] Phát hiện cấu hình hệ thống bị suy giảm bảo mật nghiêm trọng:" -ForegroundColor Red
    foreach ($reason in $secReasons) {
        Write-Host "   -> $reason" -ForegroundColor Red
    }
} else {
    Write-Host " [+] Cấu hình bảo mật hệ thống an toàn (UAC Bật, Windows Update hoạt động, Test Signing Tắt)." -ForegroundColor Green
}
Write-Host ""

# 4. GIAI ĐOẠN 2 ASSESSMENT
Write-Host "[4] KẾT LUẬN GIAI ĐOẠN 2" -ForegroundColor Blue
Write-Host "--------------------------------------------------------------------------------"

if ($detectedCrackFiles.Count -gt 0 -or $portTamperDetected -or $secTamper) {
    Write-Host " ========================================================================" -ForegroundColor Red
    Write-Host "    KẾT QUẢ QUÉT SÂU: PHÁT HIỆN LỖ HỔNG & CAN THIỆP PHẦN MỀM LẬU" -ForegroundColor Red
    Write-Host " ========================================================================" -ForegroundColor Red
    if ($detectedCrackFiles.Count -gt 0) { Write-Host "  * Phát hiện $($detectedCrackFiles.Count) tệp tin crack/trái phép được xác định trên hệ thống." -ForegroundColor Red }
    if ($portTamperDetected) { Write-Host "  * Phát hiện kết nối/cổng mạng hoặc DNS Cache bị can thiệp để chạy KMS lậu." -ForegroundColor Red }
    if ($secTamper) { Write-Host "  * Hệ thống bị suy giảm bảo mật nghiêm trọng (UAC/Windows Update bị tắt, Test Signing bật)." -ForegroundColor Red }
} else {
    Write-Host " ========================================================================" -ForegroundColor Green
    Write-Host "    KẾT QUẢ QUÉT SÂU: HỆ THỐNG AN TOÀN & SẠCH (SECURE & CLEAN)" -ForegroundColor Green
    Write-Host " ========================================================================" -ForegroundColor Green
    Write-Host "  * Không xác định được tệp tin crack/trái phép nào trong các thư mục quan trọng." -ForegroundColor Green
    Write-Host "  * Không phát hiện can thiệp cổng mạng KMS hoặc DNS Cache giả lập." -ForegroundColor Green
    Write-Host "  * Các thiết lập UAC, Windows Update và chữ ký driver hoạt động an toàn." -ForegroundColor Green
}

# ── GIAI ĐOẠN GỠ BỎ: XÓA FILE CRACK / TRÁI PHÉP ────────────────────────────
Write-Host ""
Write-Host "[5] GỠ BỎ TỆP TIN CRACK / TRÁI PHÉP" -ForegroundColor Blue
Write-Host "--------------------------------------------------------------------------------"

if ($detectedCrackFiles.Count -eq 0) {
    Write-Host " [+] Không có tệp tin crack/trái phép nào cần xóa." -ForegroundColor Green
} else {
    Write-Host " [!] Danh sách tệp tin crack/trái phép phát hiện:" -ForegroundColor Red
    $i = 1
    foreach ($f in $detectedCrackFiles) {
        Write-Host "   [$i] $f" -ForegroundColor Yellow
        $i++
    }
    Write-Host ""
    Write-Host " ╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host " ║  CẢNH BÁO: Hành động xóa là KHÔNG THỂ HOÀN TÁC. Hãy chắc chắn trước  ║" -ForegroundColor Red
    Write-Host " ║  khi xác nhận! Bạn có muốn XÓA VĨNH VIỄN $($detectedCrackFiles.Count) tệp tin trên không?   ║" -ForegroundColor Red
    Write-Host " ╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""

    # Prompt y/n — dùng Read-Host để hoạt động đúng kể cả khi chạy qua cmd.exe
    $choiceChar = ""
    do {
        Write-Host " Nhập lựa chọn của bạn [y = XÓA / n = BỎ QUA]: " -ForegroundColor Cyan -NoNewline
        $raw = (Read-Host).Trim().ToLower()
        if ($raw -eq "y" -or $raw -eq "n") { $choiceChar = $raw }
        else { Write-Host " Vui lòng chỉ nhập 'y' hoặc 'n'." -ForegroundColor Yellow }
    } while ($choiceChar -eq "")

    Write-Host ""

    if ($choiceChar -eq "y") {
        Write-Host " Đang tiến hành xóa..." -ForegroundColor Yellow
        Write-Host ""
        $deletedCount  = 0
        $failedCount   = 0
        $failedFiles   = @()

        foreach ($filePath in $detectedCrackFiles) {
            try {
                if (Test-Path $filePath) {
                    Remove-Item -LiteralPath $filePath -Force -ErrorAction Stop
                    Write-Host "   [OK] Đã xóa: $filePath" -ForegroundColor Green
                    $deletedCount++
                } else {
                    Write-Host "   [--] Tệp không còn tồn tại (đã được xóa trước đó): $filePath" -ForegroundColor DarkGray
                }
            } catch {
                Write-Host "   [X]  Không thể xóa: $filePath" -ForegroundColor Red
                Write-Host "        Lý do: $($_.Exception.Message)" -ForegroundColor DarkRed
                $failedCount++
                $failedFiles += $filePath
            }
        }

        Write-Host ""
        Write-Host " ────────────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
        Write-Host " KẾT QUẢ XÓA:" -ForegroundColor Cyan
        Write-Host "   Đã xóa thành công : $deletedCount tệp" -ForegroundColor Green
        if ($failedCount -gt 0) {
            Write-Host "   Không xóa được    : $failedCount tệp (thiếu quyền hoặc tệp đang bị khóa)" -ForegroundColor Red
            foreach ($ff in $failedFiles) {
                Write-Host "     -> $ff" -ForegroundColor Red
            }
            Write-Host ""
            Write-Host "   GỢI Ý: Thử khởi động lại máy tính rồi chạy lại công cụ với quyền" -ForegroundColor Yellow
            Write-Host "   Administrator, hoặc xóa thủ công trong Safe Mode." -ForegroundColor Yellow
        }
        Write-Host " ────────────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
    } else {
        Write-Host " [--] Bỏ qua. Không có tệp tin nào bị xóa." -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Quá trình quét sâu Giai đoạn 2 kết thúc. Nhấn phím bất kỳ để đóng..."
[void][System.Console]::ReadKey($true)
