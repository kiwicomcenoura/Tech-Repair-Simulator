param(
    [Parameter(Mandatory)][string]$GodotConsole,
    [Parameter(Mandatory)][string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$GodotConsole = (Resolve-Path -LiteralPath $GodotConsole).Path
$version = & $GodotConsole --version
if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2\.stable\.') {
    throw 'Use o editor Godot 4.7.2 estável e os templates da mesma versão.'
}

$game = Split-Path -Parent $PSScriptRoot
$output = (New-Item -ItemType Directory -Force -Path $OutputDirectory).FullName
$gameExe = Join-Path $output 'Tech Repair Simulator.exe'
$launcherExe = Join-Path $output 'Tech-Repair-Simulator-Launcher-Windows-x64.exe'
$gameZip = Join-Path $output 'Tech-Repair-Simulator-Windows-x64.zip'

function Export-Windows([string]$Project, [string]$Destination) {
    & $GodotConsole --headless --path $Project --import
    if ($LASTEXITCODE -ne 0) { throw "Importação falhou em $Project" }
    & $GodotConsole --headless --path $Project --export-release Windows $Destination
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        throw "Falha ao exportar $Project"
    }
}

Export-Windows $game $gameExe
Export-Windows $PSScriptRoot $launcherExe
Compress-Archive -LiteralPath $gameExe -DestinationPath $gameZip -Force
Set-Content -LiteralPath "$gameZip.sha256" -Encoding ASCII -Value (
    '{0}  {1}' -f (Get-FileHash -LiteralPath $gameZip -Algorithm SHA256).Hash.ToLowerInvariant(), (Split-Path -Leaf $gameZip)
)
