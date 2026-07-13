![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL_18-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![pgAdmin](https://img.shields.io/badge/pgAdmin_4-1E8CBE?style=for-the-badge&logo=postgresql&logoColor=white)
![Pentaho](https://img.shields.io/badge/Pentaho_Spoon-FF5E00?style=for-the-badge&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![PowerShell](https://img.shields.io/badge/PowerShell_5.1+-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)

# 🚀 Entorno BI: Seguros

**PostgreSQL + Pentaho Spoon + Power BI** — Sistema completo BI, 100% Docker.

---

## 📋 Requisitos

[Docker Desktop](https://www.docker.com/products/docker-desktop/) con WSL 2 · PowerShell 5.1+

## 📁 Estructura

```
D:\DockerData\bi\
│
├── scripts_helpers\           ← Todos los scripts .ps1
├── postgres\                  ← PostgreSQL + pgAdmin + SQL scripts
├── pentaho\                   ← Pentaho Spoon + ETLs + Excel fuente
├── enunciado proy\            ← PDFs del proyecto (Fase I y II)
├── power-bi\                  ← Dashboard .pbix + temas .json
├── menu.bat                   ← Acceso directo (doble click)
└── AGENTS.md                  ← Instrucciones para el agente
```

---

## 🚀 Cómo empezar


```powershell
.\scripts_helpers\menu.ps1
```

```
▄████▄ ▄▄▄▄  ▄▄▄▄  ▄▄▄▄   ▄▄▄   ▄▄▄   ▄▄▄▄ ▄▄ ▄▄   ▄█████  ▄▄▄  ▄▄▄▄▄ ▄▄▄▄▄▄
██▄▄██ ██▄█▀ ██▄█▀ ██▄█▄ ██▀██ ██▀██ ██▀▀▀ ██▄██   ▀▀▀▄▄▄ ██▀██ ██▄▄    ██
██  ██ ██    ██    ██ ██ ▀███▀ ██▀██ ▀████ ██ ██   █████▀ ▀███▀ ██      ██

============================================
          MENU PRINCIPAL
============================================

--- ENTORNO ---
[1]  Iniciar entorno
[2]  Detener entorno

--- DATOS ---
[3]  Generar e Hidratar BD
[4]  Ejecutar inserts defensa

--- MANTENIMIENTO ---
[5]  Limpiar DB schemas

[6]  Salir

============================================
```

| # | Opción | Descripción |
|---|--------|-------------|
| 1 | **Iniciar entorno** | Levanta PostgreSQL, pgAdmin y Pentaho Spoon |
| 2 | **Detener entorno** | Abre sub-menú para detener contenedores |
| 3 | **Generar e Hidratar BD** | Crea esquemas OLTP + DW y los llena con datos |
| 4 | **Ejecutar inserts defensa** | Inserta ~6,000 registros adicionales |
| 5 | **Limpiar DB schemas** | Abre sub-menú para truncar esquemas |
| 6 | **Salir** | Cierra el menú |

---

## 🛑 Sub-menú: Detener entorno (opción 2)

```
============================================
          STOP - DETENER ENTORNO
============================================

        [1]  PostgreSQL + pgAdmin
        [2]  Pentaho WebSpoon
        [3]  Todos los contenedores
        [4]  Salir

============================================
```

| Opción | Acción |
|--------|--------|
| 1 | Detiene solo PostgreSQL y pgAdmin |
| 2 | Detiene solo Pentaho Spoon |
| 3 | Detiene todos los contenedores |
| 4 | Vuelve al menú principal |

> [!NOTE]
> Antes de apagar pregunta si deseas eliminar los volúmenes de datos. Si respondes que sí, se borra toda la información persistente.

---

## 💧 Sub-menú: Generar e Hidratar BD (opción 3)

| Paso | Descripción |
|------|-------------|
| 1 | Verifica que el contenedor PostgreSQL esté corriendo |
| 2 | Verifica los archivos SQL (`create_tables.sql` + `hidrate.sql`) |
| 3 | Muestra advertencia si los esquemas ya existen y pide confirmación |
| 4 | Ejecuta los scripts: borra esquemas → crea tablas → inserta datos |

| Schema | Tipo | Contenido |
|--------|------|-----------|
| `SEGURO_G28310422` | OLTP | 12 tablas relacionales (~200 clientes, ~2000 contratos) |
| `SEGURO_DW_G28310422` | DW | 8 dimensiones + 4 tablas de hechos *(vacías — se llenan con ETLs)* |

> [!CAUTION]
> **Destructivo:** Borra y recrea ambos esquemas desde cero cada vez.

Al finalizar muestra conteo de registros por tabla y arte ASCII.

---

## 🎯 Sub-menú: Ejecutar inserts defensa (opción 4)

| Paso | Descripción |
|------|-------------|
| 1 | Verifica el contenedor PostgreSQL |
| 2 | Escanea el archivo SQL y cuenta los inserts por tabla |
| 3 | Muestra el desglose de registros a insertar y pide confirmación |
| 4 | Ejecuta todos los inserts en una sola transacción |

| Tabla | Registros |
|-------|:---------:|
| PRODUCTO | 9 |
| CLIENTE | 400 |
| CONTRATO | 1,200 |
| REGISTRO_CONTRATO | 1,800 |
| SINIESTRO | 600 |
| REGISTRO_SINIESTRO | 600 |
| RECOMIENDA | 1,400 |
| **Total** | **6,009** |

> [!TIP]
> Después de insertar, ejecuta las ETLs correspondientes en Pentaho para poblar el DW.

---

## 🧹 Sub-menú: Limpiar DB schemas (opción 5)

```
============================================
          LIMPIEZA DE ESQUEMAS
============================================

        [1]  Limpiar toda la BD (OLTP - DW)
        [2]  Limpiar solo el DW
        [3]  Volver

============================================
```

| Opción | Acción |
|--------|--------|
| 1 | Trunca todas las tablas de **OLTP + DW** |
| 2 | Trunca solo las tablas del **Data Warehouse** |
| 3 | Vuelve al menú principal |

> [!NOTE]
> Usa `TRUNCATE ... CASCADE`. Los esquemas y la estructura de tablas se conservan intactos.

---

## 🌐 Acceso a servicios

| Servicio | URL | Usuario | Clave |
|----------|-----|---------|-------|
| 🐘 pgAdmin 4 | http://localhost:8081 | admin@correo.com | `admin` |
| 📊 Pentaho Spoon | http://localhost:5800/spoon/spoon | admin | `password` |
| 🗄️ PostgreSQL | localhost:5432 | postgres | `postgres` |

---

## ⚠️ Configuración en Pentaho

> [!IMPORTANT]
> La conexión a la BD debe usar `postgres_db` como host (nombre del servicio Docker), **no** `localhost`.

**Guardar ETLs:** Guarda en `/home/tomcat/.kettle` dentro de Spoon; los archivos aparecen en `pentaho\mis_procesos\`.

| Ruta | Contenido |
|------|-----------|
| `pentaho\mis_procesos\data\transformaciones\` | 12 ETLs `.ktr` + 1 Job `.kjb` |
| `pentaho\mis_procesos\data\xlsx\` | Archivo Excel fuente de metas |

---

## 📊 Data Warehouse

| Tipo | Tablas |
|------|--------|
| 📐 **Dimensiones** | DIM_TIEMPO, DIM_CLIENTE, DIM_PRODUCTO, DIM_CONTRATO, DIM_SUCURSAL, DIM_ESTADO_CONTRATO, DIM_EVALUACION_SERVICIO, DIM_SINIESTRO |
| 📊 **Hechos** | FACT_REGISTRO_CONTRATO, FACT_REGISTRO_SINIESTRO, FACT_EVALUACION_SERVICIO, FACT_METAS |

**Orden de ejecución de ETLs:**

```
 1. DIM_TIEMPO               2. DIM_CLIENTE
 3. DIM_CONTRATO             4. DIM_ESTADO_CONTRATO
 5. DIM_EVALUACION_SERVICIO  6. DIM_PRODUCTO
 7. DIM_SINIESTRO            8. DIM_SUCURSAL
    ─────────────────────────────
 9. FACT_EVALUACION_SERVICIO
10. FACT_METAS
11. FACT_REGISTRO_CONTRATO
12. FACT_REGISTRO_SINIESTRO
```

> [!IMPORTANT]
> La unica restricción es ejecutar primero las DIM y luego los FACT, lo de arriba solo es una sugerencia.


---

## 📈 Power BI

| Recurso | Ruta |
|---------|------|
| Dashboard | `power-bi\dashboard-seguros-alta-vista.pbix` |
| Temas | `power-bi\*.json` |

---

## 🔧 Infraestructura

- Dos stacks de Docker comparten la red externa `red_datos`
- Datos persistentes: `postgres\data\` (git-ignored)
- Workspace ETL: `pentaho\mis_procesos\` (git-ignored)
> [!IMPORTANT]
> La ruta pentaho\mis_procesos\data no está ignorada asi como tampoco pentaho\shared.xml y pentaho\kettle.properties porque la idea es que el entorno sea reutilizable
- Probado en Windows (PowerShell 5.1+, Docker Desktop con WSL2); compatible con Linux/macOS (PowerShell 7+)


