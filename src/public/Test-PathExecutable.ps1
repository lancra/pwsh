<#
.SYNOPSIS
Tests if an executable is present in the path.

.DESCRIPTION
Attempts to retrieve a command for a given executable. When successful, this
indicates that the executable is in the path since it can be executed from
anywhere.

.PARAMETER Executable
The executable name, with or without the extension.

.EXAMPLE
Test-PathExecutable -Executable 'git'
$true

Determines that git is on the path.

.EXAMPLE
Test-PathExecutable -Executable 'git.exe'
$true

Determines that the git executable is on the path. This is a Windows-specific
execution.

.EXAMPLE
Test-PathExecutable -Executable 'fake-executable'
$false

Determines that fake-executable is not on the path.
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
