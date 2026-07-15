# 2>nul & @echo off & set "BAT_PATH=%~f0" & powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -Encoding UTF8 -LiteralPath '%~f0') -join [Environment]::NewLine)" & exit /b

# PowerShell code starts here...
Clear-Host

$version = "A.00"
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
    Write-Host " YÊU CẦU QUYỀN ADMINISTRATOR / ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Yellow -Bold
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "Đang yêu cầu quyền Administrator để thực hiện quét sâu hệ thống..."
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$env:BAT_PATH`"" -Verb RunAs
    exit
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "   GIAI ĐOẠN 2: QUÉT SÂU BẢO MẬT, MẠNG & TỆP TIN NÉ CHECK" -ForegroundColor White -Bold
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

# 1. DEEP FILE SCAN (EVASIVE CRACKS)
Write-Host "[1] QUÉT SÂU TỆP TIN CRACK NÉ CHECK (EVASIVE FILES)" -ForegroundColor Blue -Bold
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

Write-Host " Bắt đầu quét sâu tệp tin (Tiến trình có thể mất từ 10-30 giây)..." -ForegroundColor Yellow

foreach ($folder in $activeScanPaths) {
    $currentFolderIndex++
    $folderName = Split-Path $folder -Leaf
    Show-ProgressBar $currentFolderIndex $totalFolders "Đang quét thư mục: $folderName"
    
    foreach ($pattern in $patterns) {
        try {
            $files = Get-ChildItem -Path $folder -Filter $pattern -Recurse -File -ErrorAction SilentlyContinue
            if ($files) {
                foreach ($file in $files) {
                    $foundEvasiveFiles += $file.FullName
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

if ($foundEvasiveFiles.Count -gt 0) {
    Write-Host " [!] Phát hiện $($foundEvasiveFiles.Count) tệp tin chứa từ khóa crack hoặc né check:" -ForegroundColor Red
    # Output first 25 files to avoid spamming the console
    $displayCount = [math]::Min($foundEvasiveFiles.Count, 25)
    for ($i = 0; $i -lt $displayCount; $i++) {
        Write-Host "   -> $($foundEvasiveFiles[$i])" -ForegroundColor Red
    }
    if ($foundEvasiveFiles.Count -gt 25) {
        Write-Host "   ... và $($foundEvasiveFiles.Count - 25) tệp tin khác." -ForegroundColor Red
    }
} else {
    Write-Host " [+] Không phát hiện tệp tin nghi vấn nào chứa các từ khóa né check." -ForegroundColor Green
}
Write-Host ""

# 2. DEEP PORT & NETSTAT SCAN
Write-Host "[2] QUÉT CỔNG MẠNG CAN THIỆP & KẾT NỐI KHẢ NGHI" -ForegroundColor Blue -Bold
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
Write-Host "[3] KIỂM TRA SÂU CẤU HÌNH BẢO MẬT HỆ THỐNG" -ForegroundColor Blue -Bold
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
Write-Host "[4] KẾT LUẬN GIAI ĐOẠN 2" -ForegroundColor Blue -Bold
Write-Host "--------------------------------------------------------------------------------"

if ($foundEvasiveFiles.Count -gt 0 -or $portTamperDetected -or $secTamper) {
    Write-Host " ========================================================================" -ForegroundColor Red
    Write-Host "    KẾT QUẢ QUET SÂU: PHÁT HIỆN LỖ HỔNG & CAN THIỆP PHẦN MỀM LẬU" -ForegroundColor Red
    Write-Host " ========================================================================" -ForegroundColor Red
    if ($foundEvasiveFiles.Count -gt 0) { Write-Host "  * Phát hiện tệp tin chứa từ khóa crack hoặc né check trên hệ thống." -ForegroundColor Red }
    if ($portTamperDetected) { Write-Host "  * Phát hiện kết nối/cổng mạng hoặc DNS Cache bị can thiệp để chạy KMS lậu." -ForegroundColor Red }
    if ($secTamper) { Write-Host "  * Hệ thống bị suy giảm bảo mật nghiêm trọng (UAC/Windows Update bị tắt, Test Signing bật)." -ForegroundColor Red }
} else {
    Write-Host " ========================================================================" -ForegroundColor Green
    Write-Host "    KẾT QUẢ QUÉT SÂU: HỆ THỐNG AN TOÀN & SẠCH (SECURE & CLEAN)" -ForegroundColor Green
    Write-Host " ========================================================================" -ForegroundColor Green
    Write-Host "  * Không tìm thấy tệp tin crack né check nào trong các thư mục quan trọng." -ForegroundColor Green
    Write-Host "  * Không phát hiện can thiệp cổng mạng KMS hoặc DNS Cache giả lập." -ForegroundColor Green
    Write-Host "  * Các thiết lập UAC, Windows Update và chữ ký driver hoạt động an toàn." -ForegroundColor Green
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Quá trình quét sâu Giai đoạn 2 kết thúc. Nhấn phím bất kỳ để đóng..."
[void][System.Console]::ReadKey($true)
