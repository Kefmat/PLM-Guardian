<#
.SYNOPSIS
    IntegrityCheck - Ressursanalyse for Windows-servere.
.DESCRIPTION
    Sjekker tilgjengelig diskplass og minnebruk mot definerte terskelverdier.
    Genererer varsler i loggen dersom ressursbruken overstiger grensene.
#>

# Konfigurasjon av terskelverdier (Thresholds)
$DiskThresholdPercent = 10 # Varsle hvis mindre enn 10% ledig
$MemoryThresholdPercent = 90 # Varsle hvis mer enn 90% brukt
$LogPath = "$PSScriptRoot\..\logs\IntegrityCheck.log"

function Write-GuardianLog {
    param([string]$Message, [string]$Level = "INFO")
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Stamp] [$Level] $Message" | Out-File -FilePath $LogPath -Append
}

Write-GuardianLog "--- Starter ressursanalyse ---"

# 1. Sjekk Diskplass
$Disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
foreach ($Disk in $Disks) {
    $FreePercent = ($Disk.FreeSpace / $Disk.Size) * 100
    $FreeGB = [Math]::Round($Disk.FreeSpace / 1GB, 2)
    
    if ($FreePercent -lt $DiskThresholdPercent) {
        Write-GuardianLog "ADVARSEL: Lav diskplass på $($Disk.DeviceID). Kun $FreeGB GB ($([Math]::Round($FreePercent, 2))%) ledig." "WARNING"
    } else {
        Write-GuardianLog "OK: Disk $($Disk.DeviceID) har $FreeGB GB ledig."
    }
}

# 2. Sjekk Minnebruk (RAM)
$OS = Get-CimInstance -ClassName Win32_OperatingSystem
$TotalVisibleMemory = $OS.TotalVisibleMemorySize
$FreePhysicalMemory = $OS.FreePhysicalMemory
$UsedMemoryPercent = (($TotalVisibleMemory - $FreePhysicalMemory) / $TotalVisibleMemory) * 100

if ($UsedMemoryPercent -gt $MemoryThresholdPercent) {
    Write-GuardianLog "ADVARSEL: Høy minnebruk detektert. $($([Math]::Round($UsedMemoryPercent, 2)))% av RAM er i bruk." "WARNING"
} else {
    Write-GuardianLog "OK: Minnebruk er på $([Math]::Round($UsedMemoryPercent, 2))%."
}

Write-GuardianLog "--- Ressursanalyse fullført ---"