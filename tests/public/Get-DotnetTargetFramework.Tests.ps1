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
}

Describe 'Error Checking' {
    It 'Fails when ripgrep is unavailable' {
        Mock Test-PathExecutable { $false } -ParameterFilter { $Executable -eq 'rg' } -Module Lance
        { Get-DotnetVersion } | Should -Throw
    }
}

Describe 'Output' {
    BeforeEach {
        $script:basePath = New-TemporaryDirectory

        Mock Write-Host -Module Lance
    }

    Context 'Relative Path' {
        BeforeEach {
            $script:originalLocation = Get-Location

            $projectPath = Join-Path $script:basePath -ChildPath 'Project.csproj'
            New-MSBuildFile -Path $projectPath -Contents '<TargetFramework>foo</TargetFramework>'

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object) } -ModuleName Lance

            Set-Location $script:basePath
            Get-DotnetVersion -Path '.'
        }

        It 'Converts relative path to absolute' {
            ($writeHostInvocations -join '') | Should -Be "foo: $projectPath"
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

            Get-DotnetVersion -Path $script:basePath
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

            Get-DotnetVersion -Path $script:basePath
        }

        It 'Writes unknown versions using red font' {
            Should -Invoke -Command Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Red' -and $Object -eq 'foo' }
            Should -Invoke -Command Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Red' -and $Object -eq 'bar' }
            Should -Invoke -Command Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Red' -and $Object -eq 'baz' }
        }

        It 'Writes outdated versions using red font' {
            Should -Invoke -Command Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Red' -and
                $Object -eq 'netcoreapp3.1'
            }

            Should -Invoke -Command Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Red' -and $Object -eq 'net5.0' }
            Should -Invoke -Command Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Red' -and
                $Object -eq 'net5.0-windows'
            }
        }

        It 'Writes current versions using green font' {
            Should -Invoke -Command Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Green' -and $Object -eq 'net6.0' }
            Should -Invoke -Command Write-Host -ModuleName Lance -ParameterFilter {
                $ForegroundColor -eq 'Green' -and
                $Object -eq 'net6.0-android'
            }

            Should -Invoke -Command Write-Host -ModuleName Lance -ParameterFilter { $ForegroundColor -eq 'Green' -and $Object -eq 'net7.0' }
        }
    }

    AfterEach {
        Remove-Item -Path $script:basePath -Recurse -Force
    }
}
