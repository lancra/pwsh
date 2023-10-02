<#
.SYNOPSIS
Recursively removes all build artifact directories from a path.

.DESCRIPTION
For a given directory, removes all "artifacts", "bin", and "obj" folders.

.PARAMETER Path
The path to remove build artifact directories from.

.EXAMPLE
Remove-BuildArtifact

Removes the build artifacts within the current directory.

.EXAMPLE
Remove-BuildArtifact C:\Projects\dotnet

Removes the build artifacts within a directory.
#>
function Remove-BuildArtifact {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$Path = '.'
    )
    begin {
        $nodeDirectory = 'node_modules'
        $foldersInSearch = @('artifacts', 'bin', 'obj')
        $foldersNotInParent = $foldersInSearch + $nodeDirectory
    }
    process {
        Get-ChildItem -Path $Path -Directory -Include $foldersInSearch -Recurse |
            Where-Object -FilterScript {
                $parentPath = $_.Parent.FullName
                $parentMatches = $foldersNotInParent |
                    Where-Object -FilterScript { $parentPath -match $_ }

                # A match in the parent path indicates that this directory will either be deleted or ignored as part of the parent.
                $parentMatches.Count -eq 0
            } |
            ForEach-Object {
                $path = $_.FullName
                if (-not $WhatIfPreference) {
                    Write-Host "Removing $path"
                }

                Remove-Item -Path $path -Force -Recurse
            }
    }
}

New-Alias -Name superclean -Value Remove-BuildArtifact
Export-ModuleMember -Alias superclean
