param([string]$BlenderExe = '')
$ErrorActionPreference = 'Stop'
if (-not $BlenderExe) {
    $app = Get-Command blender -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $app) { throw 'Blender not found on PATH. Supply the existing executable with -BlenderExe.' }
    $BlenderExe = $app.Source
}
if (-not (Test-Path -LiteralPath $BlenderExe -PathType Leaf)) { throw 'Existing Blender executable not found.' }
& $BlenderExe --version
if ($LASTEXITCODE -ne 0) { throw "Blender version command failed: $LASTEXITCODE" }
Write-Host 'Availability checked only. No model was imported or rendered; P4 remains incomplete.'
