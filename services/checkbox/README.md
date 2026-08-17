# Checkbox (MS SQL Server Express)

Zentrale Microsoft SQL Server Express-Instanz für die "Checkbox Workbench"-Software (Industrieelektronik Pölz GmbH, Atemschutzüberwachung Feuerwehr).

## Verbindung von Workbench-PCs

- **Host:** `checkbox.orfel.de,7224` (bzw. IP-Adresse des Servers, Port 7224)
- **User:** `sa`
- **Passwort:** Wird bei Ausführung von `generate-env.sh` generiert und in `.env` (bzw. `.env.age`) gespeichert.

> [!WARNING]
> Da die Datenbank für beliebige Workbench-PCs aus dem Internet erreichbar sein muss, ist Port `7224` direkt über Docker nach außen freigegeben. Ein starkes `SA_PASSWORD` ist zwingend erforderlich und wird vom `generate-env.sh` Script garantiert.
