<#
.SYNOPSIS
    ReportGenerator - Aggregerer loggdata til systemrapport.
.DESCRIPTION
    Analyserer loggfiler fra ServiceWatcher og IntegrityCheck for å 
    identifisere kritiske hendelser og gi en statusoversikt over systemet.
#>

$LogDir = "$PSScriptRoot\..\logs"
$ReportPath = "$PSScriptRoot\..\logs\DailyStatus.txt"

function Get-GuardianSummary {
    $Files = Get-ChildItem -Path $LogDir -Filter "*.log"
    $Summary = @()

    Write-Host "--- Genererer Systemstatusrapport ---" -ForegroundColor Cyan

    foreach ($File in $Files) {
        $Content = Get-Content $File.FullName
        $Warnings = $Content | Select-String -Pattern "WARNING"
        $Criticals = $Content | Select-String -Pattern "CRITICAL"
        $Errors = $Content | Select-String -Pattern "FEIL"

        $Stat = [PSCustomObject]@{
            Loggfil    = $File.Name
            Advarsler  = $Warnings.Count
            Kritiske   = $Criticals.Count
            Feil       = $Errors.Count
            SisteSjekk = ($Content[-1] -split '\] ')[0].Trim('[')
        }
        $Summary += $Stat
    }
    return $Summary
}

$FinalReport = Get-GuardianSummary

# Presentasjon av data
$FinalReport | Format-Table -AutoSize

# Lagre rapporten til fil for arkivering
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
"Systemrapport generert: $Timestamp" | Out-File $ReportPath
$FinalReport | Out-File $ReportPath -Append

Write-Host "Rapport er lagret i: $ReportPath" -ForegroundColor Green