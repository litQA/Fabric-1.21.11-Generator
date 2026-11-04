<#
.SYNOPSIS
    Switches the Gradle wrapper distribution URL between the local reference zip and the
    public Gradle URL.

.DESCRIPTION
    The generator ships with a local `file:///` distribution URL so that offline test machines
    never re-download Gradle. The public URL is kept commented in the same file. This script
    rewrites the active URL while preserving the commented alternative, for:
      * the plugin project itself (`plugin/gradle/wrapper/gradle-wrapper.properties`);
      * the generated workspace template
        (`plugin/src/main/resources/fabric-<version>/workspacebase/gradle/wrapper/...`).

.PARAMETER Mode
    Local  - active distributionUrl points at Reference resources\gradle-9.8.0-bin.zip
    Public - active distributionUrl points at services.gradle.org

.PARAMETER LocalUrl
    Override for the local distribution URL (raw path or file URI). Defaults to
    <workspace>\Reference resources\gradle-9.8.0-bin.zip.

.PARAMETER Targets
    Plugin, Workspace or All (default All).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Local', 'Public')]
    [string] $Mode,

    [string] $LocalUrl = "",

    [ValidateSet('Plugin', 'Workspace', 'All')]
    [string] $TargetScope = 'All',

    [string] $McVersion = "1.21.11"
)

$ErrorActionPreference = 'Stop'
$pluginDir = Split-Path -Parent $PSScriptRoot
$workspace = Split-Path -Parent $pluginDir

if (-not $LocalUrl) {
    $zip = Join-Path $workspace 'Reference resources\gradle-9.8.0-bin.zip'
    if (-not (Test-Path $zip)) {
        throw "Local Gradle distribution not found: $zip"
    }
    $uri = ([System.Uri]$zip).AbsoluteUri          # file:///B:/QA/.../gradle-9.8.0-bin.zip
    $LocalUrl = $uri -replace ':', '\:'             # properties escaping: file\:///B\:/QA/...
} elseif ($LocalUrl -notmatch '^file') {
    $LocalUrl = (([System.Uri]$LocalUrl).AbsoluteUri) -replace ':', '\:'
}

$publicUrl = 'https\://services.gradle.org/distributions/gradle-9.8.0-bin.zip'

function New-WrapperContent([string] $activeMode) {
    $localLine = if ($activeMode -eq 'Local') { "distributionUrl=$LocalUrl" } else { "# distributionUrl=$LocalUrl" }
    $publicLine = if ($activeMode -eq 'Public') { "distributionUrl=$publicUrl" } else { "# distributionUrl=$publicUrl" }
    $validate = if ($activeMode -eq 'Local') { 'false' } else { 'true' }
    return @(
        'distributionBase=GRADLE_USER_HOME',
        'distributionPath=wrapper/dists',
        '# Local test distribution: keeps builds offline and avoids repeated Gradle downloads.',
        '# Public URL for portable/user environments (switch with tools/set-gradle-distribution.ps1):',
        $publicLine,
        $localLine,
        'networkTimeout=10000',
        "validateDistributionUrl=$validate",
        'zipStoreBase=GRADLE_USER_HOME',
        'zipStorePath=wrapper/dists'
    ) -join "`n"
}

$wrapperTargets = @()
if ($TargetScope -in @('Plugin', 'All')) {
    $wrapperTargets += Join-Path $pluginDir 'gradle\wrapper\gradle-wrapper.properties'
}
if ($TargetScope -in @('Workspace', 'All')) {
    $wrapperTargets += Join-Path $pluginDir "src\main\resources\fabric-$McVersion\workspacebase\gradle\wrapper\gradle-wrapper.properties"
}

$content = New-WrapperContent $Mode
foreach ($wrapperFile in $wrapperTargets) {
    if (-not (Test-Path $wrapperFile)) {
        throw "Wrapper file not found: $wrapperFile"
    }
    [System.IO.File]::WriteAllText($wrapperFile, $content + "`n", (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "updated ($Mode): $wrapperFile"
}

Write-Host "Active distributionUrl: $(if ($Mode -eq 'Local') { $LocalUrl } else { $publicUrl })"
