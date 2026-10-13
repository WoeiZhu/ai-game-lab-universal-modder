param(
    [string]$OutDir = '',
    [string[]]$ProtectedEnvironmentPaths = @(),
    [switch]$QueryVersions
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not $OutDir) { $OutDir = Join-Path (Get-LabRoot) 'reports' }
$results = foreach ($tool in @('git', 'python', 'uv', 'codex', 'claude', 'ffmpeg', 'blender', 'um')) {
    $cmd = Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $version = 'NOT_QUERIED'
    $code = $null
    if ($cmd -and $QueryVersions) {
        try {
            $versionFlag = if ($tool -eq 'ffmpeg') { '-version' } else { '--version' }
            $output = & $cmd.Source $versionFlag 2>&1
            $code = $LASTEXITCODE
            $version = ($output | Select-Object -First 1 | Out-String).Trim()
        } catch { $version = 'QUERY_FAILED'; $code = -1 }
    }
    [pscustomobject]@{ Tool = $tool; Exists = [bool]$cmd; Version = $version; ExitCode = $code
        Source = $(if ($cmd) { $cmd.Source } else { '' }) }
}
$protected = foreach ($path in $ProtectedEnvironmentPaths) {
    [pscustomobject]@{ Path = $path; Exists = (Test-Path -LiteralPath $path -PathType Container) }
}
$report = [pscustomobject]@{
    Timestamp = (Get-Date).ToUniversalTime().ToString('o')
    Computer = $env:COMPUTERNAME
    OS = [Environment]::OSVersion.VersionString
    Tools = @($results)
    ProtectedEnvironments = @($protected)
    ComfyConnection = 'NOT_RUN'
    WorkflowRegression = 'NOT_RUN'
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$file = Join-Path $OutDir 'preflight.json'
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $file -Encoding UTF8
$results | Format-Table -AutoSize
Write-Host "Inventory saved locally: $file. It contains private paths; do not commit it."
Write-Host 'No installations or workflow tests were performed. Review missing tools and baseline manually.'
