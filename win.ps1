# ================================================
# WINDOWS FULL AUTO DEPLOY — ZABBIX AGENT 2
# ================================================

Write-Host "Starting Zabbix Agent auto deployment..." -ForegroundColor Cyan

# -------- SETTINGS --------
$ZabbixServer = "103.127.29.5"
$ZabbixVersion = "7.0.4"
# --------------------------

# Auto-detect hostname
$HostName = (hostname)

# Auto-detect IP (DHCP / any network)
$IpAddress = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*" } |
    Select-Object -First 1 -ExpandProperty IPAddress)

Write-Host "Detected Hostname: $HostName"
Write-Host "Detected IP Address: $IpAddress"

# Create work dir
$WorkDir = "C:\Zabbix"
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

# Correct Zabbix Agent 2 MSI download URL
$msi = "$WorkDir\zabbix-agent2.msi"
$downloadUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/$ZabbixVersion/zabbix_agent2-$ZabbixVersion-windows-amd64-openssl.msi"

Write-Host "Downloading Zabbix Agent 2..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $downloadUrl -OutFile $msi

# Install silently
Write-Host "Installing Zabbix Agent 2..." -ForegroundColor Cyan
Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet" -Wait

# Correct config file path for Agent 2
$ConfigFile = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"

Write-Host "Configuring Zabbix Agent 2..." -ForegroundColor Cyan

(Get-Content $ConfigFile) `
 | ForEach-Object {
        $_ -replace '^Server=.*', "Server=$ZabbixServer" `
           -replace '^ServerActive=.*', "ServerActive=$ZabbixServer" `
           -replace '^Hostname=.*', "Hostname=$HostName"
 } | Set-Content $ConfigFile

# Start service
Write-Host "Starting Zabbix Agent 2 service..." -ForegroundColor Cyan
Start-Service "Zabbix Agent 2"

# Auto start
Set-Service -Name "Zabbix Agent 2" -StartupType Automatic

Write-Host "Zabbix Agent 2 successfully installed & running!" -ForegroundColor Green
Write-Host "Machine IP: $IpAddress"
Write-Host "Hostname: $HostName"
Write-Host "Server: $ZabbixServer"
