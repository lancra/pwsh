#Requires -Version 2.0

if ($PSVersionTable.PSVersion.Major -ge 3) {
    $script:IgnoreError = 'Ignore'
} else {
    $script:IgnoreError = 'SilentlyContinue'
}

$script:nl = [System.Environment]::NewLine

# Dot source public/private functions
$dotSourceParams = @{
    Filter = '*.ps1'
    Recurse = $true
    ErrorAction = 'Stop'
}

$public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'public') @dotSourceParams)
$private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'private/*.ps1') @dotSourceParams)
foreach ($import in @($public + $private)) {
    try {
        . $import.FullName
    } catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $scriptDirectory Lance.psd1
Test-ModuleManifest -Path $manifestPath -WarningAction SilentlyContinue

$script:Lance = @{}

Export-ModuleMember -Function $public.BaseName -Variable Lance
