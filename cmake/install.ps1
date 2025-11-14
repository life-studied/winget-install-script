# 安装 CMake
$package = winget list --id "Kitware.CMake" | Select-String "Kitware.CMake"
if ($package) {
    Write-Host "CMake 已安装。"
} else {
    Write-Host "正在安装 CMake..."
    winget install --id "Kitware.CMake" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "CMake 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "CMake 安装完成。"
}

# 将 CMake 添加到 PATH 环境变量
$cmakePath = "$env:ProgramFiles\CMake\bin"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$cmakePath*") {
    $newPath = $currentPath + ";" + $cmakePath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 CMake 添加到 PATH 环境变量。"
} else {
    Write-Host "CMake 已在 PATH 环境变量中。"
}

# done
exit $global:exitSuccess
