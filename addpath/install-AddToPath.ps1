<#
.SYNOPSIS
    双击即可把「将当前路径添加到环境变量 Path」加入 Win11 右键菜单
#>

# 如果已经在管理员上下文，直接干活；否则自提权
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # 重新用管理员启动当前脚本
    Start-Process powershell.exe -ArgumentList "-NoExit","-File",$PSCommandPath -Verb RunAs
    exit
}

# ── 正式安装逻辑（已在管理员权限下） ──
$toolsDir = "$env:USERPROFILE\Tools"
if (-not (Test-Path $toolsDir)) { New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null }
$scriptPath = Join-Path $toolsDir "AddPath.ps1"

# 释放真正的功能脚本
@'
param([string]$folderPath)
Add-Type -AssemblyName System.Windows.Forms
try {
    $usrPath = [Environment]::GetEnvironmentVariable('Path','User')
    if ($usrPath -split ';' -contains $folderPath) {
        [System.Windows.Forms.MessageBox]::Show("Path has exists!", "Tips", "OK", "Information")
        return
    }
    [Environment]::SetEnvironmentVariable('Path', "$usrPath;$folderPath", 'User")
    [System.Windows.Forms.MessageBox]::Show("Path successfully added: `n$folderPath", "Success", "OK", "Information")
} catch {
    [System.Windows.Forms.MessageBox]::Show("Error:$_", "Error", "OK", "Error")
}
'@ | Out-File -FilePath $scriptPath -Encoding UTF8 -Force

# 写注册表
$menuText = "将当前路径添加到环境变量 Path"
$icon = "imageres.dll,77"

foreach ($root in @("Directory\Background\shell", "Directory\shell")) {
    $regPath = "Registry::HKEY_CLASSES_ROOT\$root\AddToPath"
    New-Item -Path $regPath -Force | Out-Null
    Set-ItemProperty -Path $regPath -Name "(Default)" -Value $menuText
    Set-ItemProperty -Path $regPath -Name "Icon" -Value $icon
    $cmdPath = "$regPath\command"
    New-Item -Path $cmdPath -Force | Out-Null
    $arg = if ($root -like "*Background*") { "%V" } else { "%1" }
    Set-ItemProperty -Path $cmdPath -Name "(Default)" `
        -Value "powershell.exe -NoLogo -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -folderPath `"$arg`""
}

Write-Host "Successfully finish!" -ForegroundColor Green

exit 0