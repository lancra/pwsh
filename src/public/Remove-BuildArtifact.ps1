function Remove-BuildArtifact {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$Path = '.'
    )
    begin {
        $targetFolderNames = @('artifacts', 'bin', 'obj')
    }
    process {
        Get-ChildItem -Path $Path -Include $targetFolderNames -Recurse |
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
