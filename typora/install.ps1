# 安装 Typora
$package = winget list --id "appmakes.Typora" | Select-String "appmakes.Typora"
if ($package) {
    Write-Host "Typora 已安装。"
} else {
    Write-Host "正在安装 Typora..."
    winget install --id "appmakes.Typora" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Typora 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "Typora 安装完成。"
}

# 将 Typora 添加到 PATH 环境变量
$typoraPath = "$env:ProgramFiles\Typora"
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)

if (!(Test-Path "$typoraPath\Typora.exe")) {
    Write-Host "Typora 可执行文件未找到，退出代码：$global:exitInstallButNotFound"
    exit $global:exitInstallButNotFound
}
if ($currentPath -notlike "*$typoraPath*") {
    $newPath = $currentPath + ";" + $typoraPath
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::User)
    Write-Host "已将 Typora 添加到 PATH 环境变量。"
} else {
    Write-Host "Typora 已在 PATH 环境变量中。"
}

# 安装 REG 文件以关联 Markdown 文件
if (!(Test-Path "$scriptDir/Typora.reg")) {
    Write-Host "未找到 Typora.reg 文件，无法设置文件关联。"
    exit $global:exitInstallButNotFound
}
if (!(Test-Path "$typoraPath\Typora.exe")) {
    Write-Host "Typora 可执行文件未找到，退出代码：$global:exitInstallButNotFound"
    exit $global:exitInstallButNotFound
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
regedit.exe /s "$scriptDir/Typora.reg"

# done
exit $global:exitSuccess
