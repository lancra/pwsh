function Write-HostSegment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [OutputSegment[]]$Segments
    )
    process {
        $Segments |
            ForEach-Object -Process {
                Write-Host -Object $_.Text -ForegroundColor $_.ForegroundColor -NoNewline
            } -End {
                Write-Host ''
            }
    }
}
