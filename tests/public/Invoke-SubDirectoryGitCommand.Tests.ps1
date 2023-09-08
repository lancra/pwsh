BeforeAll {
    function New-TemporaryDirectory {
        $path = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath (New-Guid).Guid
        New-Item -ItemType Directory -Path $path > $null
        $path
    }
}

Describe 'Command Execution' {
    Context 'On Each Child Directory' {
        BeforeEach {
            $basePath = New-TemporaryDirectory

            $fooPath = Join-Path -Path $basePath -ChildPath 'foo'
            New-Item -ItemType Directory -Path $fooPath

            $barPath = Join-Path -Path $basePath -ChildPath 'bar'
            New-Item -ItemType Directory -Path $barPath

            $bazPath = Join-Path -Path $basePath -ChildPath 'baz'
            New-Item -ItemType Directory -Path $bazPath

            Mock Write-GitRepositoryDetail -ModuleName Lance
            Mock git -ModuleName Lance

            Invoke-SubDirectoryGitCommand -Command {fetch} -Path $basePath -NoAheadBehind
        }

        It 'Writes repository detail' {
            Should -Invoke -Command Write-GitRepositoryDetail -ModuleName 'Lance' -ParameterFilter {
                $Path -eq $fooPath -and
                -not $NoHead -and
                $NoAheadBehind
            }

            Should -Invoke -Command Write-GitRepositoryDetail -ModuleName 'Lance' -ParameterFilter {
                $Path -eq $barPath -and
                -not $NoHead -and
                $NoAheadBehind
            }

            Should -Invoke -Command Write-GitRepositoryDetail -ModuleName 'Lance' -ParameterFilter {
                $Path -eq $bazPath -and
                -not $NoHead -and
                $NoAheadBehind
            }
        }

        It 'Invokes Git command' {
            Should -Invoke -CommandName 'git' -ModuleName 'Lance' -ParameterFilter { "$args" -eq "-C $fooPath fetch" }
            Should -Invoke -CommandName 'git' -ModuleName 'Lance' -ParameterFilter { "$args" -eq "-C $barPath fetch" }
            Should -Invoke -CommandName 'git' -ModuleName 'Lance' -ParameterFilter { "$args" -eq "-C $bazPath fetch" }
        }
    }

    Context 'Command-Specific Logic' {
        BeforeEach {
            $basePath = New-TemporaryDirectory

            $childPath = Join-Path -Path $basePath -ChildPath 'child'
            New-Item -ItemType Directory -Path $childPath

            Mock Write-GitRepositoryDetail -ModuleName Lance
            Mock git -ModuleName Lance
        }

        It 'Trims provided command' {
            Invoke-SubDirectoryGitCommand -Command {  pull  } -Path $basePath
            Should -Invoke -CommandName 'git' -ModuleName 'Lance' -ParameterFilter { "$args" -eq "-C $childPath pull" }
        }

        It 'Skips current branch alias when head is shown' {
            Invoke-SubDirectoryGitCommand -Command { branch-current } -Path $basePath
            Should -Not -Invoke -CommandName 'git' -ModuleName 'Lance' -ParameterFilter { "$args" -eq "-C $childPath branch-current" }
        }

        It 'Executes current branch alias when head is not shown' {
            Invoke-SubDirectoryGitCommand -Command { branch-current } -Path $basePath -NoHead
            Should -Invoke -CommandName 'git' -ModuleName 'Lance' -ParameterFilter { "$args" -eq "-C $childPath branch-current" }
        }
    }

    AfterEach {
        Remove-Item -Path $basePath -Recurse
    }
}
