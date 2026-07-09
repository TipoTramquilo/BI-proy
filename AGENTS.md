# AGENTS.md — BI Environment (PostgreSQL + Pentaho Spoon)

## Quick start

```powershell
.\menu.ps1              # interactive menu (start / stop / hydrate)
.\run.ps1               # start everything directly
.\stop.ps1               # stop containers (asks about volumes)
.\postgres\db_setup\run_hidratation.ps1   # hydrate DB with test data
```

- PowerShell execution policy may need `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` on first use.

## Services

| Service       | URL                             | Auth                     |
|---------------|---------------------------------|--------------------------|
| pgAdmin 4     | http://localhost:8081           | admin@correo.com / admin |
| Pentaho Spoon | http://localhost:5800/spoon/spoon | admin / password         |
| PostgreSQL    | localhost:5432                  | postgres / postgres      |

## Critical Pentaho quirks

- **Database host**: use `postgres_db` (Docker service name), *not* `localhost`.
- **Save path**: inside Spoon save to `/home/tomcat/.kettle` — files appear in `pentaho\mis_procesos\` on the host.

## Hydration

`run_hidratation.ps1` requires the `postgres_db` container to be running.
Creates schema `SEGURO_G28310422` (12 transactional tables with ~200 clients, ~2000 contracts) and empty DW schema `SEGURO_DW_G28310422`.
**Destructive**: drops and recreates both schemas each run.

## Infrastructure

- Two `docker compose` stacks share the external Docker network `red_datos`.
- `run.ps1`: creates `red_datos` if missing → `docker compose up -d` in `postgres/` → `pentaho/`.
- Data persists in `postgres\data\` (git-ignored).
- ETL workspace in `pentaho\mis_procesos\` (git-ignored).
- Windows-only (PowerShell 5.1+, Docker Desktop with WSL2 backend).
