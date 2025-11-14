# 安装 Steam
$package = winget list --id "Valve.Steam" | Select-String "Valve.Steam"
if ($package) {
    Write-Host "Steam 已安装。"
} else {
    Write-Host "正在安装 Steam..."
    winget install --id "Valve.Steam" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Steam 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "Steam 安装完成。"
}

# 将 Steam 添加到 PATH 环境变量
$steamPath = "$env:ProgramFiles (x86)\Steam"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$steamPath*") {
    $newPath = $currentPath + ";" + $steamPath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 Steam 添加到 PATH 环境变量。"
} else {
    Write-Host "Steam 已在 PATH 环境变量中。"
}

# done
exit $global:exitSuccess
