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
    "captura"
)

$global:customToolsPath = "$env:USERPROFILE\CustomTools"
if (Test-Path $customToolsPath) {
    New-Item -ItemType Directory -Path $customToolsPath -Force | Out-Null
}

# 1. 获取当前脚本所在目录
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

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
        param($scriptPath, $moduleName)
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
            
            # 执行安装脚本
            & $scriptPath
            
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
    
    $job = Start-Job -ScriptBlock $jobScript -ArgumentList $moduleScript, $module
    
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
    if ($result.Success -eq $true -and $result.ExitCode -eq $global:exitSuccess) {
        Add-Content -Path $cacheFile -Value $result.Module
        $modulesInstalled += $result.Module
        Write-Host "✓ 模块 $($result.Module) 安装成功" -ForegroundColor Green
    } else {
        $modulesFailed += @{
            Module = $result.Module
            ExitCode = $result.ExitCode
            Error = $result.Error
        }
        Write-Host "✗ 模块 $($result.Module) 安装失败，退出代码：$($result.ExitCode)" -ForegroundColor Red
        if ($result.Error) {
            Write-Host "  错误详情: $($result.Error)" -ForegroundColor Yellow
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