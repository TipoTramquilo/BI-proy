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

do {
    Clear-Host
    Write-Host ""
    Write-Host ""
    Write-Host ""
    $banner = @"
▄████▄ ▄▄▄▄  ▄▄▄▄  ▄▄▄▄   ▄▄▄   ▄▄▄   ▄▄▄▄ ▄▄ ▄▄   ▄█████  ▄▄▄  ▄▄▄▄▄ ▄▄▄▄▄▄ 
██▄▄██ ██▄█▀ ██▄█▀ ██▄█▄ ██▀██ ██▀██ ██▀▀▀ ██▄██   ▀▀▀▄▄▄ ██▀██ ██▄▄    ██   
██  ██ ██    ██    ██ ██ ▀███▀ ██▀██ ▀████ ██ ██   █████▀ ▀███▀ ██      ██  
"@
    $bannerLines = $banner -split "`n" | ForEach-Object { $_.TrimEnd("`r") } | Where-Object { $_.Length -gt 0 }
    $bannerWidth = ($bannerLines | ForEach-Object { $_.Length }) | Sort-Object -Descending | Select-Object -First 1
    $bannerPad = " " * [math]::Max(0, [math]::Floor(($Host.UI.RawUI.BufferSize.Width - $bannerWidth) / 2))
    foreach ($line in $bannerLines) { Write-Host "$bannerPad$line" -ForegroundColor Cyan }
    Write-Host ""
    Center "=======================================================" Cyan
    Center "MENU PRINCIPAL" Yellow
    Center "=======================================================" Cyan

    Center ""
    Center "" Gray
    Center "--- ENTORNO ---" DarkCyan
    Center "[1]  Iniciar entorno" Green
    Center "[2]  Detener entorno" DarkYellow
    Center "" Gray
    Center "--- DATOS ---" DarkCyan
    Center "[3]  Generar e Hidratar BD" Yellow
    Center "[4]  Ejecutar inserts defensa" Magenta
    Center "" Gray
    Center "--- MANTENIMIENTO ---" DarkCyan
    Center "[5]  Limpiar DB schemas" DarkRed
    Center "" Gray
    Center "[6]  Salir" Gray
    Center ""
    Center "=======================================================" Green

    $prompt = "Opcion"
    $pw = $Host.UI.RawUI.BufferSize.Width
    $pp = " " * [math]::Max(0, [math]::Floor(($pw - $prompt.Length) / 2))
    $choice = Read-Host "`n$pp$prompt"

    switch ($choice) {
        '1' {
            Clear-Host
            & "$PSScriptRoot\run.ps1"
            Center "Presiona ENTER para volver al menu..." Gray
            $null = Read-Host
        }
        '2' {
            Clear-Host
            & "$PSScriptRoot\stop.ps1"
        }
        '3' {
            Clear-Host
            $hidratePath = "$PSScriptRoot\run_hidratation.ps1"
            if (Test-Path -LiteralPath $hidratePath) {
                & $hidratePath
            } else {
                Center ""
                Center "=======================================================" Red
                Center "[!]  No se encontro el script de hidratacion" Red
                Center "=======================================================" Red
            }
            Center "Presiona ENTER para volver al menu..." Gray
            $null = Read-Host
        }
        '4' {
            Clear-Host
            $defensaPath = "$PSScriptRoot\run_inserts_defensa.ps1"
            if (Test-Path -LiteralPath $defensaPath) {
                & $defensaPath
            } else {
                Center ""
                Center "=======================================================" Red
                Center "[!]  No se encontro el script de inserts de defensa" Red
                Center "=======================================================" Red
            }
            Center "Presiona ENTER para volver al menu..." Gray
            $null = Read-Host
        }
        '5' {
            Clear-Host
            $cleanPath = "$PSScriptRoot\clean_schemas.ps1"
            if (Test-Path -LiteralPath $cleanPath) {
                & $cleanPath
            } else {
                Center ""
                Center "=======================================================" Red
                Center "[!]  No se encontro el script de limpieza" Red
                Center "=======================================================" Red
            }
        }
        '6' {
            Center ""
            Center "Hasta luego!" Yellow
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
} while ($choice -ne '6')
