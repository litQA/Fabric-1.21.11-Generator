<#
.SYNOPSIS
    Verifies the structure of the built generator archive.

.DESCRIPTION
    Fails when the archive violates any packaging rule that MCreator relies on:
      * plugin.json and LICENSE at the archive root;
      * exactly one generator.yaml, inside fabric-<mcVersion>/;
      * base layers contained in fabric-<mcVersion>-base/ and free of generator.yaml;
      * no legacy un-namespaced base paths (datapack-*, neoforge-*);
      * required entry files (fabric.mod.json, mixin.json, pack.mcmeta, workspace build).
#>
[CmdletBinding()]
param(
    [string] $Archive = "",
    [string] $McVersion = "1.21.11"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$pluginDir = Split-Path -Parent $PSScriptRoot
if (-not $Archive) {
    $Archive = Join-Path $pluginDir "build\dist\generator-fabric-$McVersion.zip"
}
if (-not (Test-Path $Archive)) {
    throw "Archive not found: $Archive (build it first)"
}

$generatorDir = "fabric-$McVersion/"
$baseDir = "fabric-$McVersion-base/"
$failures = New-Object System.Collections.Generic.List[string]

$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Archive))
try {
    $entries = $zip.Entries | ForEach-Object { $_.FullName }
    Write-Host "Archive : $Archive"
    Write-Host "Entries : $($entries.Count)"

    foreach ($required in @('plugin.json', 'LICENSE')) {
        if ($entries -notcontains $required) { $failures.Add("missing root entry: $required") }
    }

    $generators = @($entries | Where-Object { $_ -match '(^|/)generator\.yaml$' })
    if ($generators.Count -ne 1) {
        $failures.Add("expected exactly one generator.yaml, found $($generators.Count): $($generators -join ', ')")
    } elseif ($generators[0] -ne "$($generatorDir)generator.yaml") {
        $failures.Add("generator.yaml must be at $($generatorDir)generator.yaml, found $($generators[0])")
    }

    foreach ($layer in @("$($baseDir)datapack/", "$($baseDir)neoforge/")) {
        if (-not ($entries | Where-Object { $_.StartsWith($layer) })) {
            $failures.Add("missing base layer: $layer")
        }
    }

    $legacy = @($entries | Where-Object { $_ -match '^(datapack-|neoforge-|resourcepack-)' })
    if ($legacy.Count -gt 0) {
        $failures.Add("archive contains legacy un-namespaced generator paths: $($legacy -join ', ')")
    }

    foreach ($required in @(
        "$($generatorDir)generator.yaml",
        "$($generatorDir)templates/modbase/fabric.mod.json.ftl",
        "$($generatorDir)templates/modbase/mixin.json.ftl",
        "$($generatorDir)workspacebase/build.gradle",
        "$($generatorDir)workspacebase/gradle/wrapper/gradle-wrapper.properties",
        "$($baseDir)datapack/templates/pack.mcmeta.ftl",
        "$($baseDir)neoforge/utils/mcelements.ftl"
    )) {
        if ($entries -notcontains $required) { $failures.Add("missing required file: $required") }
    }
} finally {
    $zip.Dispose()
}

if ($failures.Count -gt 0) {
    Write-Host "`nFAILED:" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

$hash = (Get-FileHash $Archive -Algorithm SHA256).Hash
Write-Host "`nStructure OK"
Write-Host "SHA-256: $hash"

