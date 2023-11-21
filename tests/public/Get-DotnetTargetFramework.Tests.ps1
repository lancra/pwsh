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
            Mock Write-Host { $writeHostInvocations.Add($Object) } -ModuleName Lance
        }

        It 'Converts current directory relative path to absolute' {
            Set-Location $script:basePath
            Get-DotnetTargetFramework -Path '.'

            ($writeHostInvocations -join '') | Should -Be "foo: $projectPath"
        }

        It 'Converts current directory prefixed relative path to absolute' {
            Set-Location $script:basePath
            Get-DotnetTargetFramework -Path "./$innerDirectoryName"

            ($writeHostInvocations -join '') | Should -Be "foo: $projectPath"
        }

        It 'Converts parent directory relative path to absolute' {
            Set-Location $innerDirectoryPath
            Get-DotnetTargetFramework -Path '..'

            ($writeHostInvocations -join '') | Should -Be "foo: $projectPath"
        }

        It 'Converts parent directory prefixed relative path to absolute' {
            Set-Location $innerDirectoryPath
            Get-DotnetTargetFramework -Path "../$innerDirectoryName"

            ($writeHostInvocations -join '') | Should -Be "foo: $projectPath"
        }

        It 'Does not convert current directory relative path to absolute when relative is requested' {
            Set-Location $script:basePath
            Get-DotnetTargetFramework -Path '.' -ShowRelative

            $expectedPath = Join-Path -Path '.' -ChildPath $innerDirectoryName -AdditionalChildPath $projectName
            ($writeHostInvocations -join '') | Should -Be "foo: $expectedPath"
        }

        It 'Does not convert current directory prefixed relative path to absolute when relative is requested' {
            Set-Location $script:basePath
            $path = Join-Path -Path '.' -ChildPath $innerDirectoryName
            Get-DotnetTargetFramework -Path $path -ShowRelative

            $expectedPath = Join-Path -Path '.' -ChildPath $innerDirectoryName -AdditionalChildPath $projectName
            ($writeHostInvocations -join '') | Should -Be "foo: $expectedPath"
        }

        It 'Does not convert parent directory relative path to absolute when relative is requested' {
            Set-Location $innerDirectoryPath
            Get-DotnetTargetFramework -Path '..' -ShowRelative

            $expectedPath = Join-Path -Path '..' -ChildPath $innerDirectoryName -AdditionalChildPath $projectName
            ($writeHostInvocations -join '') | Should -Be "foo: $expectedPath"
        }

        It 'Does not convert parent directory prefixed relative path to absolute when relative is requested' {
            Set-Location $innerDirectoryPath
            $path = Join-Path -Path '..' -ChildPath $innerDirectoryName
            Get-DotnetTargetFramework -Path $path -ShowRelative

            $expectedPath = Join-Path -Path '..' -ChildPath $innerDirectoryName -AdditionalChildPath $projectName
            ($writeHostInvocations -join '') | Should -Be "foo: $expectedPath"
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
            Mock Write-Host { $writeHostInvocations.Add($Object) } -ModuleName Lance

            Get-DotnetTargetFramework -Path $script:basePath
        }

        It 'Finds project file' {
            ($writeHostInvocations[0..1] -join '') | Should -Be "foo: $projectPath"
        }

        It 'Finds properties file' {
            ($writeHostInvocations[2..($writeHostInvocations.Count - 1)] -join '') | Should -Be "bar;baz: $propertiesPath"
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

            $outdatedPropertiesPath = Join-Path -Path $script:basePath -ChildPath 'Outdated.props'
            New-MSBuildFile -Path $outdatedPropertiesPath -Contents '<TargetFrameworks>netcoreapp3.1;net5.0-windows</TargetFrameworks>'

            $currentProjectPath = Join-Path -Path $script:basePath -ChildPath 'Current.csproj'
            New-MSBuildFile -Path $currentProjectPath -Contents '<TargetFramework>net6.0</TargetFramework>'

            $currentPropertiesPath = Join-Path -Path $script:basePath -ChildPath 'Current.props'
            New-MSBuildFile -Path $currentPropertiesPath -Contents '<TargetFrameworks>net6.0-android;net7.0</TargetFrameworks>'

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

            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Red' -and $Object -eq 'net5.0' }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Red' -and
                $Object -eq 'net5.0-windows'
            }
        }

        It 'Writes current versions using green font' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Green' -and $Object -eq 'net6.0' }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Green' -and
                $Object -eq 'net6.0-android'
            }

            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Green' -and $Object -eq 'net7.0' }
        }
    }

    Context 'Exclusions' {
        BeforeAll {
            function Split-HostLines {
                [CmdletBinding()]
                param (
                    [Parameter(Mandatory)]
                    [string[]]$Invocations
                )
                process {
                    $invocationString = $Invocations -join ''
                    $invocationLinesString = $invocationString -replace 'version:',("$([System.Environment]::NewLine)version:")
                    $invocationLines = $invocationLinesString -split [System.Environment]::NewLine
                    $invocationLines | Select-Object -Skip 1
                }
            }
        }

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
            Mock Write-Host { $writeHostInvocations.Add($Object) } -ModuleName Lance
        }

        It 'Includes every match by default' {
            Get-DotnetTargetFramework -Path $script:basePath
            $writeHostLineInvocations = Split-HostLines -Invocations $writeHostInvocations

            $writeHostLineInvocations | Should -Contain "version: $fooProjectPath"
            $writeHostLineInvocations | Should -Contain "version: $barProjectPath"
            $writeHostLineInvocations | Should -Contain "version: $bazProjectPath"
            $writeHostLineInvocations | Should -Contain "version: $foobarProjectPath"
        }

        Context 'Partial Match' {
            BeforeEach {
                Get-DotnetTargetFramework -Path $script:basePath -ExcludeDirectory $fooDirectoryName
                $script:writeHostLineInvocations = Split-HostLines -Invocations $writeHostInvocations
            }

            It 'Excludes directory based on exact name' {
                $writeHostLineInvocations | Should -Not -Contain "version: $fooProjectPath"
            }

            It 'Does not exclude partially matched directory' {
                $writeHostLineInvocations | Should -Contain "version: $foobarProjectPath"
            }

            It 'Includes other directories' {
                $writeHostLineInvocations | Should -Contain "version: $barProjectPath"
                $writeHostLineInvocations | Should -Contain "version: $bazProjectPath"
            }
        }

        It 'Excludes multiple specified directories' {
            Get-DotnetTargetFramework -Path $script:basePath -ExcludeDirectory @($fooDirectoryName, $foobarDirectoryName)
            $writeHostLineInvocations = Split-HostLines -Invocations $writeHostInvocations

            $writeHostLineInvocations | Should -Not -Contain "version: $fooProjectPath"
            $writeHostLineInvocations | Should -Contain "version: $barProjectPath"
            $writeHostLineInvocations | Should -Contain "version: $bazProjectPath"
            $writeHostLineInvocations | Should -Not -Contain "version: $foobarProjectPath"
        }

        It 'Excludes ancestors of specified directories' {
            Get-DotnetTargetFramework -Path $script:basePath -ExcludeDirectory $barDirectoryName
            $writeHostLineInvocations = Split-HostLines -Invocations $writeHostInvocations

            $writeHostLineInvocations | Should -Contain "version: $fooProjectPath"
            $writeHostLineInvocations | Should -Not -Contain "version: $barProjectPath"
            $writeHostLineInvocations | Should -Not -Contain "version: $bazProjectPath"
            $writeHostLineInvocations | Should -Contain "version: $foobarProjectPath"
        }
    }

    AfterEach {
        Remove-Item -Path $script:basePath -Recurse -Force
    }
}

AfterAll {
    $env:RIPGREP_CONFIG_PATH = $script:ripgrepConfigPath
}
