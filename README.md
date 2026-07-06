<div align="center">

# 🚀 Entorno BI: PostgreSQL + Pentaho Spoon

**Entorno analítico replicable vía Docker — aislado, portable y listo para desarrollar ETLs.**

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![pgAdmin](https://img.shields.io/badge/pgAdmin_4-9-1E8CBE?style=for-the-badge&logo=postgresql&logoColor=white)
![Pentaho](https://img.shields.io/badge/Pentaho_Spoon-latest-FF5E00?style=for-the-badge&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-7.4-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![WSL2](https://img.shields.io/badge/WSL_2-4EAA25?style=for-the-badge&logo=linux&logoColor=white)

</div>

---

## 📋 Requisitos previos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) con **WSL 2** como backend
- PowerShell **5.1+** (viene incluido en Windows 10/11)

---

## 📁 Estructura del proyecto

```
D:\DockerData\bi\
├── postgres\
│   ├── postgres-compose.yaml   ← Base de datos + pgAdmin 4
│   └── data\                   ← Datos persistentes (se crea sola)
├── pentaho\
│   ├── pentaho-compose.yaml    ← Pentaho Spoon web
│   └── mis_procesos\           ← Tus .ktr, .kjb, .js (se crea sola)
└── run.ps1                     ← Script encender todo
```

---

## ⚙️ Setup inicial (solo una vez)

Si es la primera vez que abres PowerShell en esta máquina, es probable que tengas restringida la ejecución de scripts. Puedes verificarlo con:

```powershell
Get-ExecutionPolicy
```

Si devuelve `Restricted`, habilita la ejecución (recomendado):

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Luego confirma con `S` (Sí). A partir de ese momento podrás ejecutar cualquier `.ps1` sin necesidad del flag `-ExecutionPolicy Bypass`.

---

## 🚦 Flujo de trabajo diario (encender)

Desde la raíz del proyecto (`D:\DockerData\bi\`):

```powershell
powershell -ExecutionPolicy Bypass -File .\run.ps1
```

Si ya configuraste la **ExecutionPolicy** como se indicó arriba, basta con:

```powershell
.\run.ps1
```

### ¿Qué hace el script?

1. Verifica que la **red `red_datos`** exista en Docker; si no, la crea automáticamente.
2. Levanta **PostgreSQL + pgAdmin** en segundo plano.
3. Levanta **Pentaho Spoon** (interfaz web).

---

## 🌐 Acceso a los servicios

| Servicio       | URL                              | Usuario            | Contraseña |
|----------------|----------------------------------|--------------------|------------|
| **pgAdmin 4**  | http://localhost:8081            | admin@correo.com   | `admin`    |
| **Pentaho Spoon** | http://localhost:5800         | —                  | —          |

---

## ⚠️ Configuración crítica dentro de Pentaho

### 1. Conexión a la base de datos

Cuando crees una nueva conexión a PostgreSQL dentro de la web de Spoon, en el campo **Host Name** NO escribas `localhost`. Debes escribir el nombre del **servicio Docker**:

> **Host:** `postgres_db`

### 2. Ruta de guardado de ETLs

Al guardar tus flujos (`.ktr` / `.kjb`) dentro de la interfaz web, elige la carpeta:

```
/home/tomcat/.kettle
```

Al hacerlo, tus archivos aparecerán **automáticamente** en tu Windows real en:

```
D:\DockerData\bi\pentaho\mis_procesos\
```

---

## 🛑 Apagar el entorno

Cuando termines tu jornada y quieras liberar recursos:

```powershell
cd .\postgres; docker compose -f postgres-compose.yaml down; cd ..
```

```powershell
cd .\pentaho; docker compose -f pentaho-compose.yaml down; cd ..
```

O simplemente desde Docker Desktop, apagar los contenedores.

---

## 📜 Referencia del script

### `run.ps1`

```powershell
# 1. Crea la red 'red_datos' si no existe
$networkCheck = docker network ls --filter name=^red_datos$ --format "{{.Name}}"
if (-not $networkCheck) {
    Write-Host "[i] Creando red 'red_datos'..." -ForegroundColor Yellow
    docker network create red_datos
}

# 2. Levanta PostgreSQL + pgAdmin
Set-Location ".\postgres"
docker compose -f postgres-compose.yaml up -d

# 3. Levanta Pentaho Spoon
Set-Location "..\pentaho"
docker compose -f pentaho-compose.yaml up -d

Write-Host "[LISTO] Entorno encendido" -ForegroundColor Green
```

---

