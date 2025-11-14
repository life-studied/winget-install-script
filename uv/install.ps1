# 安装 uv
$package = winget list --id "astral-sh.uv" | Select-String "astral-sh.uv"
if ($package) {
    Write-Host "uv 已安装。"
} else {
    Write-Host "正在安装 uv..."
    winget install --id "astral-sh.uv" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "uv 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "uv 安装完成。"
}

# 将 uv 添加到 PATH 环境变量
$uvPath = "$env:USERPROFILE\.cargo\bin"  # uv 通常安装在 cargo 目录下
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$uvPath*") {
    $newPath = $currentPath + ";" + $uvPath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 uv 添加到 PATH 环境变量。"
} else {
    Write-Host "uv 已在 PATH 环境变量中。"
}

# done
exit $global:exitSuccess
