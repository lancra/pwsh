function Get-DotnetTargetFramework {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = '.'
    )
    begin {
        if (-not (Test-PathExecutable -Executable 'rg')) {
            throw 'ripgrep must be installed and available on the path for this script.'
        }

        # Use the absolute path so that the output is more clear for sharing.
        if ($Path -eq '.') {
            $Path = Get-Location
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
            'net7.0*' # STS until 2024-05-14
        )

        $supportedVersionAggregatePattern = Join-String -InputObject $supportedVersionPatterns -Separator '|'
    }
    process {
        # Force an array when the output is a single line. <https://superuser.com/a/414666>
        @(Invoke-Command -ScriptBlock ([scriptblock]::Create($ripgrepCommand))) |
            ForEach-Object {
                $match = $_
                $separatorIndex = $match.LastIndexOf(':')
                $path = $match.Substring(0, $separatorIndex)

                $targetFrameworkCounter = 0
                $targetFrameworks = $match.Substring($separatorIndex + 1) -split ';'

                foreach ($targetFramework in $targetFrameworks) {
                    $targetFrameworkCounter++

                    $writeColor = 'Red'
                    if ($targetFramework -match $supportedVersionAggregatePattern) {
                        $writeColor = 'Green'
                    }

                    Write-Host $targetFramework -ForegroundColor $writeColor -NoNewline

                    if ($targetFrameworkCounter -lt ($targetFrameworks.Length)) {
                        Write-Host ';' -NoNewline
                    }
                }

                Write-Host ": $path"
            }
    }
}
