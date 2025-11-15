if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoExit","-File",$PSCommandPath -Verb RunAs
    exit
}
Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\AddToPath" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\AddToPath" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "已卸载右键菜单。" -ForegroundColor Green
pause