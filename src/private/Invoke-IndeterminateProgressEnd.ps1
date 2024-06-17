function Invoke-IndeterminateProgressEnd {
    [CmdletBinding()]
    param ()
    process {
        Write-Host -NoNewline "`e]9;4;0`a"
    }
}
