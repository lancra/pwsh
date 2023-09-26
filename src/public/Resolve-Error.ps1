<#
.SYNOPSIS
Outputs all available details of an error record.

.DESCRIPTION
Outputs all properties from an error record, its invocation information, and the
associated exception(s).

.PARAMETER ErrorRecord
The error record to output. The default value is the latest error from the
associated global variable.

.EXAMPLE
Resolve-Error

Displays details for the last error.

.LINK
https://devblogs.microsoft.com/powershell/resolve-error/
#>
function Resolve-Error {
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord = $global:Error[0]
    )
    process {
        $ErrorRecord | Format-List -Property * -Force
        $ErrorRecord.InvocationInfo | Format-List -Property *
        $exception = $ErrorRecord.Exception
        for ($i = 0; $exception; $i++, ($exception = $exception.InnerException))
        {
            "$i" * 80
            $exception | Format-List -Property * -Force
        }
    }
}

Set-Alias -Name rver -Value Resolve-Error
Export-ModuleMember -Alias rver
