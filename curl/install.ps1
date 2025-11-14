# 安装 curl
$package = winget list --id "curl.curl" | Select-String "curl.curl"
if ($package) {
    Write-Host "curl 已安装。"
} else {
    Write-Host "正在安装 curl..."
    winget install --id "curl.curl" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "curl 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "curl 安装完成。"
}

# 将 curl 添加到 PATH 环境变量
$curlPath = "$env:ProgramFiles\curl"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$curlPath*") {
    $newPath = $currentPath + ";" + $curlPath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 curl 添加到 PATH 环境变量。"
} else {
    Write-Host "curl 已在 PATH 环境变量中。"
}

# done
exit $global:exitSuccess
