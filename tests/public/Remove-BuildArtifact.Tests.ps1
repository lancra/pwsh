BeforeAll {
    . $PSScriptRoot/../testing/New-TemporaryDirectory.ps1
}

Describe 'Deletion' {
    Context 'Artifacts' {
        BeforeEach {
            $rootPath = New-TemporaryDirectory
            $rootArtifactsPath = Join-Path -Path $rootPath -ChildPath 'artifacts'

            $fooPath = Join-Path -Path $rootPath -ChildPath 'foo'
            $fooArtifactsPath = Join-Path -Path $fooPath -ChildPath 'artifacts'

            $barPath = Join-Path -Path $rootPath -ChildPath 'bar'
            $barArtifactsPath = Join-Path -Path $barPath -ChildPath 'artifacts'

            New-Item -ItemType 'File' -Path (Join-Path -Path $rootArtifactsPath -ChildPath '1.txt') -Force
            New-Item -ItemType 'File' -Path (Join-Path -Path $fooArtifactsPath -ChildPath '2.txt') -Force
            New-Item -ItemType 'File' -Path (Join-Path -Path $barArtifactsPath -ChildPath '3.txt') -Force

            $remainingRootFilePath = Join-Path -Path $rootPath -ChildPath '4.txt'
            $remainingFooFilePath = Join-Path -Path $fooPath -ChildPath '5.txt'
            $remainingBarFilePath = Join-Path -Path $barPath -ChildPath '6.txt'
            New-Item -ItemType 'File' -Path $remainingRootFilePath -Force
            New-Item -ItemType 'File' -Path $remainingFooFilePath -Force
            New-Item -ItemType 'File' -Path $remainingBarFilePath -Force

            Mock Write-Host -ModuleName 'Lance'

            Remove-BuildArtifact -Path $rootPath
        }

        It 'Deletes the root artifacts folder' {
            $rootArtifactsPath | Should -Not -Exist
        }

        It 'Deletes the child artifacts folders' {
            $fooArtifactsPath | Should -Not -Exist
            $barArtifactsPath | Should -Not -Exist
        }

        It 'Writes deleted paths to the host' {
            Should -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $rootArtifactsPath" }
            Should -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $fooArtifactsPath" }
            Should -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $barArtifactsPath" }
        }

        It 'Does not delete other files' {
            $remainingRootFilePath | Should -Exist
            $remainingFooFilePath | Should -Exist
            $remainingBarFilePath | Should -Exist
        }

        AfterEach {
            Remove-Item -Path $rootPath -Recurse -Force
        }
    }

    Context 'Bin' {
        BeforeEach {
            $rootPath = New-TemporaryDirectory
            $rootBinPath = Join-Path -Path $rootPath -ChildPath 'bin'

            $fooPath = Join-Path -Path $rootPath -ChildPath 'foo'
            $fooBinPath = Join-Path -Path $fooPath -ChildPath 'bin'

            $barPath = Join-Path -Path $rootPath -ChildPath 'bar'
            $barBinPath = Join-Path -Path $barPath -ChildPath 'bin'

            New-Item -ItemType 'File' -Path (Join-Path -Path $rootBinPath -ChildPath '1.txt') -Force
            New-Item -ItemType 'File' -Path (Join-Path -Path $fooBinPath -ChildPath '2.txt') -Force
            New-Item -ItemType 'File' -Path (Join-Path -Path $barBinPath -ChildPath '3.txt') -Force

            $remainingRootFilePath = Join-Path -Path $rootPath -ChildPath '4.txt'
            $remainingFooFilePath = Join-Path -Path $fooPath -ChildPath '5.txt'
            $remainingBarFilePath = Join-Path -Path $barPath -ChildPath '6.txt'
            New-Item -ItemType 'File' -Path $remainingRootFilePath -Force
            New-Item -ItemType 'File' -Path $remainingFooFilePath -Force
            New-Item -ItemType 'File' -Path $remainingBarFilePath -Force

            Mock Write-Host -ModuleName 'Lance'

            Remove-BuildArtifact -Path $rootPath
        }

        It 'Deletes the root bin folder' {
            $rootBinPath | Should -Not -Exist
        }

        It 'Deletes the child bin folders' {
            $fooBinPath | Should -Not -Exist
            $barBinPath | Should -Not -Exist
        }

        It 'Writes deleted paths to the host' {
            Should -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $rootBinPath" }
            Should -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $fooBinPath" }
            Should -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $barBinPath" }
        }

        It 'Does not delete other files' {
            $remainingRootFilePath | Should -Exist
            $remainingFooFilePath | Should -Exist
            $remainingBarFilePath | Should -Exist
        }

        AfterEach {
            Remove-Item -Path $rootPath -Recurse -Force
        }
    }

    Context 'Obj' {
        BeforeEach {
            $rootPath = New-TemporaryDirectory
            $rootObjPath = Join-Path -Path $rootPath -ChildPath 'obj'

            $fooPath = Join-Path -Path $rootPath -ChildPath 'foo'
            $fooObjPath = Join-Path -Path $fooPath -ChildPath 'obj'

            $barPath = Join-Path -Path $rootPath -ChildPath 'bar'
            $barObjPath = Join-Path -Path $barPath -ChildPath 'obj'

            New-Item -ItemType 'File' -Path (Join-Path -Path $rootObjPath -ChildPath '1.txt') -Force
            New-Item -ItemType 'File' -Path (Join-Path -Path $fooObjPath -ChildPath '2.txt') -Force
            New-Item -ItemType 'File' -Path (Join-Path -Path $barObjPath -ChildPath '3.txt') -Force

            $remainingRootFilePath = Join-Path -Path $rootPath -ChildPath '4.txt'
            $remainingFooFilePath = Join-Path -Path $fooPath -ChildPath '5.txt'
            $remainingBarFilePath = Join-Path -Path $barPath -ChildPath '6.txt'
            New-Item -ItemType 'File' -Path $remainingRootFilePath -Force
            New-Item -ItemType 'File' -Path $remainingFooFilePath -Force
            New-Item -ItemType 'File' -Path $remainingBarFilePath -Force

            Mock Write-Host -ModuleName 'Lance'

            Remove-BuildArtifact -Path $rootPath
        }

        It 'Deletes the root obj folder' {
            $rootObjPath | Should -Not -Exist
        }

        It 'Deletes the child obj folders' {
            $fooObjPath | Should -Not -Exist
            $barObjPath | Should -Not -Exist
        }

        It 'Writes deleted paths to the host' {
            Should -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $rootObjPath" }
            Should -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $fooObjPath" }
            Should -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $barObjPath" }
        }

        It 'Does not delete other files' {
            $remainingRootFilePath | Should -Exist
            $remainingFooFilePath | Should -Exist
            $remainingBarFilePath | Should -Exist
        }

        AfterEach {
            Remove-Item -Path $rootPath -Recurse -Force
        }
    }

    Context 'WhatIf' {
        BeforeEach {
            $rootPath = New-TemporaryDirectory
            $artifactsPath = Join-Path -Path $rootPath -ChildPath 'artifacts'
            $binPath = Join-Path -Path $rootPath -ChildPath 'bin'
            $objPath = Join-Path -Path $rootPath -ChildPath 'obj'

            New-Item -ItemType 'Directory' -Path $artifactsPath -Force
            New-Item -ItemType 'Directory' -Path $binPath -Force
            New-Item -ItemType 'Directory' -Path $objPath -Force

            Mock Write-Host -ModuleName 'Lance'

            Remove-BuildArtifact -Path $rootPath -WhatIf
        }

        It 'Does not delete anything' {
            $artifactsPath | Should -Exist
            $binPath | Should -Exist
            $objPath | Should -Exist
        }

        It 'Does not write deleted paths to the host' {
            Should -Not -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $artifactsPath" }
            Should -Not -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $binPath" }
            Should -Not -Invoke -Command Write-Host -ModuleName 'Lance' -ParameterFilter { $Object -eq "Removing $objPath" }
        }

        AfterEach {
            Remove-Item -Path $rootPath -Recurse -Force
        }
    }
}
