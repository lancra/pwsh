function Write-HostSegment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [OutputSegment[]]$Segments
    )
    process {
        $segmentCounter = 0
        $Segments |
            ForEach-Object {
                $segmentCounter++
                $isLastSegment = $segmentCounter -eq $Segments.Length

                Write-Host -Object $_.Text -ForegroundColor $_.ForegroundColor -NoNewline

                if ($isLastSegment) {
                    Write-Host ''
                }
            }
    }
}
