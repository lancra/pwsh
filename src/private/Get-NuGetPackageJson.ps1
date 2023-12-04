function Get-NuGetPackageJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [DotnetPackageKind]$Kind,
        [switch]$IncludeTransitive
    )
    begin {
        $includeTransitiveOption = $IncludeTransitive ? ' --include-transitive' : ''
        $listCommand = "dotnet list $Path package --format json --$($Kind.ToString().ToLower())$includeTransitiveOption"
    }
    process {
        Start-ThreadJob ([scriptblock]::Create($listCommand))
    }
}
