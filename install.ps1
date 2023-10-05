[CmdletBinding()]
param(
    [Parameter()]
    [string]$Repository = 'Local'
)

function Join-Version {
    param(
        [string]$ModuleVersion,
        [string]$Prerelease
    )
    process {
        $finalVersion = $ModuleVersion
        if ($Prerelease) {
            $finalVersion = "$ModuleVersion-$Prerelease"
        }

        $finalVersion
    }
}

if (-not (Get-PSRepository -Name $Repository -ErrorAction SilentlyContinue)) {
    throw "The '$Repository' repository was not found. Please register it and retry."
}

Write-Host 'Executing build script...'
./build.ps1 -Task Build -Bootstrap

$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'src' -AdditionalChildPath 'Lance.psd1'
$manifest = Import-PowerShellDataFile -Path $manifestPath
$manifestVersion = Join-Version -ModuleVersion $manifest.ModuleVersion -Prerelease $manifest.PrivateData.PSData.Prerelease

$repositoryModule = Find-Module -Name Lance -Repository $Repository

if (-not $repositoryModule -or $repositoryModule.Version -ne $manifestVersion) {
    Write-Host "Publishing new module version $manifestVersion..."
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath 'artifacts' -AdditionalChildPath 'Lance'
    Publish-Module -Path $modulePath -Repository $Repository
} else {
    Write-Host "Version $manifestVersion is already in the repository. Skipping publish..."
}

$installedModule = Get-Module -Name Lance
$installedVersion = Join-Version -ModuleVersion $installedModule.Version -Prerelease $installedModule.PrivateData.PSData.Prerelease

if ($installedVersion -eq $manifestVersion) {
    Write-Host 'The latest module version is already imported. Skipping install...'
} else {
    Write-Host 'Uninstalling current module version...'
    Uninstall-Module -Name Lance -ErrorAction SilentlyContinue

    Write-Host 'Installing latest module version...'
    Install-Module -Name Lance -Repository $Repository -AllowPrerelease
}
