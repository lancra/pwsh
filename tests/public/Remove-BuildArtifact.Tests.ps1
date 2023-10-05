BeforeAll {
    . $PSScriptRoot/../testing/New-TemporaryDirectory.ps1
}

Describe 'Leaf Directory Exclusion' {
    BeforeEach {
        $rootPath = New-TemporaryDirectory
        $rootArtifactsPath = Join-Path -Path $rootPath -ChildPath 'artifacts'
        $rootBinPath = Join-Path -Path $rootPath -ChildPath 'bin'
        $rootNodePath = Join-Path -Path $rootPath -ChildPath 'node_modules'
        $rootObjPath = Join-Path -Path $rootPath -ChildPath 'obj'

        $nonLeafDirectories = @($rootArtifactsPath, $rootBinPath, $rootNodePath, $rootObjPath)
        foreach ($directory in $nonLeafDirectories) {
            New-Item -ItemType 'Directory' -Path (Join-Path -Path $directory -ChildPath 'artifacts') -Force
            New-Item -ItemType 'Directory' -Path (Join-Path -Path $directory -ChildPath 'bin') -Force
            New-Item -ItemType 'Directory' -Path (Join-Path -Path $directory -ChildPath 'node_modules') -Force
            New-Item -ItemType 'Directory' -Path (Join-Path -Path $directory -ChildPath 'obj') -Force
        }

        Mock Write-Host -ModuleName Lance
    }

    It 'Deletes non-leaf directories only' {
        Remove-BuildArtifact -Path $rootPath

        Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $rootArtifactsPath" }
        Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $rootBinPath" }
        Should -Not -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $rootNodePath" }
        Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $rootObjPath" }
    }

    It 'Deletes non-leaf Node directory when specified' {
        Remove-BuildArtifact -Path $rootPath -IncludeNode
    }

    It 'Does not delete leaf directories' {
        Remove-BuildArtifact -Path $rootPath

        Should -Not -Invoke Write-Host -ModuleName Lance -ParameterFilter {
            $Object -like "Removing $(Join-Path -Path $rootArtifactsPath -ChildPath '*')"
        }

        Should -Not -Invoke Write-Host -ModuleName Lance -ParameterFilter {
            $Object -like "Removing $(Join-Path -Path $rootBinPath -ChildPath '*')"
        }

        Should -Not -Invoke Write-Host -ModuleName Lance -ParameterFilter {
            $Object -like "Removing $(Join-Path -Path $rootNodePath -ChildPath '*')"
        }

        Should -Not -Invoke Write-Host -ModuleName Lance -ParameterFilter {
            $Object -like "Removing $(Join-Path -Path $rootObjPath -ChildPath '*')"
        }
    }

    AfterEach {
        Remove-Item -Path $rootPath -Recurse -Force
    }
}

Describe 'Specific Directory: Artifacts' {
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

        Mock Write-Host -ModuleName Lance
    }

    Context 'Deletion' {
        BeforeEach {
            Remove-BuildArtifact -Path $rootPath
        }

        It 'Deletes the root folder' {
            $rootArtifactsPath | Should -Not -Exist
        }

        It 'Deletes the child folders' {
            $fooArtifactsPath | Should -Not -Exist
            $barArtifactsPath | Should -Not -Exist
        }

        It 'Writes deleted paths to the host' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $rootArtifactsPath" }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $fooArtifactsPath" }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $barArtifactsPath" }
        }

        It 'Does not delete other files' {
            $remainingRootFilePath | Should -Exist
            $remainingFooFilePath | Should -Exist
            $remainingBarFilePath | Should -Exist
        }
    }

    Context 'WhatIf' {
        BeforeEach {
            Remove-BuildArtifact -Path $rootPath -WhatIf
        }

        It 'Does not delete anything' {
            $rootArtifactsPath | Should -Exist
            $fooArtifactsPath | Should -Exist
            $barArtifactsPath | Should -Exist
        }

        It 'Does not write deleted paths to the host' {
            Should -Not -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -like "Removing *" }
        }
    }

    AfterEach {
        Remove-Item -Path $rootPath -Recurse -Force
    }
}

Describe 'Specific Directory: Bin' {
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

        Mock Write-Host -ModuleName Lance
    }

    Context 'Deletion' {
        BeforeEach {
            Remove-BuildArtifact -Path $rootPath
        }

        It 'Deletes the root folder' {
            $rootBinPath | Should -Not -Exist
        }

        It 'Deletes the child folders' {
            $fooBinPath | Should -Not -Exist
            $barBinPath | Should -Not -Exist
        }

        It 'Writes deleted paths to the host' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $rootBinPath" }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $fooBinPath" }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $barBinPath" }
        }

        It 'Does not delete other files' {
            $remainingRootFilePath | Should -Exist
            $remainingFooFilePath | Should -Exist
            $remainingBarFilePath | Should -Exist
        }
    }

    Context 'WhatIf' {
        BeforeEach {
            Remove-BuildArtifact -Path $rootPath -WhatIf
        }

        It 'Does not delete anything' {
            $rootBinPath | Should -Exist
            $fooBinPath | Should -Exist
            $barBinPath | Should -Exist
        }

        It 'Does not write deleted paths to the host' {
            Should -Not -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -like "Removing *" }
        }
    }

    AfterEach {
        Remove-Item -Path $rootPath -Recurse -Force
    }
}

Describe 'Specific Directory: Node' {
    BeforeEach {
        $rootPath = New-TemporaryDirectory
        $rootNodePath = Join-Path -Path $rootPath -ChildPath 'node_modules'

        $fooPath = Join-Path -Path $rootPath -ChildPath 'foo'
        $fooNodePath = Join-Path -Path $fooPath -ChildPath 'node_modules'

        $barPath = Join-Path -Path $rootPath -ChildPath 'bar'
        $barNodePath = Join-Path -Path $barPath -ChildPath 'node_modules'

        New-Item -ItemType 'File' -Path (Join-Path -Path $rootNodePath -ChildPath '1.txt') -Force
        New-Item -ItemType 'File' -Path (Join-Path -Path $fooNodePath -ChildPath '2.txt') -Force
        New-Item -ItemType 'File' -Path (Join-Path -Path $barNodePath -ChildPath '3.txt') -Force

        $remainingRootFilePath = Join-Path -Path $rootPath -ChildPath '4.txt'
        $remainingFooFilePath = Join-Path -Path $fooPath -ChildPath '5.txt'
        $remainingBarFilePath = Join-Path -Path $barPath -ChildPath '6.txt'
        New-Item -ItemType 'File' -Path $remainingRootFilePath -Force
        New-Item -ItemType 'File' -Path $remainingFooFilePath -Force
        New-Item -ItemType 'File' -Path $remainingBarFilePath -Force

        Mock Write-Host -ModuleName Lance
    }

    Context 'Default Deletion (Excluded)' {
        BeforeEach {
            Remove-BuildArtifact -Path $rootPath
        }

        It 'Does not delete the root Node folder' {
            $rootNodePath | Should -Exist
        }

        It 'Does not delete the child Node folders' {
            $fooNodePath | Should -Exist
            $barNodePath | Should -Exist
        }

        It 'Does not delete other files' {
            $remainingRootFilePath | Should -Exist
            $remainingFooFilePath | Should -Exist
            $remainingBarFilePath | Should -Exist
        }
    }

    Context 'Included for Deletion' {
        BeforeEach {
            Remove-BuildArtifact -Path $rootPath -IncludeNode
        }

        It 'Deletes the root Node folder' {
            $rootNodePath | Should -Not -Exist
        }

        It 'Deletes the child Node folders' {
            $fooNodePath | Should -Not -Exist
            $barNodePath | Should -Not -Exist
        }

        It 'Writes deleted paths to the host' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $rootNodePath" }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $fooNodePath" }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $barNodePath" }
        }

        It 'Does not delete other files' {
            $remainingRootFilePath | Should -Exist
            $remainingFooFilePath | Should -Exist
            $remainingBarFilePath | Should -Exist
        }
    }

    AfterEach {
        Remove-Item -Path $rootPath -Recurse -Force
    }
}

Describe 'Specific Directory: Obj' {
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

        Mock Write-Host -ModuleName Lance
    }

    Context 'Deletion' {
        BeforeEach {
            Remove-BuildArtifact -Path $rootPath
        }

        It 'Deletes the root folder' {
            $rootObjPath | Should -Not -Exist
        }

        It 'Deletes the child folders' {
            $fooObjPath | Should -Not -Exist
            $barObjPath | Should -Not -Exist
        }

        It 'Writes deleted paths to the host' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $rootObjPath" }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $fooObjPath" }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq "Removing $barObjPath" }
        }

        It 'Does not delete other files' {
            $remainingRootFilePath | Should -Exist
            $remainingFooFilePath | Should -Exist
            $remainingBarFilePath | Should -Exist
        }
    }

    Context 'WhatIf' {
        BeforeEach {
            Remove-BuildArtifact -Path $rootPath -WhatIf
        }

        It 'Does not delete anything' {
            $rootObjPath | Should -Exist
            $fooObjPath | Should -Exist
            $barObjPath | Should -Exist
        }

        It 'Does not write deleted paths to the host' {
            Should -Not -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -like "Removing *" }
        }
    }

    AfterEach {
        Remove-Item -Path $rootPath -Recurse -Force
    }
}
