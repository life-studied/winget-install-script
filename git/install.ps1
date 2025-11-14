# 安装 Git
$package = winget list --id "Git.Git" | Select-String "Git.Git"
if ($package) {
    Write-Host "Git 已安装。"
} else {
    Write-Host "正在安装 Git..."
    winget install --id "Git.Git" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Git 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "Git 安装完成。"
}

# 将 Git 添加到 PATH 环境变量
$gitPath = "$env:ProgramFiles\Git\bin"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
if ($currentPath -notlike "*$gitPath*") {
    $newPath = $currentPath + ";" + $gitPath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 Git 添加到 PATH 环境变量。"
} else {
    Write-Host "Git 已在 PATH 环境变量中。"
}

# done
exit $global:exitSuccess
