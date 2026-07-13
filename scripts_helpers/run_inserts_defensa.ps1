Clear-Host

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
Center "INSERTANDO DATOS DE DEFENSA" Cyan
Center "=======================================================" Cyan

$container = "postgres_db"
$pgUser = "postgres"
$pgDB = "postgres"
$tmp = "/tmp"
$sqlDir = Resolve-Path "$PSScriptRoot\..\postgres\db_setup"
Set-Location $sqlDir
$sqlFile = "inserts_defensa.sql"

# 1. Verificar contenedor
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
    Center "|  Ejecuta primero el menu opcion 1 (Iniciar entorno) |" Red
    Center "+-----------------------------------------------------+" Red
    Exit 1
}

Write-Host "`n"
# 2. Verificar archivo SQL
Center "[2/4] Verificando archivo SQL..." Gray
try {
    if (-not (Test-Path $sqlFile)) { throw "$sqlFile no encontrado" }
    $fs = [math]::Round((Get-Item $sqlFile).Length / 1KB, 1)
    $lines = (Get-Content $sqlFile).Count
    Center "[+] $sqlFile ($fs KB - $lines lineas)" Green
} catch {
    Write-Host "`n"
    Center "+-----------------------------------------------------+" Red
    Center "|  [!] ERROR: $($_.Exception.Message)" Red
    Center "+-----------------------------------------------------+" Red
    Exit 1
}

Write-Host "`n"
# 3. Confirmar
Center "[3/4] Confirmacion..." Gray
$insertCounts = @{}
$tableOrder = @()
Get-Content $sqlFile | ForEach-Object {
    if ($_ -match "INSERT INTO (\w+)") {
        $t = $matches[1]
        if (-not $insertCounts.ContainsKey($t)) { $tableOrder += $t }
        $insertCounts[$t] += 1
    }
}
$totalInserts = ($insertCounts.Values | Measure-Object -Sum).Sum
$tableSizes = @()
$tableOrder | ForEach-Object { $tableSizes += "$($_): $($insertCounts[$_])" }
Center ($tableSizes -join " | ") DarkGray
$prompt = "Se insertaran $totalInserts registros en $($tableOrder.Count) tablas. Continuar? (y/N)"
$pw = $Host.UI.RawUI.BufferSize.Width
$pp = " " * [math]::Max(0, [math]::Floor(($pw - $prompt.Length) / 2))
Write-Host ""
$resp = Read-Host "$pp$prompt"
if ($resp -ne "y" -and $resp -ne "Y") {
    Center "Cancelado por el usuario." Yellow
    Exit 0
}

Write-Host "`n"
# 4. Ejecutar
Center "[4/4] Ejecutando inserts de defensa..." Gray
try {
    $start = Get-Date
    docker cp "$sqlFile" "${container}:${tmp}/${sqlFile}" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "No se pudo copiar $sqlFile" }

    Write-Host ( " " * [math]::Max(0, [math]::Floor(($Host.UI.RawUI.BufferSize.Width - "Ejecutando... (puede tomar hasta 30s)".Length) / 2)) + "Ejecutando... (puede tomar hasta 30s)" ) -ForegroundColor DarkGray
    $output = docker exec $container psql -U $pgUser -d $pgDB --single-transaction -q -f "${tmp}/${sqlFile}" -v ON_ERROR_STOP=1 2>&1
    if ($LASTEXITCODE -ne 0) { throw ($output -join "`n") }
    docker exec $container rm -f "${tmp}/${sqlFile}" 2>$null | Out-Null
    Center "[+] INSERTS COMPLETADOS" Green
} catch {
    Write-Host "`n"
    Center "+-----------------------------------------------------+" Red
    Center "|  [!] ERROR FATAL: Fallo la ejecucion de los inserts |" Red
    Center "+-----------------------------------------------------+" Red
    if ($output) {
        Write-Host "`n"
        $output | ForEach-Object { Center $_ Red }
    }
    Exit 1
}

# Resumen
Write-Host "`n"
Center "=======================================================" Green
Center "[+] $totalInserts REGISTROS INSERTADOS CON EXITO" Green
Center "=======================================================" Green

Write-Host "`n"
Center "--- SIGUIENTES PASOS ---" Yellow
Center "Ejecutar estas ETLs en Pentaho (en orden):" White
Center "" White
Center "1. DIM_CLIENTE" White
Center "2. DIM_PRODUCTO" White
Center "3. DIM_CONTRATO" White
Center "4. DIM_SINIESTRO" White
Center "5. FACT_EVALUACION_SERVICIO" White
Center "6. FACT_REGISTRO_CONTRATO" White
Center "7. FACT_REGISTRO_SINIESTRO" White

Write-Host "`n"
Center "Datos DB:" White
Center "Servidor: localhost:5432" Cyan
Center "Base: postgres | Usuario: postgres | Clave: postgres" Cyan
Center "Schema: SEGURO_G28310422" Cyan

Write-Host "`n"
$art = @"
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠀⣰⣄⡀⠀⢰⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣿⣿⣷⡾⠟⢿⣿⣿⣿⣥⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣶⣴⣿⣿⣯⠉⠻⣿⡆⠀⢈⣿⣿⢿⣭⣳⣄⣀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠶⣿⣿⣿⢿⡏⣿⡀⠈⠳⢼⠛⣧⠙⢷⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⡿⣿⣟⣧⣾⣷⣿⣖⣈⣿⣿⣿⣷⠄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣾⣿⣷⣿⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣿⣿⣿⣿⣿⣿⢿⡽⢿⣿⣿⣿⡏⣿⣿⣿⠓⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠤⢤⣤⣤⣄⡀⠈⢻⣿⣿⣿⢧⠀⡗⠸⣿⣿⢿⣰⣿⠟⠋⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣤⣶⣶⣾⣿⡄⠀⠌⢻⣿⣿⣿⣷⡄⠹⣇⠈⠐⠊⠀⠀⠈⣡⡼⣻⣿⣿⣦⣢⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠺⣏⠹⡭⠈⣽⣿⣧⣼⢷⣄⡀⠉⠋⣿⠿⠟⢻⠀⠈⠓⠤⠤⠤⠤⠚⢻⣾⣿⣿⣿⣿⣿⣧⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢶⡧⣼⣿⣿⣿⣿⣠⣿⡿⠟⠉⠀⠀⠀⢸⠃⠀⠀⠀⢀⣤⣒⣿⣿⣿⠿⣿⣿⣿⠿⠻⢿⣄⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⡈⠀⠀⣠⢶⠛⢉⣳⣿⡿⢷⣿⣦⣼⣿⡄⠀⠛⢿⣧⠀⠀⠀
⠀⢠⠖⠄⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⡿⣿⠀⠀⠀⠀⠀⢀⡔⠁⢀⣾⣵⣬⣶⣿⣟⡛⣿⣿⣿⣿⣿⢻⠗⢒⠀⢘⣿⣇⠀⠀
⠀⡏⢀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⡟⣐⣿⠀⠀⠀⢀⡤⠊⠀⠀⢸⣿⣿⣿⣿⣟⣯⣿⣿⣿⡝⠿⣿⣾⠷⢲⡀⢀⣿⣿⡀⠀
⢸⠁⡜⠀⠀⠀⠀⠀⠀⠀⠀⠀⢐⢿⣿⣿⡟⠛⣶⣶⡉⠁⠀⠀⠀⠀⠈⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣾⣿⣷⣾⣯⣬⣿⢿⣷⠀
⠘⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠈⢉⣶⣿⣿⣿⣦⣔⢻⡀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢛⣭⣿⢿⣿⠀
⠀⢻⣿⡄⠀⠀⠀⠀⠀⠀⣠⠔⢿⣿⣿⣋⣭⢹⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⢸⣿⡆
⠀⠈⢻⣿⣦⡀⠀⠀⠀⠀⠑⢲⣾⣿⣿⣿⣿⣾⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠁
⠀⠀⠀⠙⠿⣿⣶⣤⣀⣠⣤⣾⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠀
⠀⠀⠀⠀⠀⠀⠉⠛⠛⠛⠛⠁⠈⢻⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠁⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⡟⢇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡞⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠀⠉⠉⠉⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠉⠉⠉⠀⠀⠀⠀⠉⠉⠉⠁⠀⠀⠀⠀`n⠀⠀⠀⠀⠀⠀⠀⠀⠀
"@
$artLines = $art -split "`n" | ForEach-Object { $_.Trim("`r") } | Where-Object { $_.Length -gt 0 }
if ($artLines) {
    $maxArtWidth = ($artLines | ForEach-Object { $_.Length }) | Sort-Object -Descending | Select-Object -First 1
    $termWidth = $Host.UI.RawUI.BufferSize.Width
    $pad = " " * [math]::Max(0, [math]::Floor(($termWidth - $maxArtWidth) / 2))
    foreach ($line in $artLines) { Write-Host "$pad$line" -ForegroundColor Red }
}

Center "Ingresando a Memento" -ForegroundColor Red