# Parse and mock tests only. Does not run P0, install tools, contact ComfyUI or use a GPU.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$count = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
    $script:count++
}
function Assert-Rejected {
    param([scriptblock]$Action)
    $rejected = $false
    try { & $Action } catch { $rejected = $true }
    Assert-True $rejected 'Unsafe input was accepted.'
}
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root 'scripts'), $PSScriptRoot -Filter '*.ps1' -File) {
    $tokens = $null
    $errors = $null
    [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
    Assert-True (@($errors).Count -eq 0) "PowerShell parse failed: $($file.Name)"
}
. (Join-Path $root 'scripts/Common.ps1')
Assert-True ((Get-LocalComfyUrl 'http://127.0.0.1:8000') -eq 'http://127.0.0.1:8000') 'Loopback URL failed.'
Assert-True ((Get-LocalComfyUrl 'http://[::1]:8000') -eq 'http://[::1]:8000') 'IPv6 loopback URL failed.'
foreach ($bad in @('https://127.0.0.1:8000', 'http://example.org', 'http://user:pass@127.0.0.1',
    'http://127.0.0.1/path', 'http://127.0.0.1?x=1', 'invalid')) {
    Assert-Rejected { Get-LocalComfyUrl $bad | Out-Null }
}
$workflow = '{"1":{"class_type":"EmptyLatentImage","inputs":{"width":512,"height":512,"batch_size":1}},"2":{"class_type":"KSampler","inputs":{"steps":20}},"3":{"class_type":"SaveImage","inputs":{"filename_prefix":"smoke-test"}}}' | ConvertFrom-Json
Assert-LocalImageWorkflow $workflow
$count++
$workflow.'1'.inputs.batch_size = 2
Assert-Rejected { Assert-LocalImageWorkflow $workflow }
$workflow.'1'.inputs.batch_size = 1
$workflow.'2'.inputs.steps = 100
Assert-Rejected { Assert-LocalImageWorkflow $workflow }
$workflow.'2'.inputs.steps = 20
$workflow.'3'.class_type = 'UnreviewedCloudNode'
Assert-Rejected { Assert-LocalImageWorkflow $workflow }
Assert-Rejected { Assert-LocalImageWorkflow ('{"nodes":[],"links":[]}' | ConvertFrom-Json) }
Assert-Rejected { Assert-LocalImageWorkflow @() }
$stats = @{ system = @{ ram_free = 8GB }; devices = @(@{ vram_free = 8GB }) }
$queue = @{ queue_running = @(); queue_pending = @() }
Assert-ImageResources $stats $queue
$count++
$stats.devices[0].vram_free = 1GB
Assert-Rejected { Assert-ImageResources $stats $queue }
$stats.devices[0].vram_free = 8GB
$stats.system.ram_free = 1GB
Assert-Rejected { Assert-ImageResources $stats $queue }
$stats.system.ram_free = 8GB
$queue.queue_pending = @('unrelated-job')
Assert-Rejected { Assert-ImageResources $stats $queue }
Assert-Rejected { Assert-ImageResources $stats $null }

# Mock the connection endpoint. An accidental HTTP call uses this stub, not the network.
$global:LabTestRequests = New-Object 'System.Collections.Generic.List[object]'
function Invoke-RestMethod {
    param($Uri, $Method, $TimeoutSec, $MaximumRedirection)
    $global:LabTestRequests.Add([pscustomobject]@{ Uri = $Uri; Method = $Method; Redirects = $MaximumRedirection })
    @{ system = @{ comfyui_version = 'mock-only' } }
}
function uv { throw 'Installer invoked during dry-run.' }
& (Join-Path $root 'scripts/10-Install-UM.ps1')
$count++
& (Join-Path $root 'scripts/40-Test-Sprite.ps1')
$count++
& (Join-Path $root 'scripts/20-Test-ComfyUI.ps1')
Assert-True ($global:LabTestRequests.Count -eq 1 -and $global:LabTestRequests[0].Method -eq 'Get' -and
    $global:LabTestRequests[0].Uri -eq 'http://127.0.0.1:8000/system_stats' -and $global:LabTestRequests[0].Redirects -eq 0) 'Connection-only request changed.'
Assert-Rejected { & (Join-Path $root 'scripts/20-Test-ComfyUI.ps1') -ExecuteWorkflow }
Assert-Rejected { & (Join-Path $root 'scripts/20-Test-ComfyUI.ps1') -ComfyUrl 'http://example.org' }
$fixtureDir = Join-Path $root 'reports/repository-tests'
New-Item -ItemType Directory -Force -Path $fixtureDir | Out-Null
$fixture = Join-Path $fixtureDir (([Guid]::NewGuid().ToString('N')) + '.json')
try {
    [IO.File]::WriteAllText($fixture, '{}', (New-Object Text.UTF8Encoding($false)))
    Assert-Rejected {
        & (Join-Path $root 'scripts/20-Test-ComfyUI.ps1') -ExecuteWorkflow -WorkflowPath $fixture -WorkflowSha256 ('0' * 64)
    }
} finally { Remove-Item -LiteralPath $fixture -Force }
Assert-True ($global:LabTestRequests.Count -eq 1) 'Unapproved workflow contacted the server.'
Write-Host "PASS: $count parse/guard/mock checks. This suite did not execute P0-P7."
