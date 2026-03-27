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

### 1. Modulstruktur

- **ServiceWatcher.ps1 (The Actor)**: Overvåker prosesstilstander for definerte Windows-tjenester og utfører automatisk gjenoppretting ved stans.
- **IntegrityCheck.ps1 (The Evaluator)**: Analyserer systemressurser som diskplass og minnebruk (RAM) mot fastsatte terskelverdier (Thresholds).
- **Logs/ (The Repository)**: Sentral lagring av strukturerte loggfiler for analyse av historiske trender.

### 2. Logisk Flyt

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

### 3. Tekniske Spesifikasjoner

- **Språk**: PowerShell 5.1 / 7+
- **Grensesnitt**: Windows Management Instrumentation (WMI) / CIM
- **Logging**: Filbasert tekstlogging med støtte for loggnivåer (INFO, WARNING, CRITICAL)

## Roadmap og Utviklingsfaser

- **Fase 1**: Implementering av tjenesteovervåking og selvhelbredende logikk (Fullført).
- **Fase 2**: Ressursanalyse for disk- og minnekapasitet (Fullført).
- **Fase 3**: Automatisering av kjøreintervaller via Windows Task Scheduler (Planlagt).
- **Fase 4**: Utvikling av en aggregator for sentralisert rapportering på tvers av flere servere (Planlagt).