BeforeAll {
    . $PSScriptRoot/../testing/New-TemporaryDirectory.ps1

    function New-GitRepository {
        param(
            [Parameter(Mandatory)]
            [string] $Path
        )
        process {
            New-Item -ItemType Directory -Path $Path

            $gitDirectoryPath = Join-Path -Path $Path -ChildPath '.git'
            New-Item -ItemType Directory -Path $gitDirectoryPath
        }
    }
}

Describe 'Command Execution' {
    Context 'On Each Child Directory' {
        BeforeEach {
            $basePath = New-TemporaryDirectory

            $fooPath = Join-Path -Path $basePath -ChildPath 'foo'
            New-GitRepository -Path $fooPath

            $barPath = Join-Path -Path $basePath -ChildPath 'bar'
            New-GitRepository $barPath

            $bazPath = Join-Path -Path $basePath -ChildPath 'baz'
            New-GitRepository -Path $bazPath

            Mock Write-GitRepositoryDetail -ModuleName Lance
            Mock git -ModuleName Lance

            Invoke-SubDirectoryGitCommand -Command {fetch} -Path $basePath -NoAheadBehind
        }

        It 'Writes repository detail' {
            Should -Invoke Write-GitRepositoryDetail -ModuleName Lance -ParameterFilter {
                $Path -eq $fooPath -and
                -not $NoHead -and
                $NoAheadBehind
            }

            Should -Invoke Write-GitRepositoryDetail -ModuleName Lance -ParameterFilter {
                $Path -eq $barPath -and
                -not $NoHead -and
                $NoAheadBehind
            }

            Should -Invoke Write-GitRepositoryDetail -ModuleName Lance -ParameterFilter {
                $Path -eq $bazPath -and
                -not $NoHead -and
                $NoAheadBehind
            }
        }

        It 'Invokes Git command' {
            Should -Invoke 'git' -ModuleName Lance -ParameterFilter { "$args" -eq "-C $fooPath fetch" }
            Should -Invoke 'git' -ModuleName Lance -ParameterFilter { "$args" -eq "-C $barPath fetch" }
            Should -Invoke 'git' -ModuleName Lance -ParameterFilter { "$args" -eq "-C $bazPath fetch" }
        }
    }

    Context 'Command-Specific Logic' {
        BeforeEach {
            $basePath = New-TemporaryDirectory

            $childPath = Join-Path -Path $basePath -ChildPath 'child'
            New-GitRepository -Path $childPath

            Mock Write-GitRepositoryDetail -ModuleName Lance
            Mock git -ModuleName Lance
        }

        It 'Trims provided command' {
            Invoke-SubDirectoryGitCommand -Command {  pull  } -Path $basePath
            Should -Invoke 'git' -ModuleName Lance -ParameterFilter { "$args" -eq "-C $childPath pull" }
        }

        It 'Skips execution for noop command' {
            Invoke-SubDirectoryGitCommand -Command { noop } -Path $basePath
            Should -Not -Invoke 'git' -ModuleName Lance -ParameterFilter { "$args" -eq "-C $childPath noop" }
        }
    }

    AfterEach {
        Remove-Item -Path $basePath -Recurse -Force
    }
}
