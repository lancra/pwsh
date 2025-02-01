<#
.SYNOPSIS
Retrieves the target framework version(s) for one or more MS Build files.

.DESCRIPTION
Uses ripgrep to identity the TargetFramework or TargetFrameworks property for
all MS Build files in a directory. It then extracts the value and compares to a
static list of current versions, so that outdated versions are clearly
identified in the output.

.PARAMETER Path
The directory to search in. The current directory is used if no value is
provided.

.PARAMETER ExcludeDirectory
The directory name(s) to exclude from the output. They must be represented as
children of the provided path.

.PARAMETER ShowRelative
Disables conversion of relative paths to absolute paths.

.PARAMETER Format
The output format for the results. The default is Human.

.EXAMPLE
Get-DotnetTargetFramework C:\Projects

Gets .NET target framework for a directory.

.EXAMPLE
Get-DotnetTargetFramework

Gets .NET target framework for the current directory.

.EXAMPLE
Get-DotnetTargetFramework -Path C:\Projects -ExcludeDirectory ToDo

Excludes the C:\Projects\ToDo directory from the output.

.EXAMPLE
Get-DotnetTargetFramework -Path . -ShowRelative

Outputs relative paths instead of converting them to absolute paths.

.EXAMPLE
Get-DotnetTargetFramework -Path . -Format Json

Outputs results as a JSON array.
#>
function Get-DotnetTargetFramework {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '.',
        [Parameter()]
        [string[]]$ExcludeDirectory = @(),
        [switch]$ShowRelative,
        [Parameter()]
        [ValidateSet('Human', 'Json')]
        [string]$Format = 'Human'
    )
    begin {
        class ProjectTargetFramework {
            [string] $Value
            [bool] $Supported

            ProjectTargetFramework([string] $value, [bool] $supported) {
                $this.Value = $value
                $this.Supported = $supported
            }
        }

        class Project {
            [string] $Path
            [ProjectTargetFramework[]] $TargetFrameworks

            Project([string] $path, [ProjectTargetFramework[]] $targetFrameworks) {
                $this.Path = $path
                $this.TargetFrameworks = $targetFrameworks
            }
        }

        class ProjectList {
            [Project[]] $Projects

            [string] ToJson() {
                $options = [System.Text.Json.JsonSerializerOptions]@{
                    PropertyNamingPolicy = [System.Text.Json.JsonNamingPolicy]::CamelCase
                    WriteIndented = $true
                }

                return [System.Text.Json.JsonSerializer]::Serialize($this.Projects, $options)
            }

            ProjectList([Project[]] $projects) {
                $this.Projects = $projects
            }
        }

        function Write-ProjectHuman {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [Project] $Project
            )
            process {
                $targetFrameworkCounter = 0
                $segments = @()

                foreach ($targetFramework in $Project.TargetFrameworks) {
                    $targetFrameworkCounter++

                    $writeColor = $targetFramework.Supported ? 'Green' : 'Red'
                    $segments += [OutputSegment]::new($targetFramework.Value, $writeColor)

                    if ($targetFrameworkCounter -lt ($Project.TargetFrameworks.Length)) {
                        $segments += [OutputSegment]::new(';')
                    }
                }

                $targetFrameworkValuesString = ($Project.TargetFrameworks | Select-Object -ExpandProperty Value) -join ';'
                $targetFrameworksLength = $targetFrameworkValuesString.Length
                $paddingSpaces = [string]::new(' ', $maximumTargetFrameworksLength - $targetFrameworksLength)

                $segments += [OutputSegment]::new(": $paddingSpaces$($Project.Path)")
                Write-HostSegment -Segments $segments
            }
        }

        if (-not (Test-PathExecutable -Executable 'rg')) {
            throw 'ripgrep must be installed and available on the path for this script.'
        }

        # Use the absolute path by default for clarity. A trailing separator is forced onto the end of the path via the empty child
        # path so that relative path outputs do not begin with a leading separator.
        $Path = Join-Path -Path (Resolve-Path -Path $Path).Path -ChildPath ''

        $ripgrepArgs = @(
            '--ignore-case',
            '--no-heading',
            '--no-line-number',
            '--only-matching',
            "--replace '`$1'", # Replaces the match with the first regex capturing group (i.e. the XML element value).
            '--type msbuild',
            '"<TargetFrameworks?.*?>(.*)</TargetFrameworks?.*?>"',
            $Path
        )
        $ripgrepCommand = "rg $ripgrepArgs"

        # Must match .NET versions on a pattern due to OS-specific target frameworks (e.g. "net6.0-windows").
        # Support policy found at https://dotnet.microsoft.com/en-us/platform/support/policy.
        $supportedVersionPatterns = @(
            'netstandard2\.0', # .NET Standard for .NET Core & .NET Framework
            'netstandard2\.1', # .NET Standard for .NET Core Only
            'net6\.0.*', # LTS until 2024-11-12
            'net7\.0.*', # STS until 2024-05-14
            'net8\.0.*', # LTS until 2026-11-10
            'v4\.6\.2', # Until 2027-01-12
            'v4\.7.*',
            'v4\.8.*'
        )

        $supportedVersionAggregatePattern = Join-String -InputObject $supportedVersionPatterns -Separator '|'

        $excludeDirectoryPaths = $ExcludeDirectory |
            ForEach-Object {
                # The empty additional child path forces a separator onto the end of the path. Without a separator, the path could
                # match on slices of strings (e.g. ./foo could match ./foobar while ./foo/ could not).
                Join-Path -Path $Path -ChildPath $_ -AdditionalChildPath ''
            }
    }
    process {
        $maximumTargetFrameworksLength = 0

        # Force an array when the output is a single line. <https://superuser.com/a/414666>
        $projects = @(Invoke-Command -ScriptBlock ([scriptblock]::Create($ripgrepCommand))) |
            ForEach-Object {
                $match = $_
                $separatorIndex = $match.LastIndexOf(':')

                $matchPath = $match.Substring(0, $separatorIndex)
                foreach ($excludeDirectoryPath in $excludeDirectoryPaths) {
                    if ($matchPath -like "$excludeDirectoryPath*") {
                        return
                    }
                }

                if ($ShowRelative) {
                    $matchPath = $matchPath.Replace($Path, '')
                }

                $targetFrameworkValuesString = $match.Substring($separatorIndex + 1)
                if ($targetFrameworkValuesString.Length -gt $maximumTargetFrameworksLength) {
                    $maximumTargetFrameworksLength = $targetFrameworkValuesString.Length
                }

                $targetFrameworks = $targetFrameworkValuesString -split ';' |
                    ForEach-Object {
                        [ProjectTargetFramework]::new($_, $_ -match $supportedVersionAggregatePattern)
                    }

                [Project]::new($matchPath, $targetFrameworks)
            } |
            Sort-Object -Property { [regex]::Replace($_.Path, '\d+|\\|/', { $args[0].Value.PadLeft(5) }) }
        $projectList = [ProjectList]::new($projects)

        if ($Format -eq 'Human') {
            $projects |
                ForEach-Object {
                    Write-ProjectHuman -Project $_
                }
        } elseif ($Format -eq 'Json') {
            $projectList.ToJson() |
                Write-Output
        }
    }
}
