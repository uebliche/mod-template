#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$mcmetaPath = Join-Path $root '..\..\web\mcmeta\loom-index.json'
if (-not (Test-Path $mcmetaPath)) {
    throw "mcmeta file '$mcmetaPath' missing"
}

$entries = @()
$java21 = "C:\Program Files\Java\jdk-21"
$originalPath = $env:Path
$originalJavaHome = $env:JAVA_HOME

function Normalize-Version {
    param($Version)
    $parts = $Version.Split('.')
    while ($parts.Count -lt 3) {
        $parts += '0'
    }
    return ($parts[0..2] -join '.')
}

function Compare-Version {
    param($A, $B)
    $va = [version](Normalize-Version $A)
    $vb = [version](Normalize-Version $B)
    return $va.CompareTo($vb)
}

function Get-JavaHome {
    return $java21
}

$buildFrom = '0.0.0'
$gradleProps = Join-Path $root 'gradle.properties'
if (Test-Path $gradleProps) {
    foreach ($line in Get-Content $gradleProps) {
        $trim = $line.Trim()
        if ($trim -and -not $trim.StartsWith('#') -and $trim.StartsWith('buildFromVersion=')) {
            $buildFrom = $trim.Split('=', 2)[1].Trim()
            break
        }
    }
}

$payload = Get-Content $mcmetaPath -Raw | ConvertFrom-Json
$versions = @()
if ($payload.fabric -and $payload.fabric.versions) {
    $versions = $payload.fabric.versions
} elseif ($payload.versions) {
    $versions = $payload.versions
}
$versions = $versions | Where-Object { $_ -match '^\d+(\.\d+)*$' }
$versions = $versions | Sort-Object { [version](Normalize-Version $_) } -Descending
$versions = $versions | Where-Object { (Compare-Version $_ $buildFrom) -ge 0 }

if ($versions.Count -eq 0) {
    throw "No mcmeta versions found for buildFromVersion"
}

$loaders = Get-ChildItem -Directory -Filter 'loader-*' | ForEach-Object { $_.Name.Substring(7) }
if ($loaders.Count -eq 0) {
    throw "No loaders found in loader-* directories"
}

foreach ($loader in $loaders) {
    foreach ($mc in $versions) {
        $entries += [pscustomobject]@{
            Loader = $loader
            Mc      = $mc
            Args    = @()
        }
    }
}

# Prefer the Windows batch wrapper when available so Gradle runs in-place
$gradlew = Join-Path $root 'gradlew.bat'
if (-not (Test-Path $gradlew)) {
    $gradlew = Join-Path $root 'gradlew'
}
if ($entries.Count -eq 0) {
    throw "No loader entries found via mcmeta"
}

$results = @()
$overallFailed = $false

foreach ($item in $entries) {
    $cmd = @($gradlew, ":loader-$($item.Loader):build", "-PmcVersion=$($item.Mc)") + $item.Args
    Write-Host "`n==> $($cmd -join ' ')"
    $cmdArgs = if ($cmd.Count -gt 1) { @($cmd[1..($cmd.Count - 1)]) } else { @() }
    $javaHome = Get-JavaHome $item.Mc
    if (-not (Test-Path $javaHome)) {
        Write-Warning "Java home '$javaHome' not found for Minecraft $($item.Mc)"
        $status = "java-missing"
        $overallFailed = $true
    } else {
        $env:JAVA_HOME = $javaHome
        $env:Path = "$javaHome\bin;$originalPath"
        & $cmd[0] @cmdArgs
        if ($LASTEXITCODE -eq 0) {
            $status = "success"
        } else {
            $status = "failure"
            $overallFailed = $true
        }
    }
    $results += [pscustomobject]@{
        Loader = $item.Loader
        Mc     = $item.Mc
        Status = $status
        Java   = $javaHome
    }
}

$env:JAVA_HOME = $originalJavaHome
$env:Path = $originalPath

Write-Host "`nBuild versions:"
"{0,-10} {1,-10} {2,-12} {3}" -f "Loader", "MC", "Status", "Java"
"{0,-10} {1,-10} {2,-12} {3}" -f "------", "--------", "------------", "-----------------------------"
foreach ($row in $results) {
    "{0,-10} {1,-10} {2,-12} {3}" -f $row.Loader, $row.Mc, $row.Status, $row.Java
}

if ($overallFailed) { exit 1 } else { exit 0 }
