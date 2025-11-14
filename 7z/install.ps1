# 安装 7-Zip
$package = winget list --id "7zip.7zip" | Select-String "7zip.7zip"
if ($package) {
    Write-Host "7-Zip 已安装。"
} else {
    Write-Host "正在安装 7-Zip..."
    winget install --id "7zip.7zip" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "7-Zip 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "7-Zip 安装完成。"
}

# 将 7-Zip 添加到 PATH 环境变量
$sevenZipPath = "$env:ProgramFiles\7-Zip"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$sevenZipPath*") {
    $newPath = $currentPath + ";" + $sevenZipPath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 7-Zip 添加到 PATH 环境变量。"
} else {
    Write-Host "7-Zip 已在 PATH 环境变量中。"
}

# done
exit $global:exitSuccess
