<#
.SYNOPSIS
    Runs the offline validation suite for the Fabric 1.21.11 generator.

.DESCRIPTION
    The suite has three stages:
      1. Gradle resource checks (metadata, layout, version consistency, definition template refs).
      2. Compilation of the Java static validator against the FreeMarker and SnakeYAML Engine
         libraries bundled with the target MCreator installation.
      3. FreeMarker/YAML parsing of every generator resource plus build invariant checks.

    No network access, no MCreator launch and no Minecraft dependency resolution is required.

.PARAMETER McRoot
    MCreator installation that provides lib/freemarker-*.jar and lib/snakeyaml-engine-*.jar.
    Defaults to MCREATOR_HOME, or to a single MCreator* directory beside the plugin project.
    Pass an explicit path when more than one installation is present.

.PARAMETER SkipGradle
    Skips stage 1 (useful when only the Java validator should run).
#>
[CmdletBinding()]
param(
    [string] $McRoot = "",
    [switch] $SkipGradle
)

$ErrorActionPreference = 'Stop'
$pluginDir = Split-Path -Parent $PSScriptRoot
$workspace = Split-Path -Parent $pluginDir
$resources = Join-Path $pluginDir 'src\main\resources'
$buildDir = Join-Path $PSScriptRoot 'build'

if (-not $McRoot) {
    if ($env:MCREATOR_HOME -and (Test-Path -LiteralPath (Join-Path $env:MCREATOR_HOME 'lib') -PathType Container)) {
        $McRoot = $env:MCREATOR_HOME
    }
}
if (-not $McRoot) {
    $candidates = @(Get-ChildItem -LiteralPath $workspace -Directory -Filter 'MCreator*' -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'lib') -PathType Container })
    if ($candidates.Count -eq 1) {
        $McRoot = $candidates[0].FullName
    } elseif ($candidates.Count -gt 1) {
        throw "Multiple MCreator installations found. Pass -McRoot or set MCREATOR_HOME to the installation containing lib/."
    }
}
if (-not $McRoot) {
    throw "MCreator installation not found. Pass -McRoot or set MCREATOR_HOME."
}
if (-not (Test-Path -LiteralPath $McRoot -PathType Container)) {
    throw "MCreator installation not found: $McRoot"
}
if (-not (Test-Path -LiteralPath (Join-Path $McRoot 'lib') -PathType Container)) {
    throw "MCreator installation has no lib directory: $McRoot"
}

Write-Host "== Fabric 1.21.11 generator validation =="
Write-Host "plugin    : $pluginDir"
Write-Host "resources : $resources"
Write-Host "MCreator  : $McRoot"

# ---------------------------------------------------------------------------
# Stage 1: Gradle resource checks
# ---------------------------------------------------------------------------
if (-not $SkipGradle) {
    $gradle = Get-Command gradle -ErrorAction SilentlyContinue
    if (-not $gradle) {
        $localGradle = Join-Path $workspace 'caches\gradle-dist\gradle-9.8.0\bin\gradle.bat'
        if (Test-Path $localGradle) {
            $gradle = $localGradle
        }
    }
    if (-not $gradle) {
        Write-Warning 'Gradle not found; run with -SkipGradle or add gradle to PATH.'
    } else {
        $env:GRADLE_USER_HOME = Join-Path $workspace 'caches\gradle'
        Write-Host "`n[1/3] gradle checkPluginResources"
        & $gradle -p $pluginDir checkPluginResources --offline --no-daemon --console=plain
        if ($LASTEXITCODE -ne 0) {
            throw "Gradle resource validation failed (exit $LASTEXITCODE)"
        }
    }
}

# ---------------------------------------------------------------------------
# Stage 2: compile the Java validator
# ---------------------------------------------------------------------------
Write-Host "`n[2/3] compile PluginValidator"
$freemarker = Get-ChildItem (Join-Path $McRoot 'lib') -Filter 'freemarker-*.jar' | Select-Object -First 1
$snakeyaml = Get-ChildItem (Join-Path $McRoot 'lib') -Filter 'snakeyaml-engine-*.jar' | Select-Object -First 1
if (-not $freemarker -or -not $snakeyaml) {
    throw "FreeMarker/SnakeYAML jars not found under $McRoot\lib"
}
Write-Host "  freemarker: $($freemarker.Name)"
Write-Host "  snakeyaml : $($snakeyaml.Name)"

$classpath = "$($freemarker.FullName);$($snakeyaml.FullName)"
New-Item -ItemType Directory -Force $buildDir | Out-Null
$javac = Join-Path $McRoot 'jdk\bin\javac.exe'
if (-not (Test-Path $javac)) { $javac = 'javac' }
& $javac -encoding UTF-8 --release 21 -classpath $classpath -d $buildDir (Join-Path $PSScriptRoot 'PluginValidator.java')
if ($LASTEXITCODE -ne 0) {
    throw "javac failed (exit $LASTEXITCODE)"
}

# ---------------------------------------------------------------------------
# Stage 3: run the Java validator
# ---------------------------------------------------------------------------
Write-Host "`n[3/3] PluginValidator"
$java = Join-Path $McRoot 'jdk\bin\java.exe'
if (-not (Test-Path $java)) { $java = 'java' }
& $java -classpath "$buildDir;$classpath" PluginValidator $resources
$exit = $LASTEXITCODE
if ($exit -ne 0) {
    throw "Generator static validation reported errors (exit $exit)"
}
Write-Host "`nAll validation stages passed."
