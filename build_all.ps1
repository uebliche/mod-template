#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$matrixPath = Join-Path $root 'versions.matrix.json'
if (-not (Test-Path $matrixPath)) {
    throw "Matrix file '$matrixPath' missing"
}

$matrix = Get-Content $matrixPath -Raw | ConvertFrom-Json
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

foreach ($prop in $matrix.PSObject.Properties) {
    $loader = $prop.Name
    foreach ($entry in $prop.Value) {
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
        $entries += [pscustomobject]@{
            Loader = $loader
            Mc      = $mc
            Args    = $args
        }
    }
}

if ($entries.Count -eq 0) {
    throw "No loader entries found in versions.matrix.json"
}

# Prefer the Windows batch wrapper when available so Gradle runs in-place
$gradlew = Join-Path $root 'gradlew.bat'
if (-not (Test-Path $gradlew)) {
    $gradlew = Join-Path $root 'gradlew'
}
if ($entries.Count -eq 0) {
    throw "No loader entries found in versions.matrix.json"
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

Write-Host "`nBuild matrix:"
"{0,-10} {1,-10} {2,-12} {3}" -f "Loader", "MC", "Status", "Java"
"{0,-10} {1,-10} {2,-12} {3}" -f "------", "--------", "------------", "-----------------------------"
foreach ($row in $results) {
    "{0,-10} {1,-10} {2,-12} {3}" -f $row.Loader, $row.Mc, $row.Status, $row.Java
}

if ($overallFailed) { exit 1 } else { exit 0 }
