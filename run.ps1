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

function Center-Color($left, $lColor, $right, $rColor) {
    $w = $Host.UI.RawUI.BufferSize.Width
    $full = $left + $right
    $p = " " * [math]::Max(0, [math]::Floor(($w - $full.Length) / 2))
    Write-Host "$p$left" -NoNewline -ForegroundColor $lColor
    Write-Host $right -ForegroundColor $rColor
}

Center "=======================================================" Cyan
Center "🚀 INICIANDO ENTORNO" Yellow
Center "=======================================================" Cyan

Center ""
Center "[1/3] 🌐 Verificando red compartida..." Gray
try {
    $networkCheck = docker network ls --filter name=^red_datos$ --format "{{.Name}}"
    if (-not $networkCheck) {
        Center "  ⚠️  La red 'red_datos' no existe. Creandola ahora..." Yellow
        docker network create red_datos | Out-Null
        Center "  ✅ Red 'red_datos' creada con exito." Green
    } else {
        Center "  ✅ Red 'red_datos' detectada y lista para usar." Green
    }
} catch {
    Center ""
    Center "┌─────────────────────────────────────────────────────┐" Red
    Center "│  ❌ ERROR: No se pudo verificar o crear la red.      │" Red
    Center "│  Asegurate de que Docker Desktop este encendido.    │" Red
    Center "└─────────────────────────────────────────────────────┘" Red
    Exit 1
}

Center ""
Center "[2/3] 🐘 Levantando Base de Datos (PostgreSQL + pgAdmin)..." Gray
try {
    Set-Location ".\postgres"
    docker compose -f postgres-compose.yaml up -d
    if ($LASTEXITCODE -ne 0) { throw }
    Center "[+] PostgreSQL + pgAdmin levantados correctamente." Green
} catch {
    Center ""
    Center "┌─────────────────────────────────────────────────────┐" Red
    Center "│  ❌ ERROR: Fallo el despliegue de PostgreSQL/pgAdmin │" Red
    Center "│  Revisa la sintaxis del archivo postgres-compose.   │" Red
    Center "└─────────────────────────────────────────────────────┘" Red
    Set-Location ".."
    Exit 1
}

Center ""
Center "[3/3] 📊 Levantando Pentaho WebSpoon GUI..." Gray
try {
    Set-Location "..\pentaho"
    docker compose -f pentaho-compose.yaml up -d
    if ($LASTEXITCODE -ne 0) { throw }
    Center "[+] Pentaho WebSpoon levantado correctamente." Green
} catch {
    Center ""
    Center "┌─────────────────────────────────────────────────────┐" Red
    Center "│  ❌ ERROR: Fallo el despliegue de Pentaho WebSpoon   │" Red
    Center "│  Verifica que el puerto 5800 no este ocupado.       │" Red
    Center "└─────────────────────────────────────────────────────┘" Red
    Set-Location ".."
    Exit 1
}

Set-Location ".."

Center ""
Center "=======================================================" Green
Center "✨  ¡TODO EL ENTORNO ESTA ENCENDIDO!" Green
Center "=======================================================" Green

Center ""
Center-Color "🌐 pgAdmin Panel:  " White "http://localhost:8081" Cyan
Center-Color "📧 Credenciales:   " Gray "admin@correo.com / admin" Gray
Center ""
Center-Color "🚀 Pentaho Spoon:  " White "http://localhost:5800/spoon/spoon" Cyan
Center-Color "📧 Credenciales:   " Gray "admin / password" Gray

Center ""
Center "-------------------------------------------------------" Green
Center "💡 Servidor Postgres (Host): postgres_db" DarkYellow
Center "=======================================================" Green
