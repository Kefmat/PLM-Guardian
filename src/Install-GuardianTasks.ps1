<#
.SYNOPSIS
    Installeringsskript for PLM Guardian Task Automation.
.DESCRIPTION
    Oppretter planlagte oppgaver i Windows Task Scheduler for automatisk 
    kjøring av ServiceWatcher og IntegrityCheck med faste intervaller.
#>

$ScriptNameWatcher = "PLM_Guardian_ServiceWatcher"
$ScriptNameIntegrity = "PLM_Guardian_IntegrityCheck"

$PathWatcher = "$PSScriptRoot\ServiceWatcher.ps1"
$PathIntegrity = "$PSScriptRoot\IntegrityCheck.ps1"

# Definerer handlingene (Actions)
$ActionWatcher = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PathWatcher`""
$ActionIntegrity = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PathIntegrity`""

# Definerer utløsere (Triggers)
# ServiceWatcher kjører hvert 5. minutt for høy beredskap
$TriggerWatcher = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
# IntegrityCheck kjører hver time da ressursendringer skjer langsommere
$TriggerIntegrity = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1)

# Definerer innstillinger (Settings)
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

try {
    # Registrerer oppgavene i Windows
    Register-ScheduledTask -TaskName $ScriptNameWatcher -Action $ActionWatcher -Trigger $TriggerWatcher -Settings $Settings -User "SYSTEM" -Force
    Register-ScheduledTask -TaskName $ScriptNameIntegrity -Action $ActionIntegrity -Trigger $TriggerIntegrity -Settings $Settings -User "SYSTEM" -Force
    
    Write-Host "Suksess: Planlagte oppgaver er registrert i Windows Task Scheduler." -ForegroundColor Green
}
catch {
    Write-Error "Kunne ikke registrere oppgaver: $($_.Exception.Message)"
}