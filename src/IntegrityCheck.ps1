<#
.SYNOPSIS
    IntegrityCheck - Ressursanalyse for Windows-servere.
.DESCRIPTION
    Sjekker tilgjengelig diskplass og minnebruk mot definerte terskelverdier.
    Genererer varsler i loggen dersom ressursbruken overstiger de fastsatte grensene.
#>

# Konfigurasjon av terskelverdier (Thresholds)
$DiskThresholdPercent = 10 
$MemoryThresholdPercent = 90 
$LogPath = "$PSScriptRoot\..\logs\IntegrityCheck.log"

# Opprett logg-mappe hvis den ikke finnes
if (!(Test-Path "$PSScriptRoot\..\logs")) { New-Item -ItemType Directory -Path "$PSScriptRoot\..\logs" -Force }

function Write-GuardianLog {
    param(
        [string]$Message, 
        [ValidateSet("INFO", "WARNING", "CRITICAL")]
        [string]$Level = "INFO"
    )
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Stamp] [$Level] $Message" | Out-File -FilePath $LogPath -Append
}

Write-GuardianLog "--- Starter ressursanalyse ---"

# Analyse av logiske disker (DriveType 3 = Lokal disk)
try {
    $Disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($Disk in $Disks) {
        $FreePercent = ($Disk.FreeSpace / $Disk.Size) * 100
        $FreeGB = [Math]::Round($Disk.FreeSpace / 1GB, 2)
        
        if ($FreePercent -lt $DiskThresholdPercent) {
            Write-GuardianLog "ADVARSEL: Lav diskplass på $($Disk.DeviceID). Kun $FreeGB GB ($([Math]::Round($FreePercent, 2))%) ledig." "WARNING"
        } else {
            Write-GuardianLog "OK: Disk $($Disk.DeviceID) har tilstrekkelig plass ($FreeGB GB ledig)."
        }
    }
}
catch {
    Write-GuardianLog "KRITISK: Kunne ikke hente diskinformasjon. Feil: $($_.Exception.Message)" "CRITICAL"
}

# Analyse av fysisk minnebruk (RAM)
try {
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem
    $TotalVisibleMemory = $OS.TotalVisibleMemorySize
    $FreePhysicalMemory = $OS.FreePhysicalMemory
    $UsedMemoryPercent = (($TotalVisibleMemory - $FreePhysicalMemory) / $TotalVisibleMemory) * 100

    if ($UsedMemoryPercent -gt $MemoryThresholdPercent) {
        Write-GuardianLog "ADVARSEL: Høy minnebruk detektert. $($([Math]::Round($UsedMemoryPercent, 2)))% av RAM er i bruk." "WARNING"
    } else {
        Write-GuardianLog "OK: Minnebruk er innenfor normale verdier ($([Math]::Round($UsedMemoryPercent, 2))%)."
    }
}
catch {
    Write-GuardianLog "KRITISK: Kunne ikke hente minneinformasjon. Feil: $($_.Exception.Message)" "CRITICAL"
}

Write-GuardianLog "--- Ressursanalyse fullført ---"