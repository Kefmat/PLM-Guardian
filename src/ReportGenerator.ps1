<#
.SYNOPSIS
    ReportGenerator - Genererer visuelt dashboard fra loggdata.
.DESCRIPTION
    Analyserer loggfiler og transformerer rådata til et moderne HTML-dashboard
    for enkel statusoversikt over serverparken.
#>

$LogDir = "$PSScriptRoot\..\logs"
$TxtReportPath = "$LogDir\DailyStatus.txt"
$HtmlReportPath = "$LogDir\Dashboard.html"

function Get-GuardianSummary {
    $Files = Get-ChildItem -Path $LogDir -Filter "*.log"
    $Summary = @()

    foreach ($File in $Files) {
        $Content = Get-Content $File.FullName
        if ($null -eq $Content) { continue }

        $Warnings = ($Content | Select-String -Pattern "WARNING").Count
        $Criticals = ($Content | Select-String -Pattern "CRITICAL").Count
        $Errors = ($Content | Select-String -Pattern "FEIL").Count
        
        # Henter tidsstempel fra siste linje i loggen
        $LastCheck = "Ingen data"
        if ($Content.Count -gt 0) {
            $LastCheck = ($Content[-1] -split '\] ')[0].Trim('[')
        }

        $Summary += [PSCustomObject]@{
            Modul      = $File.BaseName
            Advarsler  = $Warnings
            Kritiske   = $Criticals
            Feil       = $Errors
            SisteSjekk = $LastCheck
        }
    }
    return $Summary
}

$FinalReport = Get-GuardianSummary

# --- GENERER HTML DASHBOARD ---
$Timestamp = Get-Date -Format "dd.MM.yyyy HH:mm"

$HtmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f0f2f5; padding: 40px; color: #333; }
        .container { max-width: 900px; margin: auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
        h1 { color: #1a365d; border-bottom: 2px solid #e2e8f0; padding-bottom: 10px; }
        .meta { color: #718096; margin-bottom: 25px; font-size: 0.9em; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th { background: #2d3748; color: white; text-align: left; padding: 15px; }
        td { padding: 15px; border-bottom: 1px solid #edf2f7; }
        .status-badge { padding: 5px 12px; border-radius: 20px; font-size: 0.85em; font-weight: bold; }
        .bg-ok { background: #c6f6d5; color: #22543d; }
        .bg-warn { background: #feebc8; color: #744210; }
        .bg-crit { background: #fed7d7; color: #822727; }
        tr:hover { background-color: #f7fafc; }
    </style>
</head>
<body>
    <div class="container">
        <h1>PLM Guardian Dashboard</h1>
        <p class="meta">Rapport generert: $Timestamp</p>
        <table>
            <tr>
                <th>Systemmodul</th>
                <th>Status</th>
                <th>Advarsler</th>
                <th>Kritiske</th>
                <th>Siste Sjekk</th>
            </tr>
"@

$HtmlBody = ""
foreach ($Row in $FinalReport) {
    # Bestem statusfarge
    $StatusClass = "bg-ok"
    $StatusText = "OPERATIV"
    if ($Row.Kritiske -gt 0 -or $Row.Feil -gt 0) {
        $StatusClass = "bg-crit"
        $StatusText = "FEIL DETEKTERT"
    } elseif ($Row.Advarsler -gt 0) {
        $StatusClass = "bg-warn"
        $StatusText = "OBSERVASJON"
    }

    $HtmlBody += @"
            <tr>
                <td>$($Row.Modul)</td>
                <td><span class="status-badge $StatusClass">$StatusText</span></td>
                <td>$($Row.Advarsler)</td>
                <td>$($Row.Kritiske + $Row.Feil)</td>
                <td>$($Row.SisteSjekk)</td>
            </tr>
"@
}

$HtmlFooter = @"
        </table>
    </div>
</body>
</html>
"@

# Lagre HTML-filen
$HtmlHeader + $HtmlBody + $HtmlFooter | Out-File -FilePath $HtmlReportPath -Encoding utf8

# Lagre også tekstversjon for arkiv
$FinalReport | Format-Table -AutoSize | Out-File $TxtReportPath

Write-Host "Suksess: Dashboard er generert!" -ForegroundColor Green
Write-Host "Filsti: $HtmlReportPath" -ForegroundColor Cyan