# Zabbix Server IP
$server = "172.29.110.32"

# Download the latest Agent 2
$msi = "$env:TEMP\zabbix_agent2.msi"
Invoke-WebRequest "https://cdn.zabbix.com/zabbix/binaries/stable/7.0/7.0.1/zabbix_agent2-7.0.1-windows-amd64-openssl.msi" -OutFile $msi

# Install silently (Active mode only, auto registration)
Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn SERVER=$server SERVERACTIVE=$server HOSTMETADATA=auto-win" -Wait

# Start service
Set-Service "Zabbix Agent 2" -StartupType Automatic
Start-Service "Zabbix Agent 2"

# Clean up
Remove-Item $msi -Force
