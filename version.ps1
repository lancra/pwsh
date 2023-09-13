$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'src' -AdditionalChildPath 'Lance.psd1'
$manifest = Import-PowerShellDataFile -Path $manifestPath

$moduleVersion = $manifest.ModuleVersion
$prerelease = $manifest.PrivateData.PSData.Prerelease

$tag = "v$moduleVersion"
if ($prerelease) {
    $tag = "$tag-$prerelease"
}

git show-ref --tags "$tag"

if ($LASTEXITCODE -eq 0) {
    throw "Please specify a unique module version. A tag has already been created for $tag"
}

exit 0
