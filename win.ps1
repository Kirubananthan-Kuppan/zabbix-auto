# =============================================
# FULLY AUTOMATIC WINDOWS ZABBIX AGENT 2 DEPLOY
# =============================================

Write-Host "Starting Zabbix Agent auto deployment..." -ForegroundColor Cyan

# -------- SETTINGS --------
$ZabbixServer = "103.127.29.5"
$ZabbixVersion = "7.0.4"
# --------------------------

# Auto detect hostname & IP
$HostName = (hostname)
$IpAddress = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notmatch "169.*|127.*" } |
    Select-Object -First 1 -ExpandProperty IPAddress)

Write-Host "Detected Hostname: $HostName"
Write-Host "Detected IP Address: $IpAddress"

# Work directory
$WorkDir = "C:\ZabbixAuto"
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

# Correct Zabbix Agent 2 download URL
$zipFile = "$WorkDir\zabbix.zip"
$downloadUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/$ZabbixVersion/zabbix_agent2-$ZabbixVersion-windows-amd64-openssl-static.zip"

Write-Host "Downloading Zabbix Agent 2 ZIP package..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile

Write-Host "Extracting Zabbix Agent 2..." -ForegroundColor Cyan
Expand-Archive -Path $zipFile -DestinationPath "$WorkDir\unzipped" -Force

# Install path
$AgentPath = "C:\Program Files\Zabbix Agent 2"
New-Item -ItemType Directory -Force -Path $AgentPath | Out-Null

# Copy binaries
Copy-Item "$WorkDir\unzipped\bin\zabbix_agent2.exe" $AgentPath -Force
Copy-Item "$WorkDir\unzipped\conf\zabbix_agent2.conf" $AgentPath -Force

# Update config
$ConfigFile = "$AgentPath\zabbix_agent2.conf"

(Get-Content $ConfigFile) |
    ForEach-Object {
        $_ -replace '^Server=.*', "Server=$ZabbixServer" `
           -replace '^ServerActive=.*', "ServerActive=$ZabbixServer" `
           -replace '^Hostname=.*', "Hostname=$HostName"
    } | Set-Content $ConfigFile

# Install service
Write-Host "Installing Zabbix Agent 2 as service..." -ForegroundColor Cyan
& "$AgentPath\zabbix_agent2.exe" --install

# Start service
Start-Service "Zabbix Agent 2"
Set-Service -Name "Zabbix Agent 2" -StartupType Automatic

Write-Host "Zabbix Agent 2 successfully installed & running!" -ForegroundColor Green
Write-Host "Machine IP: $IpAddress"
Write-Host "Hostname: $HostName"
Write-Host "Server: $ZabbixServer"
