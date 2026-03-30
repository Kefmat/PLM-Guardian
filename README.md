# PLM Guardian: Server Automation Suite

## Konsept: Fra Reaktiv til Proaktiv Systemforvaltning

Tradisjonell IT-drift baserer seg ofte på manuelle kontroller eller brukerrapporterte feil. PLM Guardian utforsker konseptet Self-Healing Infrastructure ved å flytte kontroll- og gjenopprettingsoppgaver fra administrator til kode.

Målet med prosjektet er å sikre maksimal tilgjengelighet for komplekse applikasjonsmiljøer der nedetid har store økonomiske konsekvenser. Ved å implementere kontinuerlig overvåking og automatiserte mottiltak, reduseres responstiden ved kritiske hendelser til et minimum.

## Læringsverdi og Metodikk

Utviklingen av denne suiten er basert på profesjonelle prinsipper for systemadministrasjon:

- **Idempotens**: Skriptene er utviklet for å kunne kjøres gjentatte ganger uten å endre systemets tilstand dersom det allerede fungerer optimalt.
- **Robust Feilhåndtering**: Bruk av try-catch-blokker sikrer at skriptet selv ikke blir en kilde til ustabilitet ved uforutsette systemendringer.
- **Auditability (Sporbarhet)**: Hver handling logges med tidsstempel og alvorlighetsgrad, noe som er essensielt for sikkerhetsrevisjon og etterlevelse av regulatoriske krav.

## Arkitektur og Systemdesign

Prosjektet er bygget modulært for å sikre enkel utvidelse og vedlikehold. Arkitekturen følger en Collector-Evaluator-Actor-modell.

### Modulstruktur

- **ServiceWatcher.ps1** (The Actor): Overvåker prosesstilstander for kritiske Windows-tjenester og utfører automatisk restart ved uventet stans.
- **IntegrityCheck.ps1** (The Evaluator): Analyserer systemressurser som diskplass og minnebruk (RAM). Inkluderer selvhelbredende logikk som automatisk frigjør diskplass ved sletting av gamle logger dersom kritiske terskelverdier nås.
- **ReportGenerator.ps1** (The Presenter): Aggregerer rådata fra loggfiler og genererer et visuelt HTML-dashboard med fargekodet status for enkel overvåking av serverparken.
- **Install-GuardianTasks.ps1**: Automatiserer distribusjon og oppsett av overvåkningssykluser via Windows Task Scheduler.

### Logisk Flyt

```
[ Trigger: Windows Task Scheduler / Manuelt ]
           |
           v
[ Collector: Henter systemdata via WMI/CIM-grensesnitt ]
           |
           v
[ Evaluator: Sammenligner faktiske verdier med konfigurasjon ]
           |
      /----^----\
     |           |
[ OK: Loggført ] [ AVVIK: Trigger Actor for korrigering ]
     |           |
      \----v----/
           |
[ Output: Oppdaterte loggfiler og systemstatus ]
```

### Tekniske Høydepunkter

- **Parametrisering**: Alle skript støtter parametere for terskelverdier, e-postadresser og dager for loggbevaring. Dette gjør suiten gjenbrukbar på tvers av ulike servermiljøer uten kodeendringer.
- **Visualisering**: Generering av dynamisk HTML/CSS-rapport som gir driftsledere øyeblikkelig statusoversikt.
- **WMI/CIM-integrasjon**: Benytter profesjonelle Windows-grensesnitt for presis innhenting av systemdata.
- **Automatisert Vedlikehold**: Innebygd logikk for sletting av foreldet data for å forhindre ressursmangel.

## Systemkrav og Bruk

- **OS**: Windows Server 2016+ / Windows 10/11
- **Språk**: PowerShell 5.1 eller PowerShell 7+
- **Rettigheter**: Krever administrative rettigheter for tjenestehåndtering og oppgaveplanlegging

## Installasjon

1. Klone eller last ned prosjektet til en passende mappe på serveren
2. Åpne PowerShell som administrator
3. Kjør installasjonsskriptet:
   ```powershell
   .\Install-GuardianTasks.ps1
   ```

## Bruk

### Manuell Kjøring
Kjør individuelle skript etter behov:
```powershell
.\ServiceWatcher.ps1
.\IntegrityCheck.ps1
.\ReportGenerator.ps1
```

### Automatisert Overvåking
Installasjonsskriptet setter opp automatiske oppgaver i Windows Task Scheduler. Disse kjøres på forhåndsdefinerte intervaller.

## Logging og Rapporter

Alle loggfiler lagres i `logs/`-mappen:
- **DailyStatus.txt**: Daglig statusrapport
- **ServiceStatus.log**: Tjenestestatus og handlinger
- **dashboard.html**: Interaktiv statusrapport generert av ReportGenerator.ps1

