param([string]$folderPath)
Add-Type -AssemblyName System.Windows.Forms
try {
    $usrPath = [Environment]::GetEnvironmentVariable('Path','User')
    if ($usrPath -split ';' -contains $folderPath) {
        [System.Windows.Forms.MessageBox]::Show("Path has exists!", "Tips", "OK", "Information")
        return
    }
    [Environment]::SetEnvironmentVariable('Path', "$usrPath;$folderPath", 'User')
    [System.Windows.Forms.MessageBox]::Show("Path successfully added: `n$folderPath", "Success", "OK", "Information")
} catch {
    [System.Windows.Forms.MessageBox]::Show("Error:$_", "Error", "OK", "Error")
}
