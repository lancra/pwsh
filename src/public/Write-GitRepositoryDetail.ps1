<#
.SYNOPSIS
Writes the name of a repository with some optional details.

.DESCRIPTION
Uses the name of the directory from the filesystem to name the repository. Then,
unless disabled, it uses the branch status from Git to write the current head
and the ahead/behind to the associated remote.

.PARAMETER Path
The filesystem path for the repository. The current directory is used if none is
provided.

.PARAMETER NoHead
Disables writing the current head to the host.

.PARAMETER NoAheadBehind
Disables writing the remote ahead/behind to the host.

.EXAMPLE
Write-GitRepositoryDetail -Path C:\Projects\git
git (seen +0 -0)

.EXAMPLE
Write-GitRepositoryDetail -Path C:\Projects\git -NoHead
git (+0 -0)

.EXAMPLE
Write-GitRepositoryDetail -Path C:\Projects\git -NoAheadBehind
git (seen)

.EXAMPLE
Write-GitRepositoryDetail -Path C:\Projects\git -NoHead -NoAheadBehind
git:
#>
function Write-GitRepositoryDetail {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '.',
        [switch]$NoHead,
        [switch]$NoAheadBehind
    )
    begin {
        class BranchStatus {
            [string]$Head
            [string]$Ahead
            [string]$Behind

            BranchStatus([string[]]$commandOutput) {
                $statusHeaderMatches = $commandOutput |
                    Select-String -Pattern '# ([^\s]+) (.*)' |
                    Select-Object -ExpandProperty Matches

                $headStatusHeaderMatch = $statusHeaderMatches |
                    Where-Object { $_.Groups[1].Value -eq 'branch.head' } |
                    Select-Object -First 1
                $this.Head = $headStatusHeaderMatch.Groups[2].Value

                $aheadBehindStatusHeaderMatch = $statusHeaderMatches |
                    Where-Object { $_.Groups[1].Value -eq 'branch.ab' } |
                    Select-Object -First 1
                if ($aheadBehindStatusHeaderMatch) {
                    $aheadBehindParts = $aheadBehindStatusHeaderMatch.Groups[2].Value -split ' '
                    $this.Ahead = $aheadBehindParts[0]
                    $this.Behind = $aheadBehindParts[1]
                }
            }
        }
    }
    process {
        # Any Git commands should be executed before printing the directory since the opposite order introducing a stuttering behavior
        # when printing.
        $script:branchStatus = $null
        if (-not $NoHead -or -not $NoAheadBehind) {
            $branchStatusCommand = "git -C '$Path' status --branch --porcelain=2"
            $branchStatusOutput = Invoke-Command -ScriptBlock ([scriptblock]::Create($branchStatusCommand))
            $script:branchStatus = [BranchStatus]::new($branchStatusOutput)
        }

        $outputSegments = [System.Collections.Generic.List[OutputSegment]]::new()

        $repository = Split-Path -Path $Path -Leaf
        $outputSegments.Add([OutputSegment]::new($repository, 'Yellow'))

        if ($script:branchStatus) {
            $outputSegments.Add([OutputSegment]::new(' ('))

            $showHead = -not $NoHead -and $script:branchStatus.Head
            if ($showHead) {
                $outputSegments.Add([OutputSegment]::new($script:branchStatus.Head, 'Blue'))
            }

            $showAheadBehind = -not $NoAheadBehind -and ($script:branchStatus.Ahead -or $script:branchStatus.Behind)
            if ($showAheadBehind) {
                $ahead = $script:branchStatus.Ahead
                if ($showHead) {
                    $ahead = " $ahead"
                }

                $outputSegments.Add([OutputSegment]::new($ahead, 'Green'))
                $outputSegments.Add([OutputSegment]::new(" $($script:branchStatus.Behind)", 'Red'))
            }

            $outputSegments.Add([OutputSegment]::new(')'))
        } else {
            $outputSegments.Add([OutputSegment]::new(':'))
        }

        Write-HostSegment -Segments $outputSegments.ToArray()
    }
}
