# Limpiar la pantalla para iniciar el proceso de forma limpia
Clear-Host

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "        🚀 INICIANDO ENTORNO ANALÍTICO DE DATOS        " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# 1. Verificar si la red existe. Si no, la crea.
Write-Host "`n[1/3] 🌐 Verificando red compartida..." -ForegroundColor Gray
try {
    $networkCheck = docker network ls --filter name=^red_datos$ --format "{{.Name}}"
    if (-not $networkCheck) {
        Write-Host "      ⚠️  La red 'red_datos' no existe. Creándola ahora..." -ForegroundColor Yellow
        docker network create red_datos | Out-Null
        Write-Host "      ✅ Red 'red_datos' creada con éxito." -ForegroundColor Green
    } else {
        Write-Host "      ✅ Red 'red_datos' detectada y lista para usar." -ForegroundColor Green
    }
} catch {
    Write-Host "`n┌─────────────────────────────────────────────────────┐" -ForegroundColor Red
    Write-Host "│  ❌ ERROR: No se pudo verificar o crear la red.     │" -ForegroundColor Red
    Write-Host "│  Asegúrate de que Docker Desktop esté encendido.    │" -ForegroundColor Red
    Write-Host "└─────────────────────────────────────────────────────┘" -ForegroundColor Red
    Exit 1
}

# 2. Entrar a la subcarpeta de postgres y levantar el servicio
Write-Host "`n[2/3] 🐘 Levantando Base de Datos (PostgreSQL + pgAdmin)..." -ForegroundColor Gray
try {
    Set-Location ".\postgres"
    docker compose -f postgres-compose.yaml up -d
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Host "`n┌─────────────────────────────────────────────────────┐" -ForegroundColor Red
    Write-Host "│  ❌ ERROR: Falló el despliegue de PostgreSQL/pgAdmin│" -ForegroundColor Red
    Write-Host "│  Revisa la sintaxis del archivo postgres-compose.   │" -ForegroundColor Red
    Write-Host "└─────────────────────────────────────────────────────┘" -ForegroundColor Red
    Set-Location ".."
    Exit 1
}

# 3. Volver a la raíz y entrar a la subcarpeta de pentaho
Write-Host "`n[3/3] 📊 Levantando Pentaho WebSpoon GUI..." -ForegroundColor Gray
try {
    Set-Location "..\pentaho"
    docker compose -f pentaho-compose.yaml up -d
    if ($LASTEXITCODE -ne 0) { throw }
} catch {
    Write-Host "`n┌─────────────────────────────────────────────────────┐" -ForegroundColor Red
    Write-Host "│  ❌ ERROR: Falló el despliegue de Pentaho WebSpoon  │" -ForegroundColor Red
    Write-Host "│  Verifica que el puerto 5800 no esté ocupado.       │" -ForegroundColor Red
    Write-Host "└─────────────────────────────────────────────────────┘" -ForegroundColor Red
    Set-Location ".."
    Exit 1
}

# Volver a la carpeta raíz
Set-Location ".."

# Mensaje final de éxito
Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host "       ✨ ¡TODO EL ENTORNO ESTÁ ENCENDIDO!             " -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

# pgAdmin
Write-Host " 🌐 pgAdmin Panel: " -NoNewline -ForegroundColor White
Write-Host "http://localhost:8081" -ForegroundColor Cyan
Write-Host "    📧 Credenciales: admin@correo.com / admin`n" -ForegroundColor Gray

# Pentaho Spoon
Write-Host " 🚀 Pentaho Spoon: " -NoNewline -ForegroundColor White
Write-Host "http://localhost:5800/spoon/spoon" -ForegroundColor Cyan
Write-Host "    📧 Credenciales: admin / password" -ForegroundColor Gray

Write-Host "-------------------------------------------------------" -ForegroundColor Green
Write-Host " 💡 Servidor Postgres (Host): postgres_db" -ForegroundColor DarkYellow
Write-Host "=======================================================" -ForegroundColor Green