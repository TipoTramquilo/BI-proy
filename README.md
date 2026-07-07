<div align="center">

# 🚀 Entorno BI: PostgreSQL + Pentaho Spoon

**Entorno analítico replicable vía Docker — aislado, portable y listo para desarrollar ETLs.**

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![pgAdmin](https://img.shields.io/badge/pgAdmin_4-9-1E8CBE?style=for-the-badge&logo=postgresql&logoColor=white)
![Pentaho](https://img.shields.io/badge/Pentaho_Spoon-0.9.0-FF5E00?style=for-the-badge&logoColor=white)
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
│   ├── postgres-compose.yaml  <- Base de datos + pgAdmin 4
│   ├── db_setup\              <- Scripts SQL e hidratacion
│   └── data\                  <- Datos persistentes
├── pentaho\
│   ├── pentaho-compose.yaml   <- Pentaho Spoon web
│   └── mis_procesos\          <- .ktr, .kjb, .js
├── run.ps1                    <- Encender todo
├── stop.ps1                   <- Detener contenedores (menu)
└── menu.ps1                   <- Menu principal
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

## 🚦 Flujo de trabajo diario

Desde la raíz del proyecto (`D:\DockerData\bi\`):

```powershell
.\menu.ps1
```

Esto abre un menu con todas las operaciones del entorno:

1. **Iniciar entorno** — ejecuta `run.ps1` (red, PostgreSQL, pgAdmin, Pentaho).
2. **Detener entorno** — ejecuta `stop.ps1` con opcion de borrar volumenes.
3. **Hidratar base de datos** — ejecuta `run_hidratation.ps1` para poblar la BD con datos de prueba.
4. **Salir**

Si se prefiere ejecutar un paso directamente:

```powershell
.\run.ps1    # Solo encender
.\stop.ps1   # Solo detener
```

Si ya configuraste la **ExecutionPolicy** como se indicó arriba, basta con el nombre del script. Caso contrario:

```powershell
powershell -ExecutionPolicy Bypass -File .\menu.ps1
```

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

## 💧 Hidratar la base de datos

Una vez que el entorno esta encendido, puebla la BD con datos de prueba (200 clientes, 2000 contratos, etc.):

```powershell
.\postgres\db_setup\run_hidratation.ps1
```

O desde el menu principal (`.\menu.ps1`), opcion **3**.

El script crea el esquema `SEGURO_G28310422` con 12 tablas (paises, ciudades, sucursales, productos, clientes, contratos, siniestros, evaluaciones) y lo llena con datos realistas.

---

## 🛑 Apagar el entorno

```powershell
.\stop.ps1
```

Menu interactivo para detener:

1. **PostgreSQL + pgAdmin**
2. **Pentaho WebSpoon**
3. **Todos los contenedores**

Antes de detener pregunta si se desea eliminar los volumenes de datos (borra toda la informacion persistente).

---

## 📜 Referencia de scripts

### `run.ps1`

Levanta todo el entorno:
1. Crea la red `red_datos` si no existe.
2. `docker compose up -d` en `postgres/` (PostgreSQL + pgAdmin).
3. `docker compose up -d` en `pentaho/` (Pentaho Spoon).

### `stop.ps1`

Menu interactivo para detener contenedores:

- Opcion 1: detiene solo PostgreSQL + pgAdmin.
- Opcion 2: detiene solo Pentaho Spoon.
- Opcion 3: detiene ambos.
- Antes de ejecutar `docker compose down`, pregunta si se deben eliminar los volumenes (`-v`).

### `menu.ps1`

Menu principal que agrupa las tres operaciones basicas del entorno:

1. **Iniciar** -> ejecuta `run.ps1`
2. **Detener** -> ejecuta `stop.ps1`
3. **Hidratar** -> ejecuta `postgres/db_setup/run_hidratation.ps1`
4. **Salir**

---

