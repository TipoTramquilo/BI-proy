Clear-Host

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "        STOP - DETENER ENTORNO                         " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

function Show-Menu {
    Write-Host "`n+-----------------------------------------+" -ForegroundColor Cyan
    Write-Host "|        SELECCIONA QUE DETENER            |" -ForegroundColor Cyan
    Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
    Write-Host "|  1) PostgreSQL + pgAdmin                 |" -ForegroundColor White
    Write-Host "|  2) Pentaho WebSpoon                     |" -ForegroundColor White
    Write-Host "|  3) Todos los contenedores               |" -ForegroundColor White
    Write-Host "|  4) Salir                                |" -ForegroundColor White
    Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
}

function Ask-Volumes {
    Write-Host "`n+-----------------------------------------+" -ForegroundColor Yellow
    Write-Host "|  Eliminar tambien los volumenes de datos? |" -ForegroundColor Yellow
    Write-Host "|  (Borrara toda la informacion persistente)|" -ForegroundColor Yellow
    Write-Host "+-----------------------------------------+" -ForegroundColor Yellow
    $response = Read-Host "`nEscribe S (Si) o N (No)"
    return ($response -eq 'S' -or $response -eq 's')
}

function Stop-Containers {
    param(
        [string]$ComposeFile,
        [string]$DisplayName
    )

    Write-Host "`n[..] Deteniendo $DisplayName..." -ForegroundColor Gray
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
        Write-Host "      [+] $DisplayName detenido correctamente." -ForegroundColor Green
    } catch {
        Write-Host "      [!] ERROR al detener $DisplayName." -ForegroundColor Red
    } finally {
        Pop-Location
    }
}

do {
    Show-Menu
    $choice = Read-Host "`nOpcion"

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
            Write-Host "`nSaliendo..." -ForegroundColor Gray
        }
        default {
            Write-Host "`nOpcion invalida. Intenta de nuevo." -ForegroundColor Red
        }
    }

    if ($choice -ne '4') {
        Write-Host "`nPresiona ENTER para continuar..."
        $null = Read-Host
        Clear-Host
    }
} while ($choice -ne '4')
