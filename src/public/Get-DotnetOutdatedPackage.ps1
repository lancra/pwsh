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

.PARAMETER IncludeTransitive
The value that determines whether transitive packages (i.e. indirect
dependencies) are included in the output.

.EXAMPLE
Get-DotnetOutdatedPackage C:\Projects

Gets outdated NuGet packages for a directory.

.EXAMPLE
Get-DotnetOutdatedPackage

Gets outdated NuGet packages for the current directory.

.EXAMPLE
Get-DotnetOutdatedPackage -IncludeTransitive

Gets top-level and transitive outdated NuGet packages for the current directory.
#>
function Get-DotnetOutdatedPackage {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '.',
        [switch]$IncludeTransitive
    )
    begin {
        function Set-OutputPackage {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory)]
                [hashtable]$OutputPackages,
                [Parameter(Mandatory)]
                [DotnetPackage]$Package,
                [Parameter(Mandatory)]
                [string]$Project,
                [Parameter(Mandatory)]
                [DotnetPackageReferenceKind]$Kind
            )
            process {
                $outputPackage = $OutputPackages[$Package.Id]
                if (-not $outputPackage) {
                    $outputPackage = [OutputPackage]::new($Package.Id)
                    $OutputPackages[$Package.Id] = $outputPackage
                }

                if ($Package.LatestVersion) {
                    $outputPackage.LatestVersion = $Package.LatestVersion
                }

                $outputPackageReference = $outputPackage.References[$Package.ResolvedVersion]
                if (-not $outputPackageReference) {
                    $outputPackageReference = [OutputPackageReference]::new($Package.ResolvedVersion)
                    $outputPackage.References[$Package.ResolvedVersion] = $outputPackageReference
                }

                $outputPackageReference.Projects[$Project] = $true

                if ($Kind -eq [DotnetPackageReferenceKind]::Direct) {
                    $outputPackageReference.IsDirect = $true
                } elseif ($Kind -eq [DotnetPackageReferenceKind]::Transitive) {
                    $outputPackageReference.IsTransitive = $true
                }

                if ($Package.DeprecationReasons) {
                    $outputPackageReference.IsDeprecated = $true
                }

                if ($Package.Vulnerabilities) {
                    $outputPackageReference.Vulnerabilities = $Package.Vulnerabilities
                }
            }
        }

        Start-IndeterminateProgress

        $letterIdProvider = [LetterIdProvider]::new()
        $latestVersionNotFound = 'Not found at the sources'
        $nugetPackageUriPrefix = 'https://www.nuget.org/packages/'
    }
    process {
        # The list command does not operate as expected for relative paths in the .NET 8 upgrade, so the absolute path is used instead.
        $absolutePath = (Resolve-Path -Path $Path).Path

        $jobs = [DotnetPackageKind].GetEnumValues() |
            ForEach-Object { Get-NuGetPackageJson -Path $absolutePath -Kind $_ -IncludeTransitive:$IncludeTransitive }

        Wait-Job $jobs | Out-Null
        $packagesResults = $jobs |
            ForEach-Object {
                $jsonLines = Receive-Job -Job $_
                $json = $jsonLines -join "`n"
                $jsonObject = $json | ConvertFrom-Json
                [DotnetPackageListResult]::new($jsonObject)
            }

        # Projects are included in the output, whether or not they have any outdated packages. This allows affected projects to be
        # flagged for inclusion in this output.
        $projectPaths = @{}
        $packagesResults |
            Select-Object -ExpandProperty Projects |
            Select-Object -ExpandProperty Path -Unique |
            Sort-Object |
            ForEach-Object { $projectPaths[$_] = $false }

        $outputPackages = @{}
        foreach ($packagesResult in $packagesResults) {
            foreach ($project in $packagesResult.Projects) {
                foreach ($framework in $project.Frameworks) {
                    foreach ($package in $framework.TopLevelPackages) {
                        $projectPaths[$project.Path] = $true

                        $setOutputPackageArguments = @{
                            OutputPackages = $outputPackages
                            Package = $package
                            Project = $project.Path
                            Kind = [DotnetPackageReferenceKind]::Direct
                        }
                        Set-OutputPackage @setOutputPackageArguments
                    }

                    foreach ($package in $framework.TransitivePackages) {
                        $projectPaths[$project.Path] = $true

                        $setOutputPackageArguments = @{
                            OutputPackages = $outputPackages
                            Package = $package
                            Project = $project.Path
                            Kind = [DotnetPackageReferenceKind]::Transitive
                        }
                        Set-OutputPackage @setOutputPackageArguments
                    }
                }
            }
        }

        $projects = [ordered]@{}
        $projectPaths.GetEnumerator() |
            Where-Object Value -eq $true |
            # Force a natural number sort by separating digits and path separators with spaces.
            Sort-Object -Property { [regex]::Replace($_.Key, '\d+|\\|/', { $args[0].Value.PadLeft(5) }) } |
            ForEach-Object {
                $projects[$_.Key] = $letterIdProvider.Next($path)
            }

        Stop-IndeterminateProgress

        $outputPackages.GetEnumerator() |
            Sort-Object -Property Key |
            ForEach-Object {
                $outputPackage = $_.Value

                $packageReferenceSegmentsCollection = @()
                $outputPackage.References.GetEnumerator() |
                    # Force a natural number sort by separating digits with spaces.
                    # Include a trailing period to force release versions to be sorted after pre-release versions.
                    # For example, "0.1.0" -> "0.1.0." is correctly sorted after "0.1.0-preview0" -> "0.1.0-preview0.".
                    Sort-Object -Property { [regex]::Replace($_.Key, '\d+', { $args[0].Value.PadLeft(5) }) + '.' } |
                    ForEach-Object {
                        $outputPackageReference = $_.Value

                        $segments = @()
                        $segments += [OutputSegment]::new($outputPackageReference.Version, 'Red')
                        $segments += [OutputSegment]::new(' -> ')

                        if ($outputPackage.LatestVersion -ne $latestVersionNotFound) {
                            $segments += [OutputSegment]::new($outputPackage.LatestVersion, 'Green')
                        } else {
                            $segments += [OutputSegment]::new('?')
                        }

                        $segments += [OutputSegment]::new(' (')
                        $outputPackageReference.Projects.GetEnumerator() |
                            Select-Object -Property @{name='LetterId';expression={$projects[$_.Key]}} |
                            Select-Object -ExpandProperty LetterId |
                            Sort-Object -Property Letter |
                            ForEach-Object {
                                $segments += [OutputSegment]::new($_.Letter, $_.Color)
                            }

                        $segments += [OutputSegment]::new(')')

                        if ($IncludeTransitive) {
                            if ($outputPackageReference.IsDirect) {
                                $segments += [OutputSegment]::new(' [Direct]', 'Magenta')
                            }

                            if ($outputPackageReference.IsTransitive) {
                                $segments += [OutputSegment]::new(' [Transitive]', 'Blue')
                            }
                        }

                        if ($outputPackageReference.IsDeprecated) {
                            $segments += [OutputSegment]::new(' [Deprecated]', 'DarkRed')
                        }

                        if ($outputPackageReference.Vulnerabilities.Count -ne 0) {
                            $outputPackageReference.Vulnerabilities |
                                Sort-Object -Property { $_.Severity.Order } |
                                ForEach-Object {
                                    $advisoryUri = [System.Uri]::new($_.AdvisoryUrl)
                                    $id = $advisoryUri.Segments[-1]
                                    $link = New-Hyperlink -Text "[$id]" -Uri $_.AdvisoryUrl
                                    $segments += [OutputSegment]::new(" $link", $_.Severity.ForegroundColor)
                                }
                        }

                        # The leading comma forces an array of arrays.
                        $packageReferenceSegmentsCollection += ,$segments
                    }

                $packageSegments = @()

                $outputPackageUri = New-Hyperlink -Text $outputPackage.Id -Uri "$nugetPackageUriPrefix$($outputPackage.Id)"
                $packageSegments += [OutputSegment]::new("$($outputPackageUri):")

                if ($packageReferenceSegmentsCollection.Count -eq 1) {
                    $packageSegments += [OutputSegment]::new(' ')
                    $packageSegments += $packageReferenceSegmentsCollection[0]
                    Write-HostSegment -Segments $packageSegments
                } else {
                    Write-HostSegment -Segments $packageSegments
                    foreach ($packageReferenceSegments in $packageReferenceSegmentsCollection) {
                        $packageReferenceSegments = @([OutputSegment]::new('  ')) + $packageReferenceSegments
                        Write-HostSegment -Segments $packageReferenceSegments
                    }
                }
            }

        if ($outputPackages.Keys.Count -gt 0) {
            Write-Host
        }

        $projects.GetEnumerator() |
            ForEach-Object {
                $path = $_.Key
                $letterId = $_.Value

                $segments = @()
                $segments += [OutputSegment]::new($letterId.Letter, $letterId.Color)
                $segments += [OutputSegment]::new(": $path")
                Write-HostSegment -Segments $segments
            }
    }
}
