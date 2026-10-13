param(
    [switch]$Execute,
    [string]$SourcePath = '',
    [string]$SourceSha256 = '',
    [string]$OutDir = ''
)
$ErrorActionPreference = 'Stop'
if (-not $Execute) {
    Write-Host 'Dry-run: no files written. Supply -Execute, the reviewed source PNG and its SHA256.'
    return
}
. (Join-Path $PSScriptRoot 'Common.ps1')
if ($SourceSha256 -notmatch '^[a-fA-F0-9]{64}$' -or -not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
    throw 'Reviewed source PNG and SHA256 required.'
}
if ((Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash -ine $SourceSha256) {
    throw 'Source hash mismatch.'
}
$um = Get-LabUm
$python = Join-Path (Get-LabRoot) '.local/uv/tools/universal-modder/Scripts/python.exe'
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) { throw 'Project tool Python missing.' }
$assets = [IO.Path]::GetFullPath((Join-Path (Get-LabRoot) 'assets'))
if (-not $OutDir) {
    $OutDir = Join-Path $assets ('sprites/p3-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
}
$OutDir = [IO.Path]::GetFullPath($OutDir)
if (-not $OutDir.StartsWith($assets + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'P3 output must be a new directory under this project assets folder.'
}
if (Test-Path -LiteralPath $OutDir) { throw 'Output already exists. Choose a fresh directory.' }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$source = Join-Path $OutDir 'source.png'
Copy-Item -LiteralPath $SourcePath -Destination $source
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ine $SourceSha256) {
    throw 'Frozen source hash mismatch.'
}
function Invoke-Sprite {
    param([string[]]$Arguments)
    & $um sprite @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Sprite command failed: $LASTEXITCODE" }
}
$cutout = Join-Path $OutDir 'robot-cutout.png'
$fit = Join-Path $OutDir 'robot-64.png'
$mirror = Join-Path $OutDir 'robot-mirror-64.png'
$pixel = Join-Path $OutDir 'robot-pixel-32.png'
$pixelFit = Join-Path $OutDir 'robot-pixel-64.png'
$pixelMirror = Join-Path $OutDir 'robot-pixel-mirror-64.png'
$sheet = Join-Path $OutDir 'robot-sheet.png'
Invoke-Sprite @('info', $source)
Invoke-Sprite @('cutout', $source, $cutout, '--tol', '18')
Invoke-Sprite @('fit', $cutout, $fit, '--size', '64x64', '--hard-alpha')
Invoke-Sprite @('flip', $fit, $mirror)
Invoke-Sprite @('pixelate', $cutout, $pixel, '--size', '32x32', '--colors', '16', '--outline')
Invoke-Sprite @('fit', $pixel, $pixelFit, '--size', '64x64', '--hard-alpha')
Invoke-Sprite @('flip', $pixelFit, $pixelMirror)
Invoke-Sprite @('sheet', $sheet, $fit, $mirror, $pixelFit, $pixelMirror, '--cols', '2')
Invoke-Sprite @('slice', $sheet, (Join-Path $OutDir 'sliced'), '--frame', '64x64')
Invoke-Sprite @('preview', $sheet, (Join-Path $OutDir 'sheet-preview.png'), '--scale', '4')
& $python (Join-Path (Get-LabRoot) 'tests/validate_sprite_outputs.py') $OutDir --source-sha256 $SourceSha256
if ($LASTEXITCODE -ne 0) { throw 'P3 sprite validation failed.' }
if ((Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash -ine $SourceSha256) {
    throw 'Original source was modified.'
}
Write-Host "P3 files verified: $OutDir. Browser scene and visual review still required."
