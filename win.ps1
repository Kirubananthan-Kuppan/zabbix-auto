# ================================================
# WINDOWS FULL AUTO DEPLOY — ZABBIX AGENT
# NO MANUAL WORK REQUIRED
# ================================================

Write-Host "Starting Zabbix Agent auto deployment..." -ForegroundColor Cyan

# -------- SETTINGS (YOU CAN CHANGE THESE) -------
$ZabbixServer = "103.127.29.5"        # Your Zabbix server IP
$ZabbixVersion = "7.0.4"
# -------------------------------------------------

# Auto-detect hostname
$HostName = (hostname)

# Auto-detect primary IP (compatible with DHCP / any network)
$IpAddress = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -notlike "127.*" } |
    Select-Object -First 1 -ExpandProperty IPAddress)

Write-Host "Detected Hostname: $HostName"
Write-Host "Detected IP Address: $IpAddress"

# Create working directory silently
$WorkDir = "C:\Zabbix"
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

# Download Zabbix Agent MSI
$msi = "$WorkDir\zabbix-agent.msi"
$downloadUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/$ZabbixVersion/zabbix_agent-$ZabbixVersion-windows-amd64-openssl.msi"

Write-Host "Downloading Zabbix Agent..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $downloadUrl -OutFile $msi

# Install silently
Write-Host "Installing Zabbix Agent..." -ForegroundColor Cyan
Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet" -Wait

# Path of configuration file
$ConfigFile = "C:\Program Files\Zabbix Agent\zabbix_agentd.conf"

# Update config automatically
Write-Host "Configuring Zabbix Agent..." -ForegroundColor Cyan

(Get-Content $ConfigFile) `
 | ForEach-Object {
        $_ -replace '^Server=.*', "Server=$ZabbixServer" `
           -replace '^ServerActive=.*', "ServerActive=$ZabbixServer" `
           -replace '^Hostname=.*', "Hostname=$HostName" `
 } | Set-Content $ConfigFile

# Start service
Write-Host "Starting Zabbix Agent Service..." -ForegroundColor Cyan
Start-Service "Zabbix Agent"

# Enable autostart
Set-Service -Name "Zabbix Agent" -StartupType Automatic

Write-Host "Zabbix Agent successfully installed & running!" -ForegroundColor Green
Write-Host "Machine IP: $IpAddress"
Write-Host "Hostname: $HostName"
Write-Host "Server: $ZabbixServer"
