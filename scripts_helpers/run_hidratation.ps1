# Limpiar la pantalla para iniciar el proceso de forma limpia
Clear-Host

# Configurar tamano de consola para centrado perfecto
try {
    $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(130, 55)
    $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(130, 9999)
} catch { }

function Center($t, $c = "White") {
    $w = $Host.UI.RawUI.BufferSize.Width
    $p = " " * [math]::Max(0, [math]::Floor(($w - $t.Length) / 2))
    Write-Host "$p$t" -ForegroundColor $c
}

Center "=======================================================" Cyan
Center "HIDRATANDO BASE DE DATOS - SEGUROS" Cyan
Center "=======================================================" Cyan

$container = "postgres_db"
$pgUser = "postgres"
$pgDB = "postgres"
$schema = "SEGURO_G28310422"
$schemaDW = "SEGURO_DW_G28310422"
$tmp = "/tmp"
$sqlDir = Resolve-Path "$PSScriptRoot\..\postgres\db_setup"
Set-Location $sqlDir

# 1. Verificar contenedor Docker
Write-Host "`n"
Center "[1/4] Verificando contenedor PostgreSQL..." Gray
try {
    $running = docker ps --filter "name=$container" --filter "status=running" --format "{{.Names}}" 2>$null
    if (-not $running) { throw "Contenedor no detectado" }
    Center "[+] Contenedor '$container' detectado y corriendo." Green
} catch {
    Write-Host "`n"
    Center "+-----------------------------------------------------+" Red
    Center "|  [!] ERROR: Contenedor PostgreSQL no encontrado.    |" Red
    Center "|  Ejecuta primero: docker-compose up -d              |" Red
    Center "+-----------------------------------------------------+" Red
    Exit 1
}

# 2. Verificar archivos SQL
Write-Host "`n"
Center "[2/4] Verificando archivos SQL..." Gray
try {
    if (-not (Test-Path "create_tables.sql")) { throw "create_tables.sql no encontrado" }
    if (-not (Test-Path "hidrate.sql")) { throw "hidrate.sql no encontrado" }
    $ts = [math]::Round((Get-Item "create_tables.sql").Length / 1KB, 1)
    $hs = [math]::Round((Get-Item "hidrate.sql").Length / 1KB, 1)
    $hl = (Get-Content "hidrate.sql").Count
    Center "[+] create_tables.sql ($ts KB - 12 tablas)" Green
    Center "[+] hidrate.sql ($hs KB - $hl lineas)" Green
} catch {
    Write-Host "`n"
    Center "+-----------------------------------------------------+" Red
    Center "|  [!] ERROR: $($_.Exception.Message)" Red
    Center "+-----------------------------------------------------+" Red
    Exit 1
}

# 3. Confirmar
Write-Host "`n"
Center "[3/4] Confirmacion..." Gray
$schemaExists = docker exec $container psql -U $pgUser -d $pgDB -t -A -c "SELECT COUNT(*) FROM information_schema.schemata WHERE lower(schema_name) = lower('$schema');" 2>$null
if ($schemaExists -and [int]$schemaExists -ge 1) {
    Center "[!] AVISO: El schema '$schema' (Relacional) YA EXISTE en la base de datos." Red
    Center "Se borrara y se creara de nuevo (DROP SCHEMA ... CASCADE)." Red
}

$schemaDWExists = docker exec $container psql -U $pgUser -d $pgDB -t -A -c "SELECT COUNT(*) FROM information_schema.schemata WHERE lower(schema_name) = lower('$schemaDW');" 2>$null
if ($schemaDWExists -and [int]$schemaDWExists -ge 1) {
    Center "[!] AVISO: El schema '$schemaDW' (Data Warehouse) YA EXISTE en la base de datos." Red
    Center "Se borrara y se creara de nuevo (DROP SCHEMA ... CASCADE)." Red
}
$prompt = "Desea continuar con la creacion de tablas e hidratacion? (y/N)"
$pw = $Host.UI.RawUI.BufferSize.Width
$pp = " " * [math]::Max(0, [math]::Floor(($pw - $prompt.Length) / 2))
Write-Host ""
$resp = Read-Host "$pp$prompt"
if ($resp -ne "y" -and $resp -ne "Y") {
    Center "Cancelado por el usuario." Yellow
    Exit 0
}

# 4. Ejecutar scripts
Write-Host "`n"
Center "[4/4] Ejecutando scripts de hidratacion..." Gray

function Run-Script($file, $label) {
    Write-Host "`n"
    Center "Ejecutando $label ..." DarkGray
    try {
        $start = Get-Date
        docker cp "$file" "${container}:${tmp}/${file}" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "No se pudo copiar $file" }

        $output = docker exec $container psql -U $pgUser -d $pgDB -f "${tmp}/${file}" -v ON_ERROR_STOP=1 2>&1
        if ($LASTEXITCODE -ne 0) { throw $output }

        docker exec $container rm -f "${tmp}/${file}" 2>$null | Out-Null
        $elapsed = (Get-Date) - $start
        $secs = [math]::Round($elapsed.TotalSeconds, 2)
        Center "[+] $label completado [${secs}s]" Green
    } catch {
        Write-Host "`n"
        Center "+-----------------------------------------------------+" Red
        Center "|  [!] ERROR FATAL: Fallo $label                      |" Red
        Center "|  No se creo NADA - Schema eliminado                |" Red
        Center "|  Corrige el error y vuelve a ejecutar              |" Red
        Center "+-----------------------------------------------------+" Red

        Write-Host "`n"
        Center "Limpiando esquema $schema..." DarkGray
        docker exec $container psql -U $pgUser -d $pgDB -c "DROP SCHEMA IF EXISTS $schema CASCADE; DROP SCHEMA IF EXISTS $schemaDW CASCADE;" -q 2>$null | Out-Null
        Center "[+] Esquemas eliminados - No quedo nada (Relacional + DW)" Yellow
        Exit 1
    }
}

Run-Script "create_tables.sql" "Creacion de tablas"
Run-Script "hidrate.sql" "Insercion de datos"

# Mostrar conteos finales
Write-Host "`n"
Center "=======================================================" Green
Center "[+] HIDRATACION COMPLETADA CON EXITO" Green
Center "=======================================================" Green

# Descubrir tablas relacionales dinamicamente
$tableQuery = "SELECT table_name FROM information_schema.tables WHERE lower(table_schema) = lower('$schema') AND table_type = 'BASE TABLE' ORDER BY table_name"
$tableResult = docker exec $container psql -U $pgUser -d $pgDB -t -A -c "$tableQuery" 2>$null
$tables = $tableResult -split "`n" | Where-Object { $_.Trim() -ne "" }

if (-not $tables) {
    Center "[!] ERROR: No se encontraron tablas en el schema $schema" Red
    Exit 1
}

# Descubrir tablas DW dinamicamente
$dwQuery = "SELECT table_name FROM information_schema.tables WHERE lower(table_schema) = lower('$schemaDW') AND table_type = 'BASE TABLE' ORDER BY table_name"
$dwResult = docker exec $container psql -U $pgUser -d $pgDB -t -A -c "$dwQuery" 2>$null
$allDwTables = $dwResult -split "`n" | Where-Object { $_.Trim() -ne "" }
$dimensiones = $allDwTables | Where-Object { $_ -like 'DIM_*' }
$factTables = $allDwTables | Where-Object { $_ -like 'FACT_*' }

# --- Mostrar conteos relacionales + verificar que no esten vacias ---
$totalRows = 0
$maxNameLen = ($tables | ForEach-Object { $_.Length }) | Sort-Object -Descending | Select-Object -First 1
$emptyTables = @()

foreach ($t in $tables) {
    $result = docker exec $container psql -U $pgUser -d $pgDB -t -A -c "SELECT COUNT(*) FROM $schema.$t;" 2>$null
    $c = [int]$result
    $totalRows += $c
    if ($c -eq 0) { $emptyTables += $t }
    Center ("{0,-$($maxNameLen+2)}: {1,5}" -f $t, $c) White
}

Center "-------------------------------------------------------" Green
Center ("{0,-$($maxNameLen+2)}: {1,5}" -f "TOTAL REGISTROS", $totalRows) Yellow
Center "=======================================================" Green

if ($emptyTables) {
    Write-Host "`n"
    Center "+-----------------------------------------------------+" Red
    Center "|  [!] ERROR: Las siguientes tablas quedaron VACIAS:  |" Red
    foreach ($et in $emptyTables) {
        Center "|       - $et" Red
    }
    Center "|  Revise el script hidrate.sql para posibles errores |" Red
    Center "+-----------------------------------------------------+" Red
    Exit 1
}

# --- Mostrar estructura DW ---
Write-Host "`n"
Center "--- DATA WAREHOUSE (estructura creada, sin datos) ---" Yellow

if ($dimensiones -or $factTables) {
    $dwMaxLen = (($dimensiones + $factTables) | ForEach-Object { $_.Length }) | Sort-Object -Descending | Select-Object -First 1
    Center "Dimensiones:" Cyan
    foreach ($d in $dimensiones) {
        Center ("  {0,-$($dwMaxLen+2)}: (vacia)" -f $d) Gray
    }
    Center "Fact Tables:" Cyan
    foreach ($f in $factTables) {
        Center ("  {0,-$($dwMaxLen+2)}: (vacia)" -f $f) Gray
    }
} else {
    Center "[!] No se encontraron tablas en el schema $schemaDW" Yellow
}

Write-Host "`n"
Center "Datos DB:" White
Center "Servidor: localhost:5432" Cyan
Center "Base: postgres | Usuario: postgres | Clave: postgres" Cyan
Center "Schema: $schema" Cyan
Center "Schema DW: $schemaDW" Cyan
Write-Host "`n"
$art = "`n⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⡿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣽⣶⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⡿⠋⢁⠀⢂⣚⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⡿⠁⠠⢢⣐⡆⢸⣷⡈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣏⣿⡿⡿⣡⠞⣴⣾⣿⣿⣧⠻⠁⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢼⣿⣎⣿⢏⣿⣳⣿⡿⣋⣹⠏⠀⠔⠈⣶⣿⣿⢿⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⣃⣀⣀⣀⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣾⣧⣿⣷⣟⣡⣴⣿⡿⠖⠚⠂⠳⠙⢻⣳⣿⡇⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⡙⣿⡿⠛⠿⣿⢿⣃⡠⠄⠉⣷⠀⢸⠘⣿⣆⡅⣾⣿⣿⣿⣿⣿⣿⣿⣿⣯⣽⠖⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣷⡄⣐⣤⣚⣿⢳⠀⠄⣹⠀⣼⢾⣿⣛⣵⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠁⠀⠀⠀⢀⣀⣀⡤⠶⢒⣒⣡⣤⣤⣄⡀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣻⣞⣡⠴⠋⠁⠈⠆⢀⢸⡀⣏⡟⡍⣿⣿⣿⣿⣿⠿⠿⠿⠛⠁⠀⠀⣠⠤⣶⠯⢛⣭⣴⣶⣿⣿⣿⣿⣿⣿⣿⡆
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣯⡻⣟⠿⠟⢀⠊⢀⠘⣾⣿⠑⣌⢿⠿⠿⠿⠶⠄⠀⠀⣀⢤⢖⣩⠶⣋⣵⣿⣿⣿⣿⣿⣿⣿⣿⣟⣿⣿⣿⡇
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⢿⣷⣿⠀⠀⡀⠈⢰⣾⣿⣏⡀⢿⠸⣶⡀⠀⠀⣀⣰⢾⢱⣿⠎⣁⣾⣿⣿⣿⣿⣿⣿⣷⣿⡿⣿⣿⣿⢿⡿⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⣧⣴⣶⣿⡿⣿⢏⣾⡇⢘⣼⣷⣫⣶⣫⣟⣥⡾⢛⣥⣾⣿⣿⣿⣿⣿⣽⣿⣻⣿⣿⣿⣿⣿⣻⡿⢡⠁
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣟⣯⣼⣛⣿⠿⢷⣾⣿⠟⣡⢞⣼⣿⢋⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⣿⣿⣷⡿⣿⣿⣡⠇⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣴⣶⣿⣿⣿⣷⣿⠟⣉⣤⣶⡿⠟⢁⣾⣿⣿⠟⣱⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣿⣿⣾⣿⢛⡴⠋⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣤⣴⣒⣶⣶⣶⢞⣿⣾⡟⣋⣡⣿⣿⡿⠿⢛⣛⣉⣥⣴⣦⣻⢿⣿⢋⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢾⣿⡟⣡⠟⠁⠀⠀⠀
⠀⠀⠀⣀⣤⣶⣿⠿⣲⠿⣅⡽⢋⢭⣾⢭⣾⣿⡿⠿⠛⢉⣡⣤⡴⡞⣏⣻⠭⠏⠐⠒⠫⢟⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣯⡿⣋⡴⠋⠀⠀⠀⠀⠀
⣀⡤⠾⠯⠽⣽⣬⣽⣋⣱⡞⣘⣼⣿⣷⣈⣭⡵⠒⠖⠛⠻⠭⣕⣋⠉⠁⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣋⡴⠋⠀⠀⠀⠀⠀⠀⠀
⠳⣏⡿⣿⣿⣶⣶⣦⣭⣽⣓⣻⣷⡧⠟⠫⠎⣼⠀⠀⠀⠀⠀⠀⠈⠉⠓⠒⠤⣀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⣋⡶⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠙⠺⢽⣿⢿⣿⣿⡿⠟⠉⠀⠀⠀⢀⣶⣟⣆⣀⣀⣀⣀⣀⠀⠀⠀⠀⢀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢟⡭⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣠⣾⠟⠋⠁⠀⠀⠀⠀⠀⢀⣸⡟⣿⣮⣧⣭⣶⣭⣍⣙⣫⣓⣦⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⣠⣴⡟⠀⠀⠀⠀⠀⢀⣠⡴⢞⢫⠔⣿⣶⣝⣿⡿⠻⠛⣫⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢀⣼⣿⣿⡇⠀⠀⣀⣤⠞⡭⣑⡚⢬⢃⣮⣿⣿⢟⢫⡙⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀`n"
$artLines = $art -split "`n" | ForEach-Object { $_.Trim("`r") } | Where-Object { $_.Length -gt 0 }
$maxArtWidth = ($artLines | ForEach-Object { $_.Length }) | Sort-Object -Descending | Select-Object -First 1
$termWidth = $Host.UI.RawUI.BufferSize.Width
$pad = " " * [math]::Max(0, [math]::Floor(($termWidth - $maxArtWidth) / 2))
foreach ($line in $artLines) { Write-Host "$pad$line" -ForegroundColor Magenta }

$msg1 = "Preparate para un nivel de poder de"
$msg2 = "$totalRows"
$msg3 = "ARCHIVOS"
$p1 = " " * [math]::Max(0, [math]::Floor(($termWidth - $msg1.Length) / 2))
$p2 = " " * [math]::Max(0, [math]::Floor(($termWidth - $msg2.Length) / 2))
$p3 = " " * [math]::Max(0, [math]::Floor(($termWidth - $msg3.Length) / 2))
Write-Host "`n"
Write-Host "$p1$msg1" -ForegroundColor Yellow
Write-Host "$p2$msg2" -ForegroundColor Cyan
Write-Host "$p3$msg3" -ForegroundColor Yellow
Write-Host ""