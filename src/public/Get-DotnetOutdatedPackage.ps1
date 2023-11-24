<#
.SYNOPSIS
Retrieves the outdated NuGet packages for a .NET solution or project.

.DESCRIPTION
Uses the .NET CLI to determine the outdated NuGet packages for one or more
projects. Then it re-arranges the output to a more compact package-scoped format
(instead of the default project-scoped format), where each affected project is
identified by a unique letter.

.PARAMETER Path
The directory, solution, or project to get outdated packages for. The current
directory is used if no value is provided.

.EXAMPLE
Get-DotnetOutdatedPackage C:\Projects

Gets outdated NuGet packages for a directory.

.EXAMPLE
Get-DotnetOutdatedPackage

Gets outdated NuGet packages for the current directory.
#>
function Get-DotnetOutdatedPackage {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '.'
    )
    begin {
        Start-IndeterminateProgress

        $letterIdProvider = [LetterIdProvider]::new()
    }
    process {
        # The list command does not operate as expected for relative paths in the .NET 8 upgrade, so the absolute path is used instead.
        $absolutePath = (Resolve-Path -Path $Path).Path
        $packagesResultObject = dotnet list $absolutePath package --outdated --format json | ConvertFrom-Json
        $packagesResult = [DotnetPackageListResult]::new($packagesResultObject)

        # Projects are included in the output, whether or not they have any outdated packages. This allows affected projects to be
        # flagged for inclusion in this output.
        $projectPaths = [System.Collections.Generic.Dictionary[string, bool]]::new()
        foreach ($project in $packagesResult.Projects) {
            $projectPaths.Add($project.Path, $false)
        }

        $packages = [System.Collections.Generic.Dictionary[string, Package]]::new()
        foreach ($project in $packagesResult.Projects) {
            foreach ($framework in $project.Frameworks) {
                foreach ($topLevelPackage in $framework.TopLevelPackages) {
                    $packageKey = $topLevelPackage.Id
                    $packages.TryAdd($packageKey, [Package]::new($packageKey, $topLevelPackage.LatestVersion)) > $null
                    $package = $packages[$packageKey]

                    $packageReferenceKey = $topLevelPackage.ResolvedVersion
                    $package.References.TryAdd($packageReferenceKey, [PackageReference]::new($packageReferenceKey)) > $null
                    $packageReference = $package.References[$packageReferenceKey]

                    $projectKey = $project.Path
                    if (-not ($packageReference.Projects -contains $projectKey)) {
                        $packageReference.Projects.Add($projectKey)
                    }

                    $projectPaths[$projectKey] = $true
                }
            }
        }

        $projects = [System.Collections.Generic.Dictionary[string, LetterId]]::new()
        $projectPaths.GetEnumerator() |
            Where-Object Value -eq $true |
            # Force a natural number sort by separating digits and path separators with spaces.
            Sort-Object -Property { [regex]::Replace($_.Key, '\d+|\\|/', { $args[0].Value.PadLeft(5) }) } |
            ForEach-Object {
                $path = $_.Key
                $projects.Add($path, $letterIdProvider.Next($path))
            }

        Stop-IndeterminateProgress

        $packages.GetEnumerator() |
            Sort-Object -Property Key |
            ForEach-Object {
                $package = $_.Value

                $packageReferenceSegmentCollections =
                    [System.Collections.Generic.List[System.Collections.Generic.List[OutputSegment]]]::new()
                $package.References.GetEnumerator() |
                    # Force a natural number sort by separating digits with spaces.
                    # Include a trailing period to force release versions to be sorted after pre-release versions.
                    # For example, "0.1.0" -> "0.1.0." is correctly sorted after "0.1.0-preview0" -> "0.1.0-preview0.".
                    Sort-Object -Property { [regex]::Replace($_.Key, '\d+', { $args[0].Value.PadLeft(5) }) + '.' } |
                    ForEach-Object {
                        $packageReference = $_.Value

                        $segments = [System.Collections.Generic.List[OutputSegment]]::new()
                        $segments.Add([OutputSegment]::new($packageReference.Version, 'Red'))
                        $segments.Add([OutputSegment]::new(' -> '))
                        $segments.Add([OutputSegment]::new($package.LatestVersion, 'Green'))

                        $segments.Add([OutputSegment]::new(' ('))
                        $packageReference.Projects |
                            Select-Object -Property @{name='LetterId';expression={$projects[$_]}} |
                            Select-Object -ExpandProperty LetterId |
                            Sort-Object -Property Letter |
                            ForEach-Object {
                                $segments.Add([OutputSegment]::new($_.Letter, $_.Color))
                            }

                        $segments.Add([OutputSegment]::new(')'))

                        $packageReferenceSegmentCollections.Add($segments)
                    }

                $packageSegments = [System.Collections.Generic.List[OutputSegment]]::new()
                $packageSegments.Add([OutputSegment]::new("$($package.Id):"))
                if ($packageReferenceSegmentCollections.Count -eq 1) {
                    $packageSegments.Add([OutputSegment]::new(' '))
                    $packageSegments.AddRange($packageReferenceSegmentCollections[0])
                    Write-HostSegment -Segments $packageSegments
                } else {
                    Write-HostSegment -Segments $packageSegments
                    foreach ($packageReferenceSegments in $packageReferenceSegmentCollections) {
                        $packageReferenceSegments.Insert(0, [OutputSegment]::new('  '))
                        Write-HostSegment -Segments $packageReferenceSegments
                    }
                }
            }

        if ($packages.Keys.Count -gt 0) {
            Write-Host
        }

        $projects.GetEnumerator() |
            ForEach-Object {
                $path = $_.Key
                $letterId = $_.Value

                $segments = [System.Collections.Generic.List[OutputSegment]]::new()
                $segments.Add([OutputSegment]::new($letterId.Letter, $letterId.Color))
                $segments.Add([OutputSegment]::new(": $path"))
                Write-HostSegment -Segments $segments
            }
    }
}
