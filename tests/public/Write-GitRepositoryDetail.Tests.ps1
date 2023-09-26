BeforeAll {
    . $PSScriptRoot/../testing/New-TemporaryDirectory.ps1

    # Setup template remote repository.
    $remoteTemplatePath = New-TemporaryDirectory
    git -C $remoteTemplatePath init --initial-branch=main
    git -C $remoteTemplatePath config --local user.email "testuser@example.org"
    git -C $remoteTemplatePath config --local user.name "Test User"

    'foo' > (Join-Path -Path $remoteTemplatePath -ChildPath 'foo.txt')
    git -C $remoteTemplatePath add 'foo.txt'
    git -C $remoteTemplatePath commit -m 'Add foo'

    'bar' > (Join-Path -Path $remoteTemplatePath -ChildPath 'bar.txt')
    git -C $remoteTemplatePath add 'bar.txt'
    git -C $remoteTemplatePath commit -m 'Add bar'

    # Setup template local repository.
    $localTemplatePath = New-TemporaryDirectory
    git clone "$remoteTemplatePath/.git" $localTemplatePath *> $null
    git -C $localTemplatePath config --local user.email "testuser@example.org"
    git -C $localTemplatePath config --local user.name "Test User"
}

Describe 'Expected Output' {
    BeforeEach {
        $remotePath = New-TemporaryDirectory
        $remoteTemplateCopyPath = Join-Path -Path $remoteTemplatePath -ChildPath '*'
        Copy-Item -Path $remoteTemplateCopyPath -Destination $remotePath -Recurse -Force

        $localPath = New-TemporaryDirectory
        $localTemplateCopyPath = Join-Path -Path $localTemplatePath -ChildPath '*'
        Copy-Item -Path $localTemplateCopyPath -Destination $localPath -Recurse -Force
        git -C $localPath remote set-url origin "$remotePath/.git"

        Mock Write-Host -ModuleName Lance
    }

    Context 'Default Repository' {
        It 'Shows repository, head, and ahead/behind' {
            Write-GitRepositoryDetail -Path $localPath

            $expectedRepository = Split-Path -Path $localPath -Leaf
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq $expectedRepository -and
                $ForegroundColor -eq 'Yellow'
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ' (' -and $NoNewline -eq $true }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq 'main' -and
                $ForegroundColor -eq 'Blue' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' +0' -and
                $ForegroundColor -eq 'Green' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' -0' -and
                $ForegroundColor -eq 'Red' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ')' -and $NoNewline -eq $true }
        }

        It 'Excludes head when specified' {
            Write-GitRepositoryDetail -Path $localPath -NoHead

            $expectedRepository = Split-Path -Path $localPath -Leaf
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq $expectedRepository -and
                $ForegroundColor -eq 'Yellow'
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ' (' -and $NoNewline -eq $true }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq 'main' -and
                $ForegroundColor -eq 'Blue' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq '+0' -and
                $ForegroundColor -eq 'Green' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' -0' -and
                $ForegroundColor -eq 'Red' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ')' -and $NoNewline -eq $true }
        }

        It 'Excludes ahead/behind when specified' {
            Write-GitRepositoryDetail -Path $localPath -NoAheadBehind

            $expectedRepository = Split-Path -Path $localPath -Leaf
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq $expectedRepository -and
                $ForegroundColor -eq 'Yellow'
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ' (' -and $NoNewline -eq $true }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq 'main' -and
                $ForegroundColor -eq 'Blue' -and
                $NoNewline -eq $true
            }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' +0' -and
                $ForegroundColor -eq 'Green' -and
                $NoNewline -eq $true
            }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' -0' -and
                $ForegroundColor -eq 'Red' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ')' -and $NoNewline -eq $true }
        }

        It 'Excludes head and ahead/behind when specified' {
            Write-GitRepositoryDetail -Path $localPath -NoHead -NoAheadBehind

            $expectedRepository = Split-Path -Path $localPath -Leaf
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq $expectedRepository -and
                $ForegroundColor -eq 'Yellow'
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ':' -and $NoNewline -eq $true }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ' (' -and $NoNewline -eq $true }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq 'main' -and
                $ForegroundColor -eq 'Blue' -and
                $NoNewline -eq $true
            }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' +0' -and
                $ForegroundColor -eq 'Green' -and
                $NoNewline -eq $true
            }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' -0' -and
                $ForegroundColor -eq 'Red' -and
                $NoNewline -eq $true
            }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ')' -and $NoNewline -eq $true }
        }
    }

    Context 'Modified Local' {
        It 'Shows correct head' {
            git -C $localPath switch -c 'fancy-new-branch' *> $null
            git -C $localPath push -u origin fancy-new-branch *> $null

            Write-GitRepositoryDetail -Path $localPath

            $expectedRepository = Split-Path -Path $localPath -Leaf
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq $expectedRepository -and
                $ForegroundColor -eq 'Yellow'
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ' (' -and $NoNewline -eq $true }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq 'fancy-new-branch' -and
                $ForegroundColor -eq 'Blue' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' +0' -and
                $ForegroundColor -eq 'Green' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' -0' -and
                $ForegroundColor -eq 'Red' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ')' -and $NoNewline -eq $true }
        }

        It 'Shows detached head correctly' {
            $firstCommitId = (git -C $localPath rev-list --max-parents=0 HEAD)
            git -C $localPath switch --detach $firstCommitId *> $null

            Write-GitRepositoryDetail -Path $localPath

            $expectedRepository = Split-Path -Path $localPath -Leaf
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq $expectedRepository -and
                $ForegroundColor -eq 'Yellow'
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ' (' -and $NoNewline -eq $true }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq '(detached)' -and
                $ForegroundColor -eq 'Blue' -and
                $NoNewline -eq $true
            }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' +0' -and
                $ForegroundColor -eq 'Green' -and
                $NoNewline -eq $true
            }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' -0' -and
                $ForegroundColor -eq 'Red' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ')' -and $NoNewline -eq $true }
        }

        It 'Excludes ahead/behind for local branch' {
            git -C $localPath switch -c 'fancy-new-branch' *> $null

            Write-GitRepositoryDetail -Path $localPath

            $expectedRepository = Split-Path -Path $localPath -Leaf
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq $expectedRepository -and
                $ForegroundColor -eq 'Yellow'
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ' (' -and $NoNewline -eq $true }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq 'fancy-new-branch' -and
                $ForegroundColor -eq 'Blue' -and
                $NoNewline -eq $true
            }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' +0' -and
                $ForegroundColor -eq 'Green' -and
                $NoNewline -eq $true
            }
            Should -Not -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' -0' -and
                $ForegroundColor -eq 'Red' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ')' -and $NoNewline -eq $true }
        }

        It 'Shows correct ahead' {
            'baz' > (Join-Path -Path $localPath -ChildPath 'baz.txt')
            git -C $localPath add 'baz.txt'
            git -C $localPath commit -m 'Add baz'

            'qux' > (Join-Path -Path $localPath -ChildPath 'qux.txt')
            git -C $localPath add 'qux.txt'
            git -C $localPath commit -m 'Add qux'

            Write-GitRepositoryDetail -Path $localPath

            $expectedRepository = Split-Path -Path $localPath -Leaf
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq $expectedRepository -and
                $ForegroundColor -eq 'Yellow'
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ' (' -and $NoNewline -eq $true }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq 'main' -and
                $ForegroundColor -eq 'Blue' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' +2' -and
                $ForegroundColor -eq 'Green' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' -0' -and
                $ForegroundColor -eq 'Red' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ')' -and $NoNewline -eq $true }
        }
    }

    Context 'Modified Remote' {
        It 'Shows correct behind' {
            'baz' > (Join-Path -Path $remotePath -ChildPath 'baz.txt')
            git -C $remotePath add 'baz.txt'
            git -C $remotePath commit -m 'Add baz'

            git -C $localPath fetch *> $null

            Write-GitRepositoryDetail -Path $localPath

            $expectedRepository = Split-Path -Path $localPath -Leaf
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq $expectedRepository -and
                $ForegroundColor -eq 'Yellow'
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ' (' -and $NoNewline -eq $true }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq 'main' -and
                $ForegroundColor -eq 'Blue' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' +0' -and
                $ForegroundColor -eq 'Green' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter {
                $Object -eq ' -1' -and
                $ForegroundColor -eq 'Red' -and
                $NoNewline -eq $true
            }
            Should -Invoke Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq ')' -and $NoNewline -eq $true }
        }
    }

    AfterEach {
        Remove-Item -Path $remotePath -Recurse -Force > $null
        Remove-Item -Path $localPath -Recurse -Force > $null
    }
}

AfterAll {
    Remove-Item -Path $remoteTemplatePath -Recurse -Force > $null
    Remove-Item -Path $localTemplatePath -Recurse -Force > $null
}
