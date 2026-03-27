<#
.SYNOPSIS
    IntegrityCheck - Ressursanalyse med automatisert opprydding.
.DESCRIPTION
    Sjekker tilgjengelig diskplass og minnebruk mot definerte terskelverdier.
    Utfører automatisk sletting av gamle loggfiler dersom diskplassen er kritisk lav.
#>

# Konfigurasjon av terskelverdier (Thresholds)
$DiskThresholdPercent = 10 
$MemoryThresholdPercent = 90 
$LogDir = "$PSScriptRoot\..\logs"
$LogPath = "$LogDir\IntegrityCheck.log"

# Opprett logg-mappe hvis den ikke finnes
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force }

function Write-GuardianLog {
    param(
        [string]$Message, 
        [ValidateSet("INFO", "WARNING", "CRITICAL")]
        [string]$Level = "INFO"
    )
    $Stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Stamp] [$Level] $Message" | Out-File -FilePath $LogPath -Append
}

# NY FUNKSJON: Automatisk opprydding for å frigjøre plass
function Start-GuardianCleanup {
    Write-GuardianLog "Trigger automatisert opprydding: Sletter logger eldre enn 7 dager." "INFO"
    $Limit = (Get-Date).AddDays(-7)
    $OldFiles = Get-ChildItem -Path $LogDir -Filter "*.log" | Where-Object { $_.LastWriteTime -lt $Limit }
    
    foreach ($File in $OldFiles) {
        Remove-Item $File.FullName -Force
        Write-GuardianLog "Slettet gammel loggfil: $($File.Name)" "INFO"
    }
}

Write-GuardianLog "--- Starter ressursanalyse ---"

# Analyse av logiske disker
try {
    $Disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($Disk in $Disks) {
        $FreePercent = ($Disk.FreeSpace / $Disk.Size) * 100
        $FreeGB = [Math]::Round($Disk.FreeSpace / 1GB, 2)
        
        if ($FreePercent -lt $DiskThresholdPercent) {
            Write-GuardianLog "ADVARSEL: Lav diskplass på $($Disk.DeviceID). Kun $FreeGB GB ledig." "WARNING"
            # Utfører opprydding for å avhjelpe situasjonen
            Start-GuardianCleanup
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
        Write-GuardianLog "ADVARSEL: Høy minnebruk detektert ($([Math]::Round($UsedMemoryPercent, 2))%)." "WARNING"
    } else {
        Write-GuardianLog "OK: Minnebruk er innenfor normale verdier."
    }
}
catch {
    Write-GuardianLog "KRITISK: Kunne ikke hente minneinformasjon. Feil: $($_.Exception.Message)" "CRITICAL"
}

Write-GuardianLog "--- Ressursanalyse fullført ---"