<#
.SYNOPSIS
Force stops Windows Subsystem for Linux.

.DESCRIPTION
Stops all processes associated with WSL, initiates a shutdown via WSL, then
stops the WSL service process again.

.LINK
https://github.com/microsoft/WSL/issues/8529#issuecomment-1623852490
#>
function Stop-Wsl {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    process {
        if (-not $IsWindows) {
            throw 'WSL can only be stopped from Windows.'
        }

        [Security.Principal.WindowsPrincipal] $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'Adminstrator permissions are required to stop processes.'
        }

        Get-Process -Name 'wsl' -ErrorAction Ignore | Stop-Process
        Get-Process -Name 'wslhost' -ErrorAction Ignore | Stop-Process
        Get-Process -Name 'wslservice' -ErrorAction Ignore | Stop-Process

        wsl --shutdown

        Get-Process -Name 'wslservice' -ErrorAction Ignore | Stop-Process
    }
}
