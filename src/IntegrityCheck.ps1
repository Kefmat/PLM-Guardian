<#
.SYNOPSIS
    IntegrityCheck - Proaktiv ressursanalyse med automatisert opprydding.
.DESCRIPTION
    Sjekker tilgjengelig diskplass og minnebruk mot definerte terskelverdier.
    Utfører automatisk sletting av gamle loggfiler dersom diskplassen er kritisk lav.
    Inkluderer parametrisering for enkel tilpasning i ulike servermiljøer.
#>

param(
    [Parameter(HelpMessage="Terskel for lav diskplass i prosent")]
    [int]$DiskThresholdPercent = 10,

    [Parameter(HelpMessage="Terskel for høy minnebruk i prosent")]
    [int]$MemoryThresholdPercent = 90,

    [Parameter(HelpMessage="Antall dager logger skal beholdes ved opprydding")]
    [int]$DaysToKeep = 7
)

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

# Automatisk opprydding for å frigjøre plass
function Start-GuardianCleanup {
    Write-GuardianLog "Trigger automatisert opprydding: Sletter logger eldre enn $DaysToKeep dager." "WARNING"
    $Limit = (Get-Date).AddDays(-$DaysToKeep)
    $OldFiles = Get-ChildItem -Path $LogDir -Filter "*.log" | Where-Object { $_.LastWriteTime -lt $Limit }
    
    if ($OldFiles.Count -gt 0) {
        foreach ($File in $OldFiles) {
            Remove-Item $File.FullName -Force
            Write-GuardianLog "Slettet gammel loggfil: $($File.Name)" "INFO"
        }
    } else {
        Write-GuardianLog "Ingen filer funnet for sletting (eldre enn $DaysToKeep dager)." "INFO"
    }
}

Write-GuardianLog "--- Starter ressursanalyse (Terskel: $DiskThresholdPercent% Disk / $MemoryThresholdPercent% RAM) ---"

# Analyse av logiske disker
try {
    $Disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($Disk in $Disks) {
        $FreePercent = ($Disk.FreeSpace / $Disk.Size) * 100
        $FreeGB = [Math]::Round($Disk.FreeSpace / 1GB, 2)
        
        if ($FreePercent -lt $DiskThresholdPercent) {
            Write-GuardianLog "ADVARSEL: Lav diskplass på $($Disk.DeviceID). Kun $FreeGB GB ($([Math]::Round($FreePercent, 2))%) ledig." "WARNING"
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
        Write-GuardianLog "OK: Minnebruk er innenfor normale verdier ($([Math]::Round($UsedMemoryPercent, 2))%)."
    }
}
catch {
    Write-GuardianLog "KRITISK: Kunne ikke hente minneinformasjon. Feil: $($_.Exception.Message)" "CRITICAL"
}

Write-GuardianLog "--- Ressursanalyse fullført ---"