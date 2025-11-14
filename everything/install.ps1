# 安装 Everything
$package = winget list --id "voidtools.Everything" | Select-String "voidtools.Everything"
if ($package) {
    Write-Host "Everything 已安装。"
    $everythingInstalled = $true
} else {
    Write-Host "正在安装 Everything..."
    winget install --id "voidtools.Everything" --silent
    Write-Host "Everything 安装完成。"
}

# 设置 Everything 开机自启动
$everythingPath = "$env:ProgramFiles\Everything\Everything.exe"
if (Test-Path $everythingPath) {
    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = Join-Path $startupFolder "Everything.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $everythingPath
    $shortcut.Save()
    Write-Host "已设置 Everything 开机自启动。"
} else {
    Write-Host "未找到 Everything 可执行文件，无法设置开机自启动。"
}

# 启动 Everything 应用程序
if(-Not $everythingInstalled) {
    Start-Process $everythingPath
}
Write-Host "Everything 已启动。"

# 安装 everything sdk
Write-Host "正在安装 Everything SDK..."
$everythingSdkUrl = "https://www.voidtools.com/Everything-SDK.zip"
$sdkZipPath = "$env:TEMP\Everything-SDK.zip"

$sdkFilePath = "$global:customToolsPath\Everything-SDK\dll\Everything64.dll"
$sdkExtractPath = $global:customToolsPath + "\Everything-SDK"
# 如果不存在 SDK，则执行
if ( -Not (Test-Path $sdkFilePath)) {
    # 下载 Everything SDK 压缩包
    Invoke-WebRequest -Uri $everythingSdkUrl -OutFile $sdkZipPath

    # 解压 Everything SDK 到指定目录
    if (Test-Path $sdkExtractPath) {
        Remove-Item -Recurse -Force $sdkExtractPath
    }
    Expand-Archive -Path $sdkZipPath -DestinationPath $sdkExtractPath
    if (-Not (Test-Path $sdkExtractPath)) {
        Write-Host "Everything SDK 解压失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
}
Write-Host "Everything SDK 安装完成，路径：$sdkExtractPath"

# 设置环境变量 EVERYTHING_SDK_PATH=path\to\Everything-SDK\dll\Everything64.dll
[System.Environment]::SetEnvironmentVariable("EVERYTHING_SDK_PATH", "$sdkExtractPath\dll\Everything64.dll", [System.EnvironmentVariableTarget]::User)
# 检查安装是否成功
if ($LASTEXITCODE -eq 0) {
    Write-Host "Everything SDK 环境变量设置完成。"
} else {
    Write-Host "Everything SDK 安装失败，退出代码：$global:exitEnvValConfigFail"
    exit $global:exitEnvValConfigFail
}

# done
exit $global:exitSuccess
