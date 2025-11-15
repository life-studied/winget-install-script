# 全局脚本，负责安装所有目录下的模块（创建缓存，每次从上次缓存开始安装）

# 0. 定义模块列表
$modules = @(
    "7z",
    "curl",
    "uv",
    "everything",
    "git",
    "snipaste",
    "typora",
    "steam",
    "cmake",
    "inputtip",
    "captura",
    "nvm",
    "addpath",
    "g",
    "vscode"
)

$global:exitSuccess            = 0
$global:exitInstallFail        = 1
$global:exitInstallButNotFound = 2
$global:exitEnvValConfigFail   = 3

$global:customToolsPath = "$env:USERPROFILE\CustomTools"
if (Test-Path $customToolsPath) {
    New-Item -ItemType Directory -Path $customToolsPath -Force | Out-Null
}

# 管理员权限
if (-not ([Security.Principal.WindowsPrincipal]`
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "当前脚本未以管理员权限运行，正在以管理员权限重新启动脚本..."
    Start-Process pwsh -ArgumentList "-NoExit","-File",$PSCommandPath `
                 -Verb RunAs -Wait
    exit
}

Write-Host "脚本以管理员权限运行，执行安装流程..."

# 1. 获取当前脚本所在目录
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# 获取github token（如果有的话），以避免API限流(从文件github.token)
$tokenFile = Join-Path $scriptDir "github.token"
if (-Not (Test-Path $tokenFile)) {
    Write-Host "未找到 github.token 文件，继续无token模式，可能导致限流。" -ForegroundColor Yellow
    Write-Host "如果遇到下载失败，请在脚本目录下创建 github.token 文件" -ForegroundColor Yellow
    Write-Host "获取路径：https://github.com/settings/personal-access-tokens" -ForegroundColor Yellow
} else {
    $githubToken = Get-Content -Path $tokenFile -Raw
    Write-Host "已读取 github token 文件，使用 token 模式下载以避免限流。" -ForegroundColor Green
    Write-Host "$githubToken" -ForegroundColor DarkGray
}

# 2. 创建缓存文件
$cacheFile = Join-Path $scriptDir "install_cache.txt"
if (-Not (Test-Path $cacheFile)) {
    New-Item -ItemType File -Path $cacheFile -Force | Out-Null
}

# 3. 读取已安装模块列表
$installedModules = Get-Content $cacheFile

# 4. 并行安装未安装的模块
$jobs = @()
$modulesToInstall = @()
$modulesInstalled = @()
$modulesFailed = @()

Write-Host "正在检查需要安装的模块..."
foreach ($module in $modules) {
    if ($installedModules -notcontains $module) {
        $moduleScript = Join-Path $scriptDir $module "install.ps1"
        if (Test-Path $moduleScript) {
            $modulesToInstall += $module
            Write-Host "准备并行安装模块：$module"
        } else {
            Write-Host "未找到模块脚本：$moduleScript，跳过安装。"
        }
    } else {
        Write-Host "模块 $module 已安装，跳过。"
    }
}

if ($modulesToInstall.Count -eq 0) {
    Write-Host "所有模块均已安装，无需执行安装。"
    exit $global:exitSuccess
}

Write-Host "开始并行安装 $($modulesToInstall.Count) 个模块..."

# 启动并行作业
foreach ($module in $modulesToInstall) {
    $moduleScript = Join-Path $scriptDir $module "install.ps1"
    
    # 创建更健壮的脚本块，确保能捕获所有错误
    $jobScript = {
        param($scriptPath, $moduleName, $githubToken)
        try {
            # 在作业中重新定义全局变量，因为作业是独立的进程
            $exitSuccess            = 0
            $exitInstallFail        = 1
            $exitInstallButNotFound = 2
            $exitEnvValConfigFail   = 3
            
            $customToolsPath = "$env:USERPROFILE\CustomTools"

            # unuse 语法去除报错
            $null = $exitSuccess
            $null = $exitInstallFail
            $null = $exitInstallButNotFound
            $null = $exitEnvValConfigFail
            $null = $customToolsPath
            
            # 执行安装脚本，传递参数
            # @1 = $githubToken
            & $scriptPath -githubToken $githubToken
            
            # 捕获退出代码
            $exitCode = $LASTEXITCODE
            
            # 返回结果
            return @{
                Module = $moduleName
                ExitCode = $exitCode
                Success = ($exitCode -eq 0)
                Error = $null
            }
        }
        catch {
            # 捕获任何异常
            return @{
                Module = $moduleName
                ExitCode = 1
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    $job = Start-Job -ScriptBlock $jobScript -ArgumentList $moduleScript, $module, $githubToken
    
    $jobs += @{
        Job = $job
        Module = $module
        Script = $moduleScript
    }
    Write-Host "已启动模块 $module 的安装作业"
}

# 等待所有作业完成并收集结果
Write-Host "等待所有安装作业完成..."
$results = @()
foreach ($jobInfo in $jobs) {
    try {
        $job = $jobInfo.Job
        $result = Wait-Job $job | Receive-Job
        $results += $result
        
        # 检查是否有错误信息
        if ($result.Error) {
            Write-Host "✗ 模块 $($jobInfo.Module) 执行出错: $($result.Error)" -ForegroundColor Red
        }
        else {
            Write-Host "✓ 模块 $($jobInfo.Module) 作业完成，退出代码：$($result.ExitCode)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "✗ 模块 $($jobInfo.Module) 作业处理出错: $($_.Exception.Message)" -ForegroundColor Red
        $results += @{
            Module = $jobInfo.Module
            ExitCode = 1
            Success = $false
            Error = $_.Exception.Message
        }
    }
    finally {
        if ($jobInfo.Job.State -eq "Running") {
            Stop-Job $jobInfo.Job
        }
        Remove-Job $jobInfo.Job -Force
    }
}

# 处理安装结果
Write-Host ""
Write-Host "处理安装结果..."
foreach ($result in $results) {
    if ($result.ExitCode -eq $global:exitSuccess) {
        Add-Content -Path $cacheFile -Value $result.Module
        $modulesInstalled += $result.Module
    } else {
        $modulesFailed += @{
            Module = $result.Module
            ExitCode = $result.ExitCode
            Error = $result.Error
        }
    }
}

# 5. 安装完成，总结安装成功和失败的模块
Write-Host ""
Write-Host "=== 安装总结 ==="
if ($modulesInstalled.Count -gt 0) {
    Write-Host "成功安装的模块：" -ForegroundColor Green
    foreach ($installedModule in $modulesInstalled) {
        Write-Host "  ✓ $installedModule" -ForegroundColor Green
    }
}

if ($modulesFailed.Count -gt 0) {
    Write-Host "安装失败的模块：" -ForegroundColor Red
    foreach ($failedModule in $modulesFailed) {
        Write-Host "  ✗ $($failedModule.Module) (退出代码: $($failedModule.ExitCode))" -ForegroundColor Red
        if ($failedModule.Error) {
            Write-Host "    错误: $($failedModule.Error)" -ForegroundColor Yellow
        }
    }
    Write-Host "总共有 $($modulesFailed.Count) 个模块安装失败" -ForegroundColor Red
    exit $global:exitInstallFail
} else {
    Write-Host "所有模块均安装成功！" -ForegroundColor Green
    exit $global:exitSuccess
}