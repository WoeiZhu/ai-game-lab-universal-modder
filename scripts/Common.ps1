# Shared helpers; loading this file does not invoke tools or network requests.
function Get-LabRoot {
    Split-Path -Parent $PSScriptRoot
}

function Get-LocalComfyUrl {
    param([string]$Value)
    $uri = $null
    if (-not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri)) {
        throw 'ComfyUrl must be an absolute loopback HTTP URL.'
    }
    $address = $null
    $numeric = [Net.IPAddress]::TryParse($uri.Host.Trim('[', ']'), [ref]$address)
    $loopback = $numeric -and ($address.Equals([Net.IPAddress]::Loopback) -or
        $address.Equals([Net.IPAddress]::IPv6Loopback))
    if ($uri.Scheme -ne 'http' -or -not $loopback -or
        $uri.UserInfo -or $uri.Query -or $uri.Fragment -or $uri.AbsolutePath -ne '/') {
        throw 'Only numeric loopback HTTP URLs without credentials, query or path are allowed.'
    }
    if ($address.Equals([Net.IPAddress]::IPv6Loopback)) { 'http://[::1]:' + $uri.Port }
    else { 'http://127.0.0.1:' + $uri.Port }
}

function Get-LabUm {
    $path = Join-Path (Get-LabRoot) '.local/uv/bin/um.exe'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw 'Project-local um CLI missing. Complete the authorized P1 stage first.'
    }
    $path
}

function Assert-LocalImageWorkflow {
    param([object]$Workflow)
    if ($null -eq $Workflow -or $Workflow -isnot [pscustomobject]) {
        throw 'Workflow must be an API JSON object.'
    }
    if ($Workflow.PSObject.Properties['nodes'] -or $Workflow.PSObject.Properties['links']) {
        throw 'UI workflow rejected. Use Export (API).'
    }
    if ($Workflow.PSObject.Properties['prompt']) { $Workflow = $Workflow.prompt }
    if ($Workflow -isnot [pscustomobject] -or @($Workflow.PSObject.Properties).Count -eq 0) {
        throw 'Workflow has no API nodes.'
    }
    $allowed = @('CheckpointLoaderSimple', 'EmptyLatentImage', 'CLIPTextEncode',
        'KSampler', 'VAEDecode', 'SaveImage', 'PreviewImage')
    $hasSave = $false
    foreach ($property in $Workflow.PSObject.Properties) {
        $node = $property.Value
        if ($node -isnot [pscustomobject] -or $node.class_type -cnotin $allowed -or
            $node.inputs -isnot [pscustomobject]) {
            throw 'Unknown, custom, cloud or malformed node rejected.'
        }
        if ($node.class_type -eq 'EmptyLatentImage') {
            foreach ($dimension in @('width', 'height')) {
                $n = $node.inputs.$dimension
                if ($n -isnot [int] -and $n -isnot [long]) { throw 'Image dimension must be an integer.' }
                if ($n -lt 64 -or $n -gt 512 -or $n % 8 -ne 0) { throw 'Smoke image must be 64-512 pixels, divisible by 8.' }
            }
            if ($node.inputs.batch_size -ne 1) { throw 'Smoke batch size must be 1.' }
        }
        if ($node.class_type -eq 'KSampler') {
            $steps = $node.inputs.steps
            if (($steps -isnot [int] -and $steps -isnot [long]) -or $steps -lt 1 -or $steps -gt 30) {
                throw 'Smoke sampler steps must be an integer from 1 to 30.'
            }
        }
        if ($node.class_type -eq 'SaveImage') {
            if ($node.inputs.filename_prefix -notmatch '^[a-zA-Z0-9_-]+$') {
                throw 'SaveImage prefix must be a plain filename stem.'
            }
            $hasSave = $true
        }
    }
    if (-not $hasSave) { throw 'Smoke workflow needs a SaveImage node.' }
}
