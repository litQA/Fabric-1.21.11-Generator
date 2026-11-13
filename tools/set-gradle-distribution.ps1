<#
.SYNOPSIS
    Selects the Gradle distribution URL used by the plugin project or the generated workspace template.

.DESCRIPTION
    The public Gradle distribution URL is the default for every wrapper shipped in this repository.
    A local distribution may be selected only for the plugin project itself, and only when the caller
    supplies the path to an existing Gradle distribution archive. The generated workspace template is
    never written with a local URL, so generated projects remain portable.

    No absolute path or local URL is stored in this script or in the wrapper files after a public run.

.PARAMETER Mode
    Public (default) writes the official Gradle distribution URL.
    Local writes a file URL derived from -LocalZip; allowed only with -TargetScope Plugin.

.PARAMETER LocalZip
    Path to an existing Gradle distribution archive for Local mode. The path is resolved by the caller;
    the script does not assume a fixed workspace location.

.PARAMETER TargetScope
    Plugin, Workspace or All (default All). Local mode supports Plugin only.

.PARAMETER McVersion
    Generator directory suffix used for the workspace template.
#>
[CmdletBinding()]
param(
    [ValidateSet('Public', 'Local')]
    [string] $Mode = 'Public',

    [string] $LocalZip = "",

    [ValidateSet('Plugin', 'Workspace', 'All')]
    [string] $TargetScope = 'All',

    [string] $McVersion = "1.21.11"
)

$ErrorActionPreference = 'Stop'
$pluginDir = Split-Path -Parent $PSScriptRoot
$publicUrl = 'https\://services.gradle.org/distributions/gradle-9.8.0-bin.zip'

if ($Mode -eq 'Local') {
    if (-not $LocalZip) {
        throw "Local mode requires -LocalZip <path-to-gradle-distribution.zip>."
    }
    if ($TargetScope -ne 'Plugin') {
        throw "Local mode is restricted to -TargetScope Plugin; generated workspace templates must keep the public URL."
    }
    if (-not (Test-Path -LiteralPath $LocalZip -PathType Leaf)) {
        throw "Gradle distribution archive not found: $LocalZip"
    }

    $resolvedZip = (Resolve-Path -LiteralPath $LocalZip).Path
    $activeUrl = ([System.Uri]$resolvedZip).AbsoluteUri -replace ':', '\:'
    $validate = $false
} else {
    $activeUrl = $publicUrl
    $validate = $true
}

function New-WrapperContent([string] $distributionUrl, [bool] $validateDistributionUrl) {
    $validateValue = if ($validateDistributionUrl) { 'true' } else { 'false' }
    return @(
        'distributionBase=GRADLE_USER_HOME',
        'distributionPath=wrapper/dists',
        "distributionUrl=$distributionUrl",
        'networkTimeout=10000',
        'retries=0',
        'retryBackOffMs=500',
        "validateDistributionUrl=$validateValue",
        'zipStoreBase=GRADLE_USER_HOME',
        'zipStorePath=wrapper/dists'
    ) -join "`n"
}

$wrapperTargets = @()
if ($TargetScope -in @('Plugin', 'All')) {
    $wrapperTargets += @{
        Label = 'plugin'
        Path  = Join-Path $pluginDir 'gradle\wrapper\gradle-wrapper.properties'
    }
}
if ($TargetScope -in @('Workspace', 'All')) {
    $wrapperTargets += @{
        Label = 'workspace template'
        Path  = Join-Path $pluginDir "src\main\resources\fabric-$McVersion\workspacebase\gradle\wrapper\gradle-wrapper.properties"
    }
}

$content = New-WrapperContent $activeUrl $validate
foreach ($target in $wrapperTargets) {
    if (-not (Test-Path -LiteralPath $target.Path -PathType Leaf)) {
        throw "Wrapper file not found: $($target.Path)"
    }
    [System.IO.File]::WriteAllText($target.Path, $content + "`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Updated $($target.Label) wrapper: $($target.Path)"
}

Write-Host "Active Gradle distribution mode: $Mode"
