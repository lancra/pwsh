<#
.SYNOPSIS
Tests if an executable is present in the path.

.DESCRIPTION
Attempts to retrieve a command for a given executable. When successful, this
indicates that the executable is in the path since it can be executed from
anywhere.

.PARAMETER Executable
The executable name, with or without the extension.
#>
function Test-PathExecutable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Executable
    )
    process {
        [bool](Get-Command -Name $Executable -ErrorAction SilentlyContinue)
    }
}
