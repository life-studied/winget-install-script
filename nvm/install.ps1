# 安装 nvm(windows)
$package = winget list --id "CoreyButler.NVMforWindows" | Select-String "CoreyButler.NVMforWindows"
if ($package) {
    Write-Host "nvm 已安装。"
} else {
    Write-Host "正在安装 nvm..."
    winget install --id "CoreyButler.NVMforWindows" --silent
    # 检查安装是否成功
    if ($LASTEXITCODE -ne 0) {
        Write-Host "nvm 安装失败，退出代码：$global:exitInstallFail"
        exit $global:exitInstallFail
    }
    Write-Host "nvm 安装完成。"
}

# done
exit $global:exitSuccess