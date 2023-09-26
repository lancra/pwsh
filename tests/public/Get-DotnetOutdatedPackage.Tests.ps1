BeforeAll {
    function Get-FakeOutput {
        param(
            [Parameter(Mandatory)]
            [string]$OutputFileName
        )
        process {
            $outputPath = Join-Path -Path "$PSScriptRoot/../testing/outdated-package-output" -ChildPath "$OutputFileName.json"
            return Get-Content -Path $outputPath
        }
    }
}

Describe 'References' {
    Context 'Single Version, Single Project' {
        BeforeEach {
            Mock dotnet { Get-FakeOutput -OutputFileName 'single-version-single-project' } -ModuleName Lance -ParameterFilter {
                "$args" -eq 'list . package --outdated --format json'
            }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes output to a single line' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 4
            $writeHostInvocationLines[0] | Should -Be 'Foo: 0.1.1 -> 1.0.0 (A)'
            $writeHostInvocationLines[1] | Should -Be ''
            $writeHostInvocationLines[2] | Should -Be 'A: /usr/git/foo.csproj'
            $writeHostInvocationLines[3] | Should -Be ''
        }
    }

    Context 'Single Version, Multi Project' {
        BeforeEach {
            Mock dotnet { Get-FakeOutput -OutputFileName 'single-version-multi-project' } -ModuleName Lance -ParameterFilter {
                "$args" -eq 'list . package --outdated --format json'
            }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes output to a single line' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 5
            $writeHostInvocationLines[0] | Should -Be 'Bar: 0.1.0 -> 1.0.0 (AB)'
            $writeHostInvocationLines[1] | Should -Be ''
            $writeHostInvocationLines[2] | Should -Be 'A: /usr/git/bar.csproj'
            $writeHostInvocationLines[3] | Should -Be 'B: /usr/git/foo.csproj'
            $writeHostInvocationLines[4] | Should -Be ''
        }
    }

    Context 'Multi Version, Single Project' {
        BeforeEach {
            Mock dotnet { Get-FakeOutput -OutputFileName 'multi-version-single-project' } -ModuleName Lance -ParameterFilter {
                "$args" -eq 'list . package --outdated --format json'
            }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes output to separate lines' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 6
            $writeHostInvocationLines[0] | Should -Be 'Baz:'
            $writeHostInvocationLines[1] | Should -Be '  0.3.4 -> 1.0.0 (A)'
            $writeHostInvocationLines[2] | Should -Be '  0.3.5 -> 1.0.0 (A)'
            $writeHostInvocationLines[3] | Should -Be ''
            $writeHostInvocationLines[4] | Should -Be 'A: /usr/git/foo.csproj'
            $writeHostInvocationLines[5] | Should -Be ''
        }
    }

    Context 'Multi Version, Multi Project' {
        BeforeEach {
            Mock dotnet { Get-FakeOutput -OutputFileName 'multi-version-multi-project' } -ModuleName Lance -ParameterFilter {
                "$args" -eq 'list . package --outdated --format json'
            }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes output to multiple lines' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 9
            $writeHostInvocationLines[0] | Should -Be 'Qux:'
            $writeHostInvocationLines[1] | Should -Be '  0.1.0 -> 1.0.0 (B)'
            $writeHostInvocationLines[2] | Should -Be '  0.2.0 -> 1.0.0 (B)'
            $writeHostInvocationLines[3] | Should -Be '  0.3.0 -> 1.0.0 (A)'
            $writeHostInvocationLines[4] | Should -Be '  0.4.0 -> 1.0.0 (A)'
            $writeHostInvocationLines[5] | Should -Be ''
            $writeHostInvocationLines[6] | Should -Be 'A: /usr/git/bar.csproj'
            $writeHostInvocationLines[7] | Should -Be 'B: /usr/git/foo.csproj'
            $writeHostInvocationLines[8] | Should -Be ''
        }
    }

    Context 'No Version, Multi Project' {
        BeforeEach {
            Mock dotnet { Get-FakeOutput -OutputFileName 'no-version-multi-project' } -ModuleName Lance -ParameterFilter {
                "$args" -eq 'list . package --outdated --format json'
            }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes no output' {
            $writeHostInvocations.Count | Should -Be 0
        }
    }
}

Describe 'Sorting' {
    Context 'Versions' {
        BeforeEach {
            Mock dotnet { Get-FakeOutput -OutputFileName 'version-sorting' } -ModuleName Lance -ParameterFilter {
                "$args" -eq 'list . package --outdated --format json'
            }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Sorts versions as numbers' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'
            $packageVersions = $writeHostInvocationLines -like '*->*' |
                ForEach-Object { ($_ -split '->')[0].Trim() }

            $packageVersions.Count | Should -Be 16
            $packageVersions[0] | Should -Be '0.1.0-preview0'
            $packageVersions[1] | Should -Be '0.1.0-preview1'
            $packageVersions[2] | Should -Be '0.1.0-preview10'
            $packageVersions[3] | Should -Be '0.1.0'
            $packageVersions[4] | Should -Be '0.1.1'
            $packageVersions[5] | Should -Be '0.1.10'
            $packageVersions[6] | Should -Be '0.10.1'
            $packageVersions[7] | Should -Be '0.10.10'
            $packageVersions[8] | Should -Be '1.0.0-preview0'
            $packageVersions[9] | Should -Be '1.0.0-preview1'
            $packageVersions[10] | Should -Be '1.0.1'
            $packageVersions[11] | Should -Be '1.0.10'
            $packageVersions[12] | Should -Be '1.1.0'
            $packageVersions[13] | Should -Be '1.1.1'
            $packageVersions[14] | Should -Be '1.1.10'
            $packageVersions[15] | Should -Be '1.1.11'
        }
    }

    Context 'Projects' {
        BeforeEach {
            Mock dotnet { Get-FakeOutput -OutputFileName 'project-sorting' } -ModuleName Lance -ParameterFilter {
                "$args" -eq 'list . package --outdated --format json'
            }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Sorts project letters' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'
            $writeHostInvocationLines[0] | Should -Be 'Foo: 0.1.1 -> 1.0.0 (ABCDEFGHI)'
        }

        It 'Sorts projects naturally' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'
            $writeHostInvocationLines[2] | Should -Be 'A: /usr/git/a/a1/project.csproj'
            $writeHostInvocationLines[3] | Should -Be 'B: /usr/git/a/a10/project.csproj'
            $writeHostInvocationLines[4] | Should -Be 'C: /usr/git/a1/a2/project.csproj'
            $writeHostInvocationLines[5] | Should -Be 'D: /usr/git/a2/a/project.csproj'
            $writeHostInvocationLines[6] | Should -Be 'E: /usr/git/a10/project.csproj'
            $writeHostInvocationLines[7] | Should -Be 'F: /usr/git/a11/project.csproj'
            $writeHostInvocationLines[8] | Should -Be 'G: /usr/git/b/project.csproj'
            $writeHostInvocationLines[9] | Should -Be 'H: /usr/git/b12/project.csproj'
            $writeHostInvocationLines[10] | Should -Be 'I: /usr/git/b100/project.csproj'
        }
    }
}

Describe 'Coloring' {
    Context 'Versions' {
        BeforeEach {
            Mock dotnet { Get-FakeOutput -OutputFileName 'version-sorting' } -ModuleName Lance -ParameterFilter {
                "$args" -eq 'list . package --outdated --format json'
            }

            Mock Write-Host -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes outdated versions using red font' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq '0.1.0' -and $ForegroundColor -eq 'Red' }
        }

        It 'Writes latest versions using green font' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq '2.0.0' -and $ForegroundColor -eq 'Green' }
        }
    }

    Context 'Projects' {
        BeforeEach {
            Mock dotnet { Get-FakeOutput -OutputFileName 'project-sorting' } -ModuleName Lance -ParameterFilter {
                "$args" -eq 'list . package --outdated --format json'
            }

            Mock Write-Host -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes project letters in varying colors' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq 'A' -and $ForegroundColor -eq 'DarkRed' }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq 'B' -and $ForegroundColor -eq 'DarkGreen' }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq 'C' -and $ForegroundColor -eq 'DarkYellow' }
        }
    }
}
