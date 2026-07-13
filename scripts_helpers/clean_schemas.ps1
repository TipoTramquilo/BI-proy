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

function Show-Menu {
    Clear-Host
    Center "=======================================================" Cyan
    Center "LIMPIEZA DE ESQUEMAS" Yellow
    Center "=======================================================" Cyan

    $opts = @(
        "[1]  Limpiar toda la BD (OLTP - DW)",
        "[2]  Limpiar solo el DW",
        "[3]  Volver"
    )
    $maxLen = ($opts | ForEach-Object { $_.Length }) | Sort-Object -Descending | Select-Object -First 1
    Center ""
    foreach ($opt in $opts) {
        Center $opt.PadRight($maxLen) White
    }
    Center ""
    Center "=======================================================" Green
}

function Run-Truncate {
    param($Schemas, $Label)

    $container = "postgres_db"
    $pgUser = "postgres"
    $pgDB = "postgres"

    Write-Host "`n"
    Center "[1/3] Verificando contenedor PostgreSQL..." Gray
    try {
        $running = docker ps --filter "name=$container" --filter "status=running" --format "{{.Names}}" 2>$null
        if (-not $running) { throw }
        Center "[+] Contenedor '$container' detectado." Green
    } catch {
        Center "[!] ERROR: Contenedor PostgreSQL no encontrado." Red
        return
    }

    Write-Host "`n"
    Center "[2/3] Confirmacion..." Gray
    $prompt = "Esto borrara TODOS los datos en $Label. Continuar? (y/N)"
    $pw = $Host.UI.RawUI.BufferSize.Width
    $pp = " " * [math]::Max(0, [math]::Floor(($pw - $prompt.Length) / 2))
    $resp = Read-Host "`n$pp$prompt"
    if ($resp -ne "y" -and $resp -ne "Y") {
        Center "Cancelado por el usuario." Yellow
        return
    }

    Write-Host "`n"
    Center "[3/3] Truncando tablas..." Gray
    foreach ($schema in $Schemas) {
        $tables = docker exec $container psql -U $pgUser -d $pgDB -t -A -c "SELECT table_name FROM information_schema.tables WHERE lower(table_schema) = lower('$schema') AND table_type = 'BASE TABLE' ORDER BY table_name;" 2>$null
        if (-not $tables) {
            Center "[!] No hay tablas en $schema" Yellow
            continue
        }
        $tableList = $tables -split "`n" | Where-Object { $_.Trim() -ne "" }
        Center "   $schema ($($tableList.Count) tablas)" White
        $truncateSql = ($tableList | ForEach-Object { "TRUNCATE TABLE $schema.$_ CASCADE;" }) -join " "
        $output = docker exec $container psql -U $pgUser -d $pgDB -c "$truncateSql" -v ON_ERROR_STOP=1 2>&1
        if ($LASTEXITCODE -ne 0) {
            Center "[!] ERROR al truncar $schema" Red
        } else {
            Center "[+] $schema limpiado correctamente." Green
        }
    }
    Write-Host "`n"
    Center "LIMPIEZA COMPLETADA" Green
}

do {
    Show-Menu
    $prompt = "Opcion"
    $pw = $Host.UI.RawUI.BufferSize.Width
    $pp = " " * [math]::Max(0, [math]::Floor(($pw - $prompt.Length) / 2))
    $choice = Read-Host "`n$pp$prompt"

    switch ($choice) {
        '1' {
            Run-Truncate -Schemas @("SEGURO_G28310422", "SEGURO_DW_G28310422") -Label "OLTP + DW"
            Center "Presiona ENTER para volver..." Gray
            $null = Read-Host
        }
        '2' {
            Run-Truncate -Schemas @("SEGURO_DW_G28310422") -Label "DW"
            Center "Presiona ENTER para volver..." Gray
            $null = Read-Host
        }
        '3' {
            Center "`nVolviendo..." Yellow
        }
        default {
            Center ""
            Center "=======================================================" Red
            Center "[!]  Opcion invalida. Intenta de nuevo." Red
            Center "=======================================================" Red
            Center "Presiona ENTER para continuar..." Gray
            $null = Read-Host
        }
    }
} while ($choice -ne '3')
