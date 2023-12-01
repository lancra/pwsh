function Get-NuGetPackageJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [DotnetPackageKind]$Kind
    )
    begin {
        $listCommand = "dotnet list $Path package --format json --$($Kind.ToString().ToLower())"
    }
    process {
        Start-ThreadJob ([scriptblock]::Create($listCommand))
    }
}
