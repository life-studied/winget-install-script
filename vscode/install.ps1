# https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user
$vsCodeInstallerUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"
$vsCodeInstallerPath = $env:TEMP

# 检查是否已安装 VSCode（User包默认安装地址：%LOCALAPPDATA%\Programs\Microsoft VS Code\）
$vsCodePath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"
$vsCodeExePath = Join-Path $vsCodePath "Code.exe"
if (Test-Path $vsCodeExePath) {
    Write-Host "VSCode 已安装，跳过安装。" -ForegroundColor Yellow
    exit $global:exitSuccess
}

# 下载 VSCode 安装程序（到指定路径）
Write-Host "正在下载 VSCode 安装程序..."
Invoke-WebRequest -Uri $vsCodeInstallerUrl -OutFile $vsCodeInstallerPath

# 检查文件是否下载成功（模式匹配 exe: VSCodeUserSetup-x64-版本号.exe）
$exe = Get-ChildItem -Path $vsCodeInstallerPath -Filter "VSCodeUserSetup-x64-*.exe" |
       Select-Object -ExpandProperty FullName -First 1

if (-not (Test-Path $exe)) {
    Write-Host "下载 VSCode 失败，请检查链接是否正确： $vsCodeInstallerUrl" -ForegroundColor Red
    exit $global:exitInstallFail
}

# 执行安装程序（正常运行，等待用户自行安装完成）
Write-Host "正在安装 VSCode..."
Start-Process -FilePath $exe -ArgumentList "/VERYSILENT", "/NORESTART" -NoNewWindow -Wait

# 检查安装是否成功
if (-not (Test-Path $vsCodeExePath)) {
    Write-Host "VSCode 安装失败，未找到可执行文件。" -Foreground Red
    exit $global:exitInstallButNotFound
}

Write-Host "VSCode 安装成功，路径： $vsCodeExePath" -ForegroundColor Green

# done
exit $global:exitSuccess