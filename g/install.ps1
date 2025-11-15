# 检查是否已安装
$toolsPath = Join-Path $global:customToolsPath "g"
$gExePath = Join-Path $toolsPath "g.exe"
if (Test-Path $gExePath) {
    Write-Host "g 模块已安装，跳过安装。" -ForegroundColor Yellow
    exit $global:exitSuccess
}

# 获取最新版本的 g 的tag（https://github.com/voidint/g/releases/download/v1.8.0/g1.8.0.windows-amd64.zip）
$latestTag = (Invoke-RestMethod https://api.github.com/repos/voidint/g/releases/latest).tag_name
$tagVersion = $latestTag.TrimStart("v")

# 下载 g 压缩包
$downloadUrl = "https://github.com/voidint/g/releases/download/$latestTag/g$tagVersion.windows-amd64.zip"
$zipFilePath = Join-Path $env:TEMP "g$tagVersion.windows-amd64.zip"

# 下载文件，检查是否成功
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath
if (-not (Test-Path $zipFilePath)) {
    Write-Host "下载 g 失败，请检查链接是否正确： $downloadUrl" -ForegroundColor Red
    exit $global:exitInstallFail
}

# 创建安装目录
if (-Not (Test-Path $toolsPath)) {
    New-Item -ItemType Directory -Path $toolsPath -Force | Out-Null
}
# 解压文件到安装目录
Expand-Archive -Path $zipFilePath -DestinationPath $toolsPath -Force
Write-Host "已将 g 解压到 $toolsPath"
if (-Not (Test-Path $gExePath)) {
    Write-Host "g 可执行文件未找到，安装失败。" -ForegroundColor Red
    exit $global:exitInstallButNotFound
}

# 删除临时下载的zip文件
Remove-Item -Path $zipFilePath -Force

# 将 g 添加到 PATH 环境变量
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$toolsPath*") {
    $newPath = $currentPath + ";" + $toolsPath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 g 添加到 PATH 环境变量。"
} else {
    Write-Host "g 已在 PATH 环境变量中。"
}

# done
exit $global:exitSuccess