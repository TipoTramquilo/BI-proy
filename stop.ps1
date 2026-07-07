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
    Center "STOP - DETENER ENTORNO" Yellow
    Center "=======================================================" Cyan

    $opts = @(
        "[1]  PostgreSQL + pgAdmin",
        "[2]  Pentaho WebSpoon",
        "[3]  Todos los contenedores",
        "[4]  Salir"
    )
    $maxLen = ($opts | ForEach-Object { $_.Length }) | Sort-Object -Descending | Select-Object -First 1
    Center ""
    foreach ($opt in $opts) {
        Center $opt.PadRight($maxLen) White
    }
    Center ""
    Center "=======================================================" Green
}

function Ask-Volumes {
    Center ""
    Center "=======================================================" Red
    Center "[!]  AVISO" Red
    Center "Eliminar tambien los volumenes de datos?" Red
    Center "(Borrara toda la informacion persistente)" Red
    Center "=======================================================" Red
    $prompt = "(s/n)"
    $pw = $Host.UI.RawUI.BufferSize.Width
    $pp = " " * [math]::Max(0, [math]::Floor(($pw - $prompt.Length) / 2))
    $response = Read-Host "$pp$prompt"
    return ($response -eq 'S' -or $response -eq 's')
}

function Stop-Containers {
    param(
        [string]$ComposeFile,
        [string]$DisplayName
    )

    Center "[..]  Deteniendo $DisplayName..." Gray
    try {
        $composePath = Join-Path -Path $PSScriptRoot -ChildPath $ComposeFile
        $projectDir = Split-Path -Path $composePath -Parent
        $composeFileName = Split-Path -Path $composePath -Leaf

        Push-Location -LiteralPath $projectDir
        $removeVolumes = Ask-Volumes
        if ($removeVolumes) {
            docker compose -f $composeFileName down -v
        } else {
            docker compose -f $composeFileName down
        }
        if ($LASTEXITCODE -ne 0) { throw }
        Center "[+]  $DisplayName detenido correctamente." Green
    } catch {
        Center "[!]  ERROR al detener $DisplayName." Red
    } finally {
        Pop-Location
    }
}

do {
    Show-Menu
    $prompt = "Opcion"
    $pw = $Host.UI.RawUI.BufferSize.Width
    $pp = " " * [math]::Max(0, [math]::Floor(($pw - $prompt.Length) / 2))
    $choice = Read-Host "`n$pp$prompt"

    switch ($choice) {
        '1' {
            Stop-Containers -ComposeFile "postgres\postgres-compose.yaml" -DisplayName "PostgreSQL + pgAdmin"
        }
        '2' {
            Stop-Containers -ComposeFile "pentaho\pentaho-compose.yaml" -DisplayName "Pentaho WebSpoon"
        }
        '3' {
            Stop-Containers -ComposeFile "postgres\postgres-compose.yaml" -DisplayName "PostgreSQL + pgAdmin"
            Stop-Containers -ComposeFile "pentaho\pentaho-compose.yaml" -DisplayName "Pentaho WebSpoon"
        }
        '4' {
            Center "`nSaliendo..." Yellow
        }
        default {
            Center ""
            Center "=======================================================" Red
            Center "[!]  Opcion invalida. Intenta de nuevo." Red
            Center "=======================================================" Red
        }
    }

    if ($choice -ne '4') {
        Center "Presiona ENTER para continuar..." Gray
        $null = Read-Host
    }
} while ($choice -ne '4')
