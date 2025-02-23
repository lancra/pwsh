BeforeAll {
    . $PSScriptRoot/../testing/New-TemporaryDirectory.ps1

    function New-MSBuildFile {
        param(
            [Parameter(Mandatory)]
            [string]$Path,

            [Parameter(Mandatory)]
            [string]$Contents
        )
        process {
            New-Item -ItemType File -Path $Path -Force
            Out-File -FilePath $Path -InputObject $Contents
        }
    }

    $script:ripgrepConfigPath = $env:RIPGREP_CONFIG_PATH
    $env:RIPGREP_CONFIG_PATH = (Resolve-Path -Path './tests/testing/rg_config').Path
}

Describe 'Error Checking' {
    It 'Fails when ripgrep is unavailable' {
        Mock Test-PathExecutable { $false } -ParameterFilter { $Executable -eq 'rg' } -ModuleName Lance
        { Get-DotnetTargetFramework } | Should -Throw
    }
}

Describe 'Output' {
    BeforeEach {
        $script:basePath = New-TemporaryDirectory
    }

    Context 'Relative Path' {
        BeforeEach {
            $script:originalLocation = Get-Location

            $innerDirectoryName = 'inner'
            $innerDirectoryPath = Join-Path -Path $script:basePath -ChildPath $innerDirectoryName
            New-Item -ItemType Directory -Path $innerDirectoryPath

            $projectName = 'Project.csproj'
            $projectPath = Join-Path $innerDirectoryPath -ChildPath $projectName
            New-MSBuildFile -Path $projectPath -Contents '<TargetFramework>foo</TargetFramework>'

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance
        }

        It 'Converts current directory relative path to absolute' {
            Set-Location $script:basePath
            Get-DotnetTargetFramework -Path '.'
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 2
            $writeHostInvocationLines[0] | Should -Be "foo: $projectPath"
            $writeHostInvocationLines[1] | Should -Be ''
        }

        It 'Converts current directory prefixed relative path to absolute' {
            Set-Location $script:basePath
            Get-DotnetTargetFramework -Path "./$innerDirectoryName"
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 2
            $writeHostInvocationLines[0] | Should -Be "foo: $projectPath"
            $writeHostInvocationLines[1] | Should -Be ''
        }

        It 'Converts parent directory relative path to absolute' {
            Set-Location $innerDirectoryPath
            Get-DotnetTargetFramework -Path '..'
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 2
            $writeHostInvocationLines[0] | Should -Be "foo: $projectPath"
            $writeHostInvocationLines[1] | Should -Be ''
        }

        It 'Converts parent directory prefixed relative path to absolute' {
            Set-Location $innerDirectoryPath
            Get-DotnetTargetFramework -Path "../$innerDirectoryName"
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 2
            $writeHostInvocationLines[0] | Should -Be "foo: $projectPath"
            $writeHostInvocationLines[1] | Should -Be ''
        }

        It 'Does not convert current directory relative path to absolute when relative is requested' {
            Set-Location $script:basePath
            $expectedPath = Join-Path -Path $innerDirectoryName -ChildPath $projectName

            Get-DotnetTargetFramework -Path '.' -ShowRelative
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 2
            $writeHostInvocationLines[0] | Should -Be "foo: $expectedPath"
            $writeHostInvocationLines[1] | Should -Be ''
        }

        It 'Does not convert current directory prefixed relative path to absolute when relative is requested' {
            Set-Location $script:basePath
            $path = Join-Path -Path '.' -ChildPath $innerDirectoryName
            $expectedPath = $projectName

            Get-DotnetTargetFramework -Path $path -ShowRelative
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 2
            $writeHostInvocationLines[0] | Should -Be "foo: $expectedPath"
            $writeHostInvocationLines[1] | Should -Be ''
        }

        It 'Does not convert parent directory relative path to absolute when relative is requested' {
            Set-Location $innerDirectoryPath
            $expectedPath = Join-Path -Path $innerDirectoryName -ChildPath $projectName

            Get-DotnetTargetFramework -Path '..' -ShowRelative
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 2
            $writeHostInvocationLines[0] | Should -Be "foo: $expectedPath"
            $writeHostInvocationLines[1] | Should -Be ''
        }

        It 'Does not convert parent directory prefixed relative path to absolute when relative is requested' {
            Set-Location $innerDirectoryPath
            $path = Join-Path -Path '..' -ChildPath $innerDirectoryName
            $expectedPath = $projectName

            Get-DotnetTargetFramework -Path $path -ShowRelative
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 2
            $writeHostInvocationLines[0] | Should -Be "foo: $expectedPath"
            $writeHostInvocationLines[1] | Should -Be ''
        }

        AfterEach {
            Set-Location $script:originalLocation
        }
    }

    Context 'Recursive Search' {
        BeforeEach {
            $projectPath = Join-Path -Path $script:basePath -ChildPath '111' -AdditionalChildPath 'Project.csproj'
            New-MSBuildFile -Path $projectPath -Contents '<TargetFramework>foo</TargetFramework>'

            $propertiesPath = Join-Path -Path $script:basePath -ChildPath '222' -AdditionalChildPath 'Properties.props'
            New-MSBuildFile -Path $propertiesPath -Contents '<TargetFrameworks>bar;baz</TargetFrameworks>'

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetTargetFramework -Path $script:basePath
            $script:writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'
        }

        It 'Finds project file' {
            $writeHostInvocationLines[0] | Should -Be "foo:     $projectPath"
        }

        It 'Finds properties file' {
            $writeHostInvocationLines[1] | Should -Be "bar;baz: $propertiesPath"
        }
    }

    Context 'Coloring' {
        BeforeEach {
            $unknownProjectPath = Join-Path -Path $script:basePath -ChildPath 'Unknown.csproj'
            New-MSBuildFile -Path $unknownProjectPath -Contents '<TargetFramework>foo</TargetFramework>'

            $unknownPropertiesPath = Join-Path -Path $script:basePath -ChildPath 'Unknown.props'
            New-MSBuildFile -Path $unknownPropertiesPath -Contents '<TargetFrameworks>bar;baz</TargetFrameworks>'

            $outdatedProjectPath = Join-Path -Path $script:basePath -ChildPath 'Outdated.csproj'
            New-MSBuildFile -Path $outdatedProjectPath -Contents '<TargetFramework>net5.0</TargetFramework>'

            $outdatedFrameworkProjectPath = Join-Path -Path $script:basePath -ChildPath 'OutdatedFramework.csproj'
            New-MSBuildFile -Path $outdatedFrameworkProjectPath -Contents '<TargetFrameworkVersion>v4.5.2</TargetFrameworkVersion>'

            $outdatedPropertiesPath = Join-Path -Path $script:basePath -ChildPath 'Outdated.props'
            New-MSBuildFile -Path $outdatedPropertiesPath -Contents '<TargetFrameworks>netcoreapp3.1;net5.0-windows</TargetFrameworks>'

            $currentProjectPath = Join-Path -Path $script:basePath -ChildPath 'Current.csproj'
            New-MSBuildFile -Path $currentProjectPath -Contents '<TargetFramework>net8.0</TargetFramework>'

            $currentFrameworkProjectPath = Join-Path -Path $script:basePath -ChildPath 'CurrentFramework.csproj'
            New-MSBuildFile -Path $currentFrameworkProjectPath -Contents '<TargetFrameworkVersion>v4.7.2</TargetFrameworkVersion>'

            $currentPropertiesPath = Join-Path -Path $script:basePath -ChildPath 'Current.props'
            New-MSBuildFile -Path $currentPropertiesPath -Contents '<TargetFrameworks>net8.0-android;net9.0</TargetFrameworks>'

            Mock Write-Host -ModuleName Lance

            Get-DotnetTargetFramework -Path $script:basePath
        }

        It 'Writes unknown versions using red font' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Red' -and $Object -eq 'foo' }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Red' -and $Object -eq 'bar' }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Red' -and $Object -eq 'baz' }
        }

        It 'Writes outdated versions using red font' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Red' -and
                $Object -eq 'netcoreapp3.1'
            }

            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Red' -and
                $Object -eq 'v4.5.2'
            }

            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Red' -and $Object -eq 'net5.0' }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Red' -and
                $Object -eq 'net5.0-windows'
            }
        }

        It 'Writes current versions using green font' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Green' -and $Object -eq 'net8.0' }

            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Green' -and
                $Object -eq 'v4.7.2'
            }

            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Green' -and
                $Object -eq 'net8.0-android'
            }

            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Green' -and $Object -eq 'net9.0' }
        }
    }

    Context 'Exclusions' {
        BeforeEach {
            $projectName = 'Project.csproj'
            $projectContents = '<TargetFramework>version</TargetFramework>'

            $fooDirectoryName = 'foo'
            $fooDirectoryPath = Join-Path -Path $script:basePath -ChildPath $fooDirectoryName
            $fooProjectPath = Join-Path -Path $fooDirectoryPath -ChildPath $projectName
            New-Item -ItemType Directory -Path $fooDirectoryPath
            New-MSBuildFile -Path $fooProjectPath -Contents $projectContents

            $barDirectoryName = 'bar'
            $barDirectoryPath = Join-Path -Path $script:basePath -ChildPath $barDirectoryName
            $barProjectPath = Join-Path -Path $barDirectoryPath -ChildPath $projectName
            New-Item -ItemType Directory -Path $barDirectoryPath
            New-MSBuildFile -Path $barProjectPath -Contents $projectContents

            $bazDirectoryName = 'baz'
            $bazDirectoryPath = Join-Path -Path $barDirectoryPath -ChildPath $bazDirectoryName
            $bazProjectPath = Join-Path -Path $bazDirectoryPath -ChildPath $projectName
            New-Item -ItemType Directory -Path $bazDirectoryPath
            New-MSBuildFile -Path $bazProjectPath -Contents $projectContents

            $foobarDirectoryName = 'foobar'
            $foobarDirectoryPath = Join-Path -Path $script:basePath -ChildPath $foobarDirectoryName
            $foobarProjectPath = Join-Path -Path $foobarDirectoryPath -ChildPath $projectName
            New-Item -ItemType Directory -Path $foobarDirectoryPath
            New-MSBuildFile -Path $foobarProjectPath -Contents $projectContents

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance
        }

        It 'Includes every match by default' {
            Get-DotnetTargetFramework -Path $script:basePath
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 5

            $writeHostInvocationLines[0] | Should -Be "version: $bazProjectPath"
            $writeHostInvocationLines[1] | Should -Be "version: $barProjectPath"
            $writeHostInvocationLines[2] | Should -Be "version: $fooProjectPath"
            $writeHostInvocationLines[3] | Should -Be "version: $foobarProjectPath"
            $writeHostInvocationLines[4] | Should -Be ''
        }

        Context 'Partial Match' {
            BeforeEach {
                Get-DotnetTargetFramework -Path $script:basePath -ExcludeDirectory $fooDirectoryName
                $script:writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'
            }

            It 'Excludes directory based on exact name' {
                $writeHostInvocationLines | Should -Not -Contain "version: $fooProjectPath"
            }

            It 'Does not exclude partially matched directory' {
                $writeHostInvocationLines | Should -Contain "version: $foobarProjectPath"
            }

            It 'Includes other directories' {
                $writeHostInvocationLines | Should -Contain "version: $barProjectPath"
                $writeHostInvocationLines | Should -Contain "version: $bazProjectPath"
            }
        }

        It 'Excludes multiple specified directories' {
            Get-DotnetTargetFramework -Path $script:basePath -ExcludeDirectory @($fooDirectoryName, $foobarDirectoryName)
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines | Should -Not -Contain "version: $fooProjectPath"
            $writeHostInvocationLines | Should -Contain "version: $barProjectPath"
            $writeHostInvocationLines | Should -Contain "version: $bazProjectPath"
            $writeHostInvocationLines | Should -Not -Contain "version: $foobarProjectPath"
        }

        It 'Excludes ancestors of specified directories' {
            Get-DotnetTargetFramework -Path $script:basePath -ExcludeDirectory $barDirectoryName
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines | Should -Contain "version: $fooProjectPath"
            $writeHostInvocationLines | Should -Not -Contain "version: $barProjectPath"
            $writeHostInvocationLines | Should -Not -Contain "version: $bazProjectPath"
            $writeHostInvocationLines | Should -Contain "version: $foobarProjectPath"
        }
    }

    Context 'Sorting' {
        BeforeEach {
            $projectContents = '<TargetFramework>net8.0</TargetFramework>'

            $thirdProjectPath = Join-Path -Path $script:basePath -ChildPath 'C' -AdditionalChildPath 'Project.csproj'
            New-MSBuildFile -Path $thirdProjectPath -Contents $projectContents

            $secondProjectPath = Join-Path -Path $script:basePath -ChildPath 'B' -AdditionalChildPath 'Project.csproj'
            New-MSBuildFile -Path $secondProjectPath -Contents $projectContents

            $firstProjectPath = Join-Path -Path $script:basePath -ChildPath 'A' -AdditionalChildPath 'Project.csproj'
            New-MSBuildFile -Path $firstProjectPath -Contents $projectContents

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance
        }

        It 'Sorts results by path' {
            Get-DotnetTargetFramework -Path $script:basePath
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 4

            $writeHostInvocationLines[0] | Should -Be "net8.0: $firstProjectPath"
            $writeHostInvocationLines[1] | Should -Be "net8.0: $secondProjectPath"
            $writeHostInvocationLines[2] | Should -Be "net8.0: $thirdProjectPath"
            $writeHostInvocationLines[3] | Should -Be ''
        }
    }

    Context 'Padding' {
        BeforeEach {
            $singleDotnetProjectPath = Join-Path -Path $script:basePath -ChildPath '1.csproj'
            New-MSBuildFile -Path $singleDotnetProjectPath -Contents '<TargetFramework>net8.0</TargetFramework>'

            $multipleDotnetProjectPath = Join-Path -Path $script:basePath -ChildPath '2.csproj'
            New-MSBuildFile -Path $multipleDotnetProjectPath -Contents '<TargetFrameworks>net6.0;net8.0</TargetFrameworks>'

            $standardProjectPath = Join-Path -Path $script:basePath -ChildPath '3.csproj'
            New-MSBuildFile -Path $standardProjectPath -Contents '<TargetFramework>netstandard2.1</TargetFramework>'

            $frameworkProjectPath = Join-Path -Path $script:basePath -ChildPath '4.csproj'
            New-MSBuildFile -Path $frameworkProjectPath -Contents '<TargetFrameworkVersion>v4.8.1</TargetFrameworkVersion>'

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance
        }

        It 'Pads framework versions to match longest entry' {
            Get-DotnetTargetFramework -Path $script:basePath
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 5

            $writeHostInvocationLines[0] | Should -Be "net8.0:         $singleDotnetProjectPath"
            $writeHostInvocationLines[1] | Should -Be "net6.0;net8.0:  $multipleDotnetProjectPath"
            $writeHostInvocationLines[2] | Should -Be "netstandard2.1: $standardProjectPath"
            $writeHostInvocationLines[3] | Should -Be "v4.8.1:         $frameworkProjectPath"
            $writeHostInvocationLines[4] | Should -Be ''
        }
    }

    Context 'Json Format' {
        BeforeEach {
            $coreProjectPath = Join-Path -Path $script:basePath -ChildPath '1.csproj'
            New-MSBuildFile -Path $coreProjectPath -Contents '<TargetFramework>net8.0</TargetFramework>'

            $frameworkProjectPath = Join-Path -Path $script:basePath -ChildPath '2.csproj'
            New-MSBuildFile -Path $frameworkProjectPath -Contents '<TargetFrameworkVersion>v4.5.2</TargetFrameworkVersion>'

            $propertiesPath = Join-Path -Path $script:basePath -ChildPath '3.props'
            New-MSBuildFile -Path $propertiesPath -Contents '<TargetFrameworks>net8.0-android;net7.0</TargetFrameworks>'

            $script:output = Get-DotnetTargetFramework -Path $script:basePath -Format 'Json' |
                ConvertFrom-Json
        }

        It 'Outputs array of all projects' {
            $output.Count | Should -Be 3
        }

        It 'Outputs core project with a single target version' {
            $project = $output[0]
            $project.path | Should -Be $coreProjectPath
            $project.targetFrameworks.Count | Should -Be 1
            $project.targetFrameworks[0].value | Should -Be 'net8.0'
            $project.targetFrameworks[0].supported | Should -Be $true
        }

        It 'Outputs framework project with a single target version' {
            $project = $output[1]
            $project.path | Should -Be $frameworkProjectPath
            $project.targetFrameworks.Count | Should -Be 1
            $project.targetFrameworks[0].value | Should -Be 'v4.5.2'
            $project.targetFrameworks[0].supported | Should -Be $false
        }

        It 'Outputs core project with multiple target versions' {
            $project = $output[2]
            $project.path | Should -Be $propertiesPath
            $project.targetFrameworks.Count | Should -Be 2
            $project.targetFrameworks[0].value | Should -Be 'net8.0-android'
            $project.targetFrameworks[0].supported | Should -Be $true
            $project.targetFrameworks[1].value | Should -Be 'net7.0'
            $project.targetFrameworks[1].supported | Should -Be $false
        }
    }

    AfterEach {
        Remove-Item -Path $script:basePath -Recurse -Force
    }
}

AfterAll {
    $env:RIPGREP_CONFIG_PATH = $script:ripgrepConfigPath
}
