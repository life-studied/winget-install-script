# 获取github token（如果有的话），从参数传递
param(
    [string]$githubToken
)

# 检查是否已安装
$inputTipInstallPath = Join-Path $global:customToolsPath "InputTip"
$inputTipExePath = Join-Path $inputTipInstallPath "InputTip-main\InputTip.bat"
if (Test-Path $inputTipExePath) {
    Write-Host "InputTip 已安装，跳过安装。" -ForegroundColor Yellow
    exit $global:exitSuccess
}

# 获取最新版本的InputTip的tag
$latestTag = (Invoke-RestMethod https://api.github.com/repos/abgox/InputTip/releases/latest).tag_name

# 下载最新版本的InputTip（eg. https://github.com/abgox/InputTip/releases/download/v2025.10.09/InputTip.zip）
$downloadUrl = "https://github.com/abgox/InputTip/releases/download/$latestTag/InputTip.zip"
$zipFilePath = "$env:TEMP\InputTip.zip"

# 下载文件，检查是否成功（使用token以避免限流）
if ($githubToken) {
    $headers = @{
        Authorization = "token $token"
        "User-Agent"  = "PowerShell"
    }
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath -Headers $headers
} else {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath
}
# 检查文件是否下载成功
if (-not (Test-Path $zipFilePath)) {
    Write-Host "下载 InputTip 失败，请检查链接是否正确： $downloadUrl" -ForegroundColor Red
    exit $global:exitInstallFail
}

# 创建安装目录
if (-Not (Test-Path $inputTipInstallPath)) {
    New-Item -ItemType Directory -Path $inputTipInstallPath -Force | Out-Null
}
# 解压文件到安装目录
Expand-Archive -Path $zipFilePath -DestinationPath $inputTipInstallPath -Force
Write-Host "已将 InputTip 解压到 $inputTipInstallPath"
# 删除临时下载的zip文件
Remove-Item -Path $zipFilePath -Force

# 执行bat文件进行安装（不阻塞等待）
Start-Process -FilePath $inputTipExePath -ArgumentList "/S" -NoNewWindow

# 给出提示（需要自行配置开机自启、其它设置）
Write-Host "InputTip 安装完成。请根据需要自行配置开机自启等设置。" -ForegroundColor Yellow

# done
exit $global:exitSuccess
