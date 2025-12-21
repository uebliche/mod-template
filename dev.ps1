#!/usr/bin/env pwsh
param(
    [string]$Loader,
    [string]$Version
)

$ErrorActionPreference = 'Stop'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 -bor [Net.SecurityProtocolType]::Tls11
} catch {
    # best-effort on older PowerShell
}

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$matrixPath = Join-Path $root 'versions.matrix.json'
if (-not (Test-Path $matrixPath)) {
    throw "Matrix file '$matrixPath' missing"
}

function Normalize-Version {
    param($Version)
    $rawParts = "$Version" -split '[.]'
    $numeric = @()
    foreach ($part in $rawParts) {
        $clean = ($part -split '[^0-9]')[0]
        if (-not $clean) { $clean = '0' }
        $numeric += [int]$clean
    }
    while ($numeric.Count -lt 3) { $numeric += 0 }
    return ($numeric[0..2] -join '.')
}

function Read-Choice {
    param(
        [string]$Prompt,
        [string[]]$Options,
        [hashtable]$DisplayMap = $null,
        [string]$Default = $null
    )
    while ($true) {
        $i = 0
        foreach ($opt in $Options) {
            $label = if ($DisplayMap -and $DisplayMap.ContainsKey($opt)) { $DisplayMap[$opt] } else { $opt }
            Write-Host ("[{0}] {1}" -f $i, $label)
            $i++
        }
        $defaultHint = $Default ? " (Enter=$Default)" : ""
        $inputVal = Read-Host "$Prompt [0-$($Options.Count - 1) oder Name]$defaultHint"
        if ([string]::IsNullOrWhiteSpace($inputVal) -and $Default) {
            return $Default
        }
        $parsed = 0
        if ([int]::TryParse($inputVal, [ref]$parsed) -and $parsed -ge 0 -and $parsed -lt $Options.Count) {
            return $Options[$parsed]
        }
        $match = $Options | Where-Object { $_ -eq $inputVal }
        if ($match) {
            return $match[0]
        }
        Write-Host "Invalid selection, try again." -ForegroundColor Yellow
    }
}

function Fetch-JsonSafe {
    param([string]$Url)
    try {
        return Invoke-RestMethod -Uri $Url -UseBasicParsing -TimeoutSec 15
    } catch {
        Write-Host "⚠️  Failed to fetch $Url : $_" -ForegroundColor DarkYellow
        return $null
    }
}

$defaultFabricFallback = @(
    "1.14","1.14.1","1.14.2","1.14.3","1.14.4",
    "1.15","1.15.1","1.15.2",
    "1.16","1.16.1","1.16.2","1.16.3","1.16.4","1.16.5",
    "1.17","1.17.1",
    "1.18","1.18.1","1.18.2",
    "1.19","1.19.1","1.19.2","1.19.3","1.19.4",
    "1.20","1.20.1","1.20.2","1.20.3","1.20.4","1.20.5","1.20.6",
    "1.21","1.21.1","1.21.2","1.21.3","1.21.4","1.21.5","1.21.6","1.21.7","1.21.8","1.21.9","1.21.10"
)

function Get-MatrixVariants {
    param($Matrix, [string]$Loader)
    $variants = @()
    $entries = $Matrix.$Loader
    if (-not $entries) { return @() }
    foreach ($entry in $entries) {
        if ($entry -is [string]) {
            $mc = $entry
            $props = @{}
        } else {
            $mc = $entry.mc
            if (-not $mc) { $mc = $entry.mcVersion }
            if (-not $mc) { continue }
            if (($entry.enabled -ne $null) -and (-not $entry.enabled)) { continue }
            $props = $entry.properties
        }
        $args = @()
        if ($props -is [System.Collections.IDictionary]) {
            foreach ($key in $props.Keys) {
                $args += "-P$($key)=$($props[$key])"
            }
        } elseif ($props) {
            $propsPS = $props | ConvertTo-Json -Compress | ConvertFrom-Json
            foreach ($kv in $propsPS.PSObject.Properties) {
                $args += "-P$($kv.Name)=$($kv.Value)"
            }
        }
        $label = $mc
        if ($args.Count -gt 0) { $label = "$mc [$($args -join ' ')]" }
        $variants += [pscustomobject]@{
            Mc    = $mc
            Args  = $args
            Label = $label
        }
    }
    return $variants
}

function Get-FabricVersionsFromApi {
    $data = Fetch-JsonSafe "https://meta.fabricmc.net/v2/versions/game"
    if (-not $data) {
        return $defaultFabricFallback
    }
    $stable = $data | Where-Object { $_.stable -eq $true } | ForEach-Object { $_.version }
    if (-not $stable -or $stable.Count -eq 0) {
        return $defaultFabricFallback
    }
    return $stable
}

function Get-PaperVersionsFromApi {
    $data = Fetch-JsonSafe "https://api.papermc.io/v2/projects/paper"
    if (-not $data) { return @() }
    return $data.versions
}

function Get-VelocityVersionsFromApi {
    $data = Fetch-JsonSafe "https://api.papermc.io/v2/projects/velocity"
    if (-not $data) { return @() }
    return $data.versions
}

function Resolve-VariantsForLoader {
    param($Matrix, [string]$Loader)
    $matrixVariants = Get-MatrixVariants -Matrix $Matrix -Loader $Loader
    $remote = @()
    $source = "matrix"

    # If matrix already defines variants, treat it as authoritative to avoid unsupported remote versions
    if ($matrixVariants.Count -gt 0) {
        return @{
            Variants = $matrixVariants
            Source   = "matrix"
        }
    }

    switch ($Loader) {
        "fabric"   { $remote = Get-FabricVersionsFromApi }
        "paper"    { $remote = Get-PaperVersionsFromApi }
        "velocity" { $remote = Get-VelocityVersionsFromApi }
        default    { $remote = @() }
    }

    if ($Loader -eq "forge" -or -not $remote -or $remote.Count -eq 0) {
        return @{
            Variants = $matrixVariants
            Source   = "matrix-only"
        }
    }

    $variants = @()
    foreach ($ver in $remote) {
        $match = $matrixVariants | Where-Object { $_.Mc -eq $ver } | Select-Object -First 1
        if ($match) {
            $variants += $match
        } else {
            $variants += [pscustomobject]@{
                Mc    = $ver
                Args  = @()
                Label = $ver
            }
        }
    }
    return @{
        Variants = $variants
        Source   = "remote+matrix"
    }
}

$matrix = Get-Content $matrixPath -Raw | ConvertFrom-Json
$availableLoaders = $matrix.PSObject.Properties | Sort-Object Name | ForEach-Object { $_.Name }
if (-not $availableLoaders -or $availableLoaders.Count -eq 0) {
    throw "No loaders found in versions.matrix.json"
}

$loaderDisplay = @{}
$loaderVariantCache = @{}
foreach ($loaderName in $availableLoaders) {
    $resolveInfo = Resolve-VariantsForLoader -Matrix $matrix -Loader $loaderName
    $loaderVariantCache[$loaderName] = $resolveInfo
    $count = ($resolveInfo.Variants).Count
    $source = $resolveInfo.Source
    $loaderDisplay[$loaderName] = "$loaderName ($count version(s), $source)"
}

if (-not $Loader -or -not ($availableLoaders -contains $Loader)) {
    $Loader = Read-Choice -Prompt "Pick loader" -Options $availableLoaders -DisplayMap $loaderDisplay
}

$resolve = $loaderVariantCache[$Loader]
if (-not $resolve) {
    $resolve = Resolve-VariantsForLoader -Matrix $matrix -Loader $Loader
}
$variants = $resolve.Variants
$variantSource = $resolve.Source

if ($variants.Count -eq 0) {
    throw "No versions found for loader '$Loader' (remote fetch + matrix fallback)."
}

$variants = $variants | Sort-Object @{ Expression = { [version](Normalize-Version $_.Mc) } ; Descending = $true }
$versionLabels = @{}
foreach ($v in $variants) {
    $versionLabels[$v.Mc] = $v.Label
}

Write-Host "Versionsquelle: $variantSource" -ForegroundColor DarkGray

$defaultVersion = $variants[0].Mc
if (-not $Version) {
    Write-Host "Auto-selecting latest version: $defaultVersion" -ForegroundColor DarkCyan
    $Version = $defaultVersion
} elseif (-not ($variants.Mc -contains $Version)) {
    $Version = Read-Choice -Prompt "Pick version for $Loader" -Options ($variants.Mc) -DisplayMap $versionLabels -Default $defaultVersion
}

$selected = $variants | Where-Object { $_.Mc -eq $Version } | Select-Object -First 1
if (-not $selected) {
    throw "Version '$Version' not found for loader '$Loader'"
}

$gradlew = Join-Path $root 'gradlew.bat'
if (-not (Test-Path $gradlew)) {
    $gradlew = Join-Path $root 'gradlew'
}

$cmd = @($gradlew, ":loader-$Loader:build", "-PmcVersion=$Version") + $selected.Args
Write-Host "`n==> $($cmd -join ' ')" -ForegroundColor Cyan

$originalPath = $env:Path
$originalJavaHome = $env:JAVA_HOME
$javaHome = "C:\Program Files\Java\jdk-21"
if (Test-Path $javaHome) {
    $env:JAVA_HOME = $javaHome
    $env:Path = "$javaHome\bin;$originalPath"
}

try {
    if ($cmd.Count -gt 1) {
        & $cmd[0] @($cmd[1..($cmd.Count - 1)])
    } else {
        & $cmd[0]
    }
} finally {
    $env:JAVA_HOME = $originalJavaHome
    $env:Path = $originalPath
}
