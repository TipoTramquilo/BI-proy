Clear-Host

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "        MENU PRINCIPAL - ENTORNO ANALITICO             " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

do {
    Write-Host "`n+-----------------------------------------+" -ForegroundColor Cyan
    Write-Host "|          SELECCIONA UNA OPCION            |" -ForegroundColor Cyan
    Write-Host "+-----------------------------------------+" -ForegroundColor Cyan
    Write-Host "|  1) Iniciar entorno                      |" -ForegroundColor White
    Write-Host "|  2) Detener entorno                      |" -ForegroundColor White
    Write-Host "|  3) Hidratar base de datos               |" -ForegroundColor White
    Write-Host "|  4) Salir                                |" -ForegroundColor White
    Write-Host "+-----------------------------------------+" -ForegroundColor Cyan

    $choice = Read-Host "`nOpcion"

    switch ($choice) {
        '1' {
            Clear-Host
            & "$PSScriptRoot\run.ps1"
            Write-Host "`nPresiona ENTER para volver al menu..."
            $null = Read-Host
            Clear-Host
        }
        '2' {
            Clear-Host
            & "$PSScriptRoot\stop.ps1"
            Clear-Host
        }
        '3' {
            Clear-Host
            $hidratePath = "$PSScriptRoot\postgres\db_setup\run_hidratation.ps1"
            if (Test-Path -LiteralPath $hidratePath) {
                & $hidratePath
            } else {
                Write-Host "+-----------------------------------------+" -ForegroundColor Red
                Write-Host "|  No se encontro el script de hidratacion.|" -ForegroundColor Red
                Write-Host "+-----------------------------------------+" -ForegroundColor Red
            }
            Write-Host "`nPresiona ENTER para volver al menu..."
            $null = Read-Host
            Clear-Host
        }
        '4' {
            Write-Host "`nHasta luego!" -ForegroundColor Gray
        }
        default {
            Write-Host "`nOpcion invalida. Intenta de nuevo." -ForegroundColor Red
            Write-Host "`nPresiona ENTER para continuar..."
            $null = Read-Host
            Clear-Host
        }
    }
} while ($choice -ne '4')
