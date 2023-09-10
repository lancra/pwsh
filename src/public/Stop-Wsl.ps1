<#
.SYNOPSIS
Force stops Windows Subsystem for Linux.

.DESCRIPTION
Kills all processes associated with WSL, initiates a shutdown via WSL, then
kills the WSL process again.

.LINK
https://github.com/microsoft/WSL/issues/8529#issuecomment-1623852490
#>
function Stop-Wsl {
    [CmdletBinding()]
    param()
    process {
        if (-not $IsWindows) {
            throw 'WSL can only be stopped from a Windows OS.'
        }

        #Requires -RunAsAdministrator
        taskkill /f /im wsl.exe
        taskkill /f /im wslhost.exe
        taskkill /f /im wslservice.exe

        wsl --shutdown

        taskkill /f /im wslservice.exe
    }
}
