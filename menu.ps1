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
    Center "=======================================================" Cyan
    Center "MENU PROY" Yellow
    Center "=======================================================" Cyan

    $opts = @(
        "[1]  Iniciar entorno",
        "[2]  Detener entorno",
        "[3]  Hidratar base de datos",
        "[4]  Salir"
    )
    $maxLen = ($opts | ForEach-Object { $_.Length }) | Sort-Object -Descending | Select-Object -First 1
    Center ""
    foreach ($opt in $opts) {
        Center $opt.PadRight($maxLen) White
    }
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
            $hidratePath = "$PSScriptRoot\postgres\db_setup\run_hidratation.ps1"
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
} while ($choice -ne '4')
