param([switch]$Install, [string]$PythonExe = '')
$ErrorActionPreference = 'Stop'
if (-not $Install) {
    Write-Host 'Dry-run: no installation. P0 evidence and explicit P1 authorization are required.'
    return
}
. (Join-Path $PSScriptRoot 'Common.ps1')
if ($env:VIRTUAL_ENV -or $env:CONDA_PREFIX) { throw 'Leave any active virtual/conda environment before P1.' }
if (-not $PythonExe -or -not [IO.Path]::IsPathRooted($PythonExe) -or
    -not (Test-Path -LiteralPath $PythonExe -PathType Leaf)) {
    throw 'Specify the reviewed, existing non-ComfyUI interpreter using -PythonExe.'
}
$uv = Get-Command uv -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $uv) { throw 'uv missing. Stop; do not install it automatically.' }
if (-not (Get-Command git -CommandType Application -ErrorAction SilentlyContinue)) { throw 'git missing.' }
$pin = Get-Content -LiteralPath (Join-Path (Get-LabRoot) 'config/upstream.json') -Raw | ConvertFrom-Json
if ($pin.repository -cne 'https://github.com/rehan-remade/universal-modder' -or
    $pin.commit -notmatch '^[a-f0-9]{40}$') { throw 'Invalid upstream pin.' }
$base = Join-Path (Get-LabRoot) '.local/uv'
$settings = @{
    UV_TOOL_DIR = (Join-Path $base 'tools')
    UV_TOOL_BIN_DIR = (Join-Path $base 'bin')
    UV_CACHE_DIR = (Join-Path $base 'cache')
    UV_PYTHON_DOWNLOADS = 'never'
    UM_HOME = (Join-Path (Get-LabRoot) '.local/um')
}
$saved = @{}
try {
    foreach ($name in $settings.Keys) {
        $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $settings[$name], 'Process')
    }
    $source = 'git+' + $pin.repository + '@' + $pin.commit
    & $uv.Source --no-config tool install --python $PythonExe $source
    if ($LASTEXITCODE -ne 0) { throw "uv tool install failed: $LASTEXITCODE" }
    $um = Get-LabUm
    & $um --version
    if ($LASTEXITCODE -ne 0) { throw "um --version failed: $LASTEXITCODE" }
    & $um --help
    if ($LASTEXITCODE -ne 0) { throw "um --help failed: $LASTEXITCODE" }
    Write-Host 'P1 CLI checks succeeded. Environment regression still needs separate evidence.'
} finally {
    foreach ($name in $saved.Keys) {
        [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process')
    }
}
