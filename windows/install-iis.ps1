#
# Author : Carter Tsai
#
# Install IIS
cls

# Variabl
$site = @{"Name"="B2C"}
$site.Path = ("C:\inetpub\"+$site.Name)
$site.LogPath = ("C:\inetpub\"+ $site.Name + "\Log\")

# Install
Add-WindowsFeature Web-Server
Add-WindowsFeature NET-Framework-45-ASPNET
Add-WindowsFeature -Name Web-Common-Http,Web-Asp-Net,Web-Net-Ext,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Http-Logging,Web-Request-Monitor,Web-Basic-Auth
Add-WindowsFeature -Name Web-Windows-Auth,Web-Filtering,Web-Performance,Web-Mgmt-Console,Web-Mgmt-Compat,WAS -IncludeAllSubFeature

# Import Module
Import-Module WebAdministration

# Create
if(Test-Path $site.Path) {
    Remove-Item $site.Path
}

New-Item $site.Path -type directory


# Start and New WebAppPool and Configure

Remove-WebAppPool -Name $site.Name

$pool = New-WebAppPool -Name $site.Name
$pool.recycling.periodicrestart.time = [TimeSpan]::FromMinutes(0)
$pool.processModel.idleTimeout = [TimeSpan]::FromMinutes(1440)

Set-ItemProperty -Path ("IIS:\AppPools\"+$site.Name) -Name Recycling.periodicRestart.schedule -Value @{value="04:00"}
Set-ItemProperty -Path ("IIS:\AppPools\"+$site.Name) -Name Recycling.periodicRestart.time $pool.recycling.periodicrestart.time
Set-ItemProperty ("IIS:\AppPools\"+$site.Name) -Name processModel.idleTimeout $pool.processModel.idleTimeout
Set-ItemProperty ("IIS:\AppPools\"+$site.Name) managedRuntimeVersion v4.0

Start-WebAppPool -Name $site.Name

# Remove WebSite

$w = Get-Website

# Remove Default Web Site
if($w.Name -eq "Default Web Site") {
    Remove-WebSite -Name ($w.Name)
}

# Remove Site 
if($w.Name -eq $site.Name) {
    Remove-WebSite -Name ($w.Name)
}

# Create Site
New-Website -Name ($site.Name) -PhysicalPath $site.Path -ApplicationPool $site.Name

# Modified Logger
# Set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name logfile.directory -value $site.LogPath
Set-WebConfigurationProperty -Filter System.Applicationhost/Sites/SiteDefaults/logfile -Name LogExtFileFlags -Value "Date,Time,ClientIP,UserName,ServerIP,Method,UriStem,UriQuery,HttpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,UserAgent,Host,HttpSubStatus,Referer"


iisreset