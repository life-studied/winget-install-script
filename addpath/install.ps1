# 检查是否已安装
$toolsPath = "$env:USERPROFILE\Tools"
$addPathScript = Join-Path $toolsPath "install-AddToPath.ps1"
if (Test-Path $addPathScript) {
    Write-Host "AddToPath 模块已安装，跳过安装。" -ForegroundColor Yellow
    exit $global:exitSuccess
}

# 将当前目录下的其它文件copy到`%USERPROFILE%\Tools`下
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$targetDir = "$env:USERPROFILE\Tools"
if (-Not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}
Get-ChildItem -Path $scriptDir -File | ForEach-Object {
    $sourceFile = $_.FullName
    $destFile = Join-Path $targetDir $_.Name
    Copy-Item -Path $sourceFile -Destination $destFile -Force
}

Write-Host "已将脚本文件复制到 $targetDir"

# 执行%USERPROFILE%\Tools\install-AddToPath.ps1脚本
$addPathScript = Join-Path $targetDir "install-AddToPath.ps1"
if (Test-Path $addPathScript) {
    Write-Host "正在执行添加路径脚本..."
    & $addPathScript
    if ($LASTEXITCODE -ne 0) {
        Write-Host "添加路径脚本执行失败，退出代码：$LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    } else {
        Write-Host "添加路径脚本执行成功。" -ForegroundColor Green
    }
} else {
    Write-Host "未找到添加路径脚本：$addPathScript" -ForegroundColor Red
    exit $global:exitInstallButNotFound
}

# done
exit $global:exitSuccess