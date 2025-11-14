# 安装 Snipaste
$package = winget list --id "liule.Snipaste" | Select-String "liule.Snipaste"
if ($package) {
    Write-Host "Snipaste 已安装。"
    $snipasteInstalled = $true
} else {
    Write-Host "正在安装 Snipaste..."
    winget install --id "liule.Snipaste" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Snipaste 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "Snipaste 安装完成。"
}

# 设置 Snipaste 开机自启动
$snipastePath = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\liule.Snipaste_Microsoft.Winget.Source_8wekyb3d8bbwe\Snipaste.exe"
if (Test-Path $snipastePath) {
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = Join-Path $startupFolder "Snipaste.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $snipastePath
    $shortcut.Save()
    Write-Host "已设置 Snipaste 开机自启动。"
} else {
    Write-Host "未找到 Snipaste 可执行文件，无法设置开机自启动。"
    exit $global:exitInstallButNotFound
}

# 启动 Snipaste 应用程序（仅在新安装时启动）
if (-Not $snipasteInstalled) {
    Start-Process $snipastePath
}
Write-Host "Snipaste 已启动。"

# 将 Snipaste 添加到 PATH 环境变量
$snipasteDir = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\liule.Snipaste_Microsoft.Winget.Source_8wekyb3d8bbwe"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$snipasteDir*") {
    $newPath = $currentPath + ";" + $snipasteDir
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 Snipaste 添加到 PATH 环境变量。"
} else {
    Write-Host "Snipaste 已在 PATH 环境变量中。"
}

# done
exit $global:exitSuccess
