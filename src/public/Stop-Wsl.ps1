<#
.SYNOPSIS
Force stops Windows Subsystem for Linux.

.DESCRIPTION
Stops all processes associated with WSL, initiates a shutdown via WSL, then
stops the WSL service process again.

.PARAMETER Force
Stops the WSL processes without prompting for confirmation.

.EXAMPLE
Stop-Wsl

Stops the WSL processes.

.EXAMPLE
Stop-Wsl -Force

Stops the WSL processes without user prompts.

.LINK
https://github.com/microsoft/WSL/issues/8529#issuecomment-1623852490
#>
function Stop-Wsl {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [switch]$Force
    )
    process {
        if (-not $IsWindows) {
            throw 'WSL can only be stopped from Windows.'
        }

        [Security.Principal.WindowsPrincipal] $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'Adminstrator permissions are required to stop processes.'
        }

        Write-Verbose 'Stopping wsl processes...'
        Get-Process -Name 'wsl' -ErrorAction Ignore | Stop-Process -Force:$Force

        Write-Verbose 'Stopping wslhost processes...'
        Get-Process -Name 'wslhost' -ErrorAction Ignore | Stop-Process -Force:$Force

        Write-Verbose 'Stopping wslservice processes...'
        Get-Process -Name 'wslservice' -ErrorAction Ignore | Stop-Process -Force:$Force

        Write-Verbose 'Executing wsl shutdown...'
        wsl --shutdown

        Write-Verbose 'Stopping wslservice processes...'
        Get-Process -Name 'wslservice' -ErrorAction Ignore | Stop-Process -Force:$Force
    }
}
