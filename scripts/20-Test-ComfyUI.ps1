param(
    [string]$ComfyUrl = 'http://127.0.0.1:8000',
    [string]$WorkflowPath = '',
    [string]$WorkflowSha256 = '',
    [switch]$ExecuteWorkflow,
    [string]$OutDir = ''
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$base = Get-LocalComfyUrl $ComfyUrl
$bytes = $null
if ($ExecuteWorkflow) {
    if ($WorkflowSha256 -notmatch '^[A-Fa-f0-9]{64}$' -or
        -not $WorkflowPath -or -not (Test-Path -LiteralPath $WorkflowPath -PathType Leaf)) {
        throw 'Supply an independently reviewed API workflow and its SHA256 before generation.'
    }
    $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $WorkflowPath).Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        throw 'Save the API workflow as UTF-8 without BOM for upstream CLI compatibility.'
    }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $actual = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '') }
    finally { $sha.Dispose() }
    if ($actual -ine $WorkflowSha256) { throw 'Workflow hash mismatch. No workflow submitted.' }
    $raw = [Text.Encoding]::UTF8.GetString($bytes).TrimStart([char]0xFEFF)
    try { $workflow = $raw | ConvertFrom-Json } catch { throw 'Invalid workflow JSON.' }
    Assert-LocalImageWorkflow $workflow
    $um = Get-LabUm
}
try {
    $info = Invoke-RestMethod -Uri "$base/system_stats" -Method Get -TimeoutSec 15 -MaximumRedirection 0
    if (-not $info.system) { throw 'Unexpected system_stats response.' }
} catch { throw 'ComfyUI status check failed. No workflow submitted; do not auto-start or reinstall it.' }
Write-Host "ComfyUI reachable: $base; version: $($info.system.comfyui_version)"
if (-not $ExecuteWorkflow) {
    Write-Host 'Connection-only test complete. No workflow submitted.'
    return
}
if (-not $OutDir) { $OutDir = Join-Path (Get-LabRoot) 'assets/concepts' }
$snapshotDir = Join-Path (Get-LabRoot) 'reports/workflows'
New-Item -ItemType Directory -Force -Path $snapshotDir | Out-Null
$snapshot = Join-Path $snapshotDir (([Guid]::NewGuid().ToString('N')) + '.json')
# Run exactly the reviewed bytes, rather than re-reading a possibly changed source.
[IO.File]::WriteAllBytes($snapshot, $bytes)
$savedUmHome = $env:UM_HOME
try {
    $env:UM_HOME = Join-Path (Get-LabRoot) '.local/um'
    & $um comfy run $snapshot --url $base --out $OutDir --name smoke-test --timeout 300
    if ($LASTEXITCODE -ne 0) { throw "Comfy generation failed: $LASTEXITCODE. Check existing queue before retrying." }
} finally { $env:UM_HOME = $savedUmHome }
Write-Host "Inspect the image and comfy_manifest.jsonl locally in $OutDir. Do not publish raw manifests."
