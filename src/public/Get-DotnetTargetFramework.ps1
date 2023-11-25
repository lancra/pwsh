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
#>
function Get-DotnetTargetFramework {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '.',
        [Parameter()]
        [string[]]$ExcludeDirectory = @(),
        [switch]$ShowRelative
    )
    begin {
        if (-not (Test-PathExecutable -Executable 'rg')) {
            throw 'ripgrep must be installed and available on the path for this script.'
        }

        # Use the absolute path by default so that the output is more clear for sharing.
        $absolutePath = (Resolve-Path -Path $Path).Path
        if (-not $ShowRelative) {
            $Path = $absolutePath
        }

        $ripgrepArgs = @(
            '--ignore-case',
            '--no-heading',
            '--no-line-number',
            '--only-matching',
            "--replace '`$1'", # Replaces the match with the first regex capturing group (i.e. the XML element value).
            '--sort path',
            '--type msbuild',
            '"<TargetFrameworks?>(.*)</TargetFrameworks?>"',
            $Path
        )
        $ripgrepCommand = "rg $ripgrepArgs"

        # Must match .NET versions on a pattern due to OS-specific target frameworks (e.g. "net6.0-windows").
        # Support policy found at https://dotnet.microsoft.com/en-us/platform/support/policy.
        $supportedVersionPatterns = @(
            'netstandard2.0', # .NET Standard for .NET Core & .NET Framework
            'netstandard2.1', # .NET Standard for .NET Core Only
            'net6.0*', # LTS until 2024-11-12
            'net7.0*', # STS until 2024-05-14
            'net8.0*' # LTS until 2026-11-10
        )

        $supportedVersionAggregatePattern = Join-String -InputObject $supportedVersionPatterns -Separator '|'

        $excludeDirectoryPaths = $ExcludeDirectory |
            ForEach-Object {
                # The empty additional child path forces a separator onto the end of the path. Without a separator, the path could
                # match on slices of strings (e.g. ./foo could match ./foobar while ./foo/ could not).
                Join-Path -Path $absolutePath -ChildPath $_ -AdditionalChildPath ''
            }
    }
    process {
        # Force an array when the output is a single line. <https://superuser.com/a/414666>
        @(Invoke-Command -ScriptBlock ([scriptblock]::Create($ripgrepCommand))) |
            ForEach-Object {
                $match = $_
                $separatorIndex = $match.LastIndexOf(':')
                $path = $match.Substring(0, $separatorIndex)

                foreach ($excludeDirectoryPath in $excludeDirectoryPaths) {
                    if ($path -like "$excludeDirectoryPath*") {
                        return
                    }
                }

                $targetFrameworkCounter = 0
                $targetFrameworks = $match.Substring($separatorIndex + 1) -split ';'

                $segments = @()

                foreach ($targetFramework in $targetFrameworks) {
                    $targetFrameworkCounter++

                    $writeColor = 'Red'
                    if ($targetFramework -match $supportedVersionAggregatePattern) {
                        $writeColor = 'Green'
                    }

                    $segments += [OutputSegment]::new($targetFramework, $writeColor)
                    if ($targetFrameworkCounter -lt ($targetFrameworks.Length)) {
                        $segments += [OutputSegment]::new(';')
                    }
                }

                $segments += [OutputSegment]::new(": $path")
                Write-HostSegment -Segments $segments
            }
    }
}
