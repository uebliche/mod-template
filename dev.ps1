#!/usr/bin/env pwsh
param(
    [string]$Loader,
    [string]$Version,
    [string]$Mode
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$mcmetaPath = Join-Path $root '..\..\web\mcmeta\loom-index.json'
if (-not (Test-Path $mcmetaPath)) {
    throw "mcmeta file '$mcmetaPath' missing"
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

function Compare-Version {
    param($A, $B)
    $va = [version](Normalize-Version $A)
    $vb = [version](Normalize-Version $B)
    return $va.CompareTo($vb)
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

function Read-BuildFrom {
    $gradleProps = Join-Path $root 'gradle.properties'
    if (-not (Test-Path $gradleProps)) { return '0.0.0' }
    foreach ($line in Get-Content $gradleProps) {
        $trim = $line.Trim()
        if ($trim -and -not $trim.StartsWith('#') -and $trim.StartsWith('buildFromVersion=')) {
            return $trim.Split('=', 2)[1].Trim()
        }
    }
    return '0.0.0'
}

function Load-McmetaVersions {
    param([string]$BuildFrom)
    $payload = Get-Content $mcmetaPath -Raw | ConvertFrom-Json
    $versions = @()
    if ($payload.fabric -and $payload.fabric.versions) {
        $versions = $payload.fabric.versions
    } elseif ($payload.versions) {
        $versions = $payload.versions
    }
    $versions = $versions | Where-Object { $_ -match '^\d+(\.\d+)*$' }
    $versions = $versions | Sort-Object { [version](Normalize-Version $_) } -Descending
    $versions = $versions | Where-Object { (Compare-Version $_ $BuildFrom) -ge 0 }
    return $versions
}

$availableLoaders = Get-ChildItem -Directory -Filter 'loader-*' | ForEach-Object { $_.Name.Substring(7) }
if (-not $availableLoaders -or $availableLoaders.Count -eq 0) {
    throw "No loaders found in loader-* directories"
}

$buildFrom = Read-BuildFrom
$versions = Load-McmetaVersions -BuildFrom $buildFrom
if (-not $versions -or $versions.Count -eq 0) {
    throw "No mcmeta versions found for buildFromVersion"
}

$loaderDisplay = @{}
foreach ($loaderName in $availableLoaders) {
    $loaderDisplay[$loaderName] = "$loaderName ($($versions.Count) version(s))"
}

if (-not $Loader -or -not ($availableLoaders -contains $Loader)) {
    $Loader = Read-Choice -Prompt "Pick loader" -Options $availableLoaders -DisplayMap $loaderDisplay
}

$versionLabels = @{}
foreach ($v in $versions) {
    $versionLabels[$v] = $v
}

$defaultVersion = $versions[0]
if (-not $Version) {
    Write-Host "Auto-selecting latest version: $defaultVersion" -ForegroundColor DarkCyan
    $Version = $defaultVersion
} elseif (-not ($versions -contains $Version)) {
    $Version = Read-Choice -Prompt "Pick version for $Loader" -Options $versions -DisplayMap $versionLabels -Default $defaultVersion
}

$modeOptionsByLoader = @{
    fabric   = @("client","server","build")
    forge    = @("client","server","build")
    paper    = @("server","build")
    velocity = @("server","build")
}
$defaultModeMap = @{
    fabric   = "client"
    forge    = "client"
    paper    = "server"
    velocity = "server"
}
$modeOptions = $modeOptionsByLoader[$Loader]
if (-not $modeOptions) { $modeOptions = @("build") }

if ($Mode) {
    $Mode = $Mode.ToLower()
    if (-not ($modeOptions -contains $Mode)) {
        throw "Unknown mode '$Mode'. Expected one of: $($modeOptions -join ', ')"
    }
} else {
    $defaultMode = $defaultModeMap[$Loader]
    if (-not $defaultMode) { $defaultMode = $modeOptions[0] }
    $Mode = Read-Choice -Prompt "Pick mode" -Options $modeOptions -Default $defaultMode
}

function Resolve-Task {
    param([string]$Loader, [string]$Mode)
    if ($Mode -eq "build") { return "build" }
    if ($Loader -eq "fabric" -or $Loader -eq "forge") {
        return ($Mode -eq "client" ? "runClient" : "runServer")
    }
    if ($Loader -eq "paper") { return "runServer" }
    if ($Loader -eq "velocity") { return "runServer" }
    return "build"
}

$task = Resolve-Task -Loader $Loader -Mode $Mode

$gradlew = Join-Path $root 'gradlew.bat'
if (-not (Test-Path $gradlew)) {
    $gradlew = Join-Path $root 'gradlew'
}

$cmd = @($gradlew, ":loader-$Loader:$task", "-PmcVersion=$Version", "-PonlyLoader=$Loader")
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
