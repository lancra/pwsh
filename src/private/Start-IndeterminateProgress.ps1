function Start-IndeterminateProgress {
    [CmdletBinding()]
    param ()
    process {
        Write-Host -NoNewline "`e]9;4;3`a"
    }
}
