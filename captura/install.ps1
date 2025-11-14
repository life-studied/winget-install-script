# 安装 Captura
$package = winget list --id "Captura.Captura" | Select-String "Captura.Captura"
if ($package) {
    Write-Host "Captura 已安装。"
} else {
    Write-Host "正在安装 Captura..."
    winget install --id "Captura.Captura" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Captura 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "Captura 安装完成。"
}

# 将 Captura 添加到 PATH 环境变量
$capturaPath = "${env:ProgramFiles(x86)}\Captura"
if (-Not (Test-Path $capturaPath)) {
    Write-Host "未找到 Captura 安装路径，退出代码：$global:exitInstallButNotFound"
    exit $global:exitInstallButNotFound
}
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$capturaPath*") {
    $newPath = $currentPath + ";" + $capturaPath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 Captura 添加到 PATH 环境变量。"
} else {
    Write-Host "Captura 已在 PATH 环境变量中。"
}

# done
exit $global:exitSuccess
