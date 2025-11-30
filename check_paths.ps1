$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
Write-Host "User Path: $userPath"
Write-Host "System Path: $systemPath"
