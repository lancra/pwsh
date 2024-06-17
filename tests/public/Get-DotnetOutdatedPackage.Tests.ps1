BeforeAll {
    . ../../src/private/classes/DotnetPackageList.ps1

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

    $script:emptyOutput = Get-FakeOutput -OutputFileName 'empty'
    $script:path = Resolve-Path .

    Mock Invoke-IndeterminateProgressBegin -ModuleName Lance
    Mock Invoke-IndeterminateProgressEnd -ModuleName Lance
    Mock ConvertTo-Hyperlink { $Text } -ModuleName Lance
}

Describe 'References' {
    Context 'Single Version, Single Project' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'single-version-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

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
            $outdatedOutput = Get-FakeOutput -OutputFileName 'single-version-multi-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

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
            $outdatedOutput = Get-FakeOutput -OutputFileName 'multi-version-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

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
            $outdatedOutput = Get-FakeOutput -OutputFileName 'multi-version-multi-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

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
            $outdatedOutput = Get-FakeOutput -OutputFileName 'no-version-multi-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes no output' {
            $writeHostInvocations.Count | Should -Be 0
        }
    }

    Context 'Top-Level and Transitive' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'top-level-and-transitive'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage -IncludeTransitive

            $script:writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'
        }

        It 'Identifies top-level references as direct' {
            $writeHostInvocationLines[4] | Should -Be 'Foo: 0.1.0 -> 1.0.0 (B) [Direct]'
        }

        It 'Identifies transitive references' {
            $writeHostInvocationLines[5] | Should -Be 'Qux: 0.1.0 -> 1.0.0 (B) [Transitive]'
        }

        It 'Identifies references that are both top-level and transitive' {
            $writeHostInvocationLines[0] | Should -Be 'Bar: 0.1.0 -> 1.0.0 (AB) [Direct] [Transitive]'
        }

        It 'Identifies top-level and transitive references on the same package' {
            $writeHostInvocationLines[1] | Should -Be 'Baz:'
            $writeHostInvocationLines[2] | Should -Be '  0.1.0 -> 1.0.0 (B) [Direct]'
            $writeHostInvocationLines[3] | Should -Be '  0.2.0 -> 1.0.0 (B) [Transitive]'
        }
    }

    Context 'Unknown Latest Version' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'unknown-latest-version'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes question mark for latest version' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 4
            $writeHostInvocationLines[0] | Should -Be 'Foo: 0.1.1 -> ? (A)'
            $writeHostInvocationLines[1] | Should -Be ''
            $writeHostInvocationLines[2] | Should -Be 'A: /usr/git/foo.csproj'
            $writeHostInvocationLines[3] | Should -Be ''
        }
    }
}

Describe 'Sorting' {
    Context 'Versions' {
        BeforeAll {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'version-sorting'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

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
        BeforeAll {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'project-sorting'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

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

    Context 'Vulnerabilities' {
        BeforeAll {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'single-version-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            $vulnerableOutput = Get-FakeOutput -OutputFileName 'vulnerability-sorting'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:vulnerableOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Sorts vulnerabilities from highest to lowest severity' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'
            $packageLine = $writeHostInvocationLines[0]
            $vulnerabilityLine = $packageLine -replace 'Foo: 0.1.1 -> 1.0.0 \(A\) ',''
            $vulnerabilities = $vulnerabilityLine -split ' '

            $vulnerabilities.Count | Should -Be 5
            $vulnerabilities[0] | Should -Be '[MNOP-1234-5678-9012]'
            $vulnerabilities[1] | Should -Be '[IJKL-1234-5678-9012]'
            $vulnerabilities[2] | Should -Be '[EFGH-1234-5678-9012]'
            $vulnerabilities[3] | Should -Be '[ABCD-1234-5678-9012]'
            $vulnerabilities[4] | Should -Be '[QRST-1234-5678-9012]'
        }
    }
}

Describe 'Deprecations' {
    Context 'Single Deprecation' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'single-version-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            $deprecatedOutput = Get-FakeOutput -OutputFileName 'single-deprecation'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:deprecatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Displays deprecation tag after reference project letters' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 4
            $writeHostInvocationLines[0] | Should -Be 'Foo: 0.1.1 -> 1.0.0 (A) [Deprecated]'
            $writeHostInvocationLines[1] | Should -Be ''
            $writeHostInvocationLines[2] | Should -Be 'A: /usr/git/foo.csproj'
            $writeHostInvocationLines[3] | Should -Be ''
        }
    }

    Context 'Multi Deprecations' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'multi-version-multi-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            $deprecatedOutput = Get-FakeOutput -OutputFileName 'multi-deprecations'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:deprecatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Adds deprecation tag only after specified reference versions' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 9
            $writeHostInvocationLines[0] | Should -Be 'Qux:'
            $writeHostInvocationLines[1] | Should -Be '  0.1.0 -> 1.0.0 (B) [Deprecated]'
            $writeHostInvocationLines[2] | Should -Be '  0.2.0 -> 1.0.0 (B)'
            $writeHostInvocationLines[3] | Should -Be '  0.3.0 -> 1.0.0 (A) [Deprecated]'
            $writeHostInvocationLines[4] | Should -Be '  0.4.0 -> 1.0.0 (A)'
            $writeHostInvocationLines[5] | Should -Be ''
            $writeHostInvocationLines[6] | Should -Be 'A: /usr/git/bar.csproj'
            $writeHostInvocationLines[7] | Should -Be 'B: /usr/git/foo.csproj'
            $writeHostInvocationLines[8] | Should -Be ''
        }
    }

    Context 'Transitive Deprecation' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'transitive-outdated'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            $deprecatedOutput = Get-FakeOutput -OutputFileName 'transitive-deprecated'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:deprecatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage -IncludeTransitive
        }

        It 'Displays deprecation tag after transitive tag' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'
            $writeHostInvocationLines | Should -Contain 'Bar: 0.1.0 -> 1.0.0 (A) [Transitive] [Deprecated]'
        }
    }
}

Describe 'Vulnerabilities' {
    Context 'Single Vulnerability, Single Package' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'single-version-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            $vulnerableOutput = Get-FakeOutput -OutputFileName 'single-vulnerability-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:vulnerableOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Displays vulnerability tag after reference project letters' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 4
            $writeHostInvocationLines[0] | Should -Be "Foo: 0.1.1 -> 1.0.0 (A) [ABCD-1234-5678-9012]"
            $writeHostInvocationLines[1] | Should -Be ''
            $writeHostInvocationLines[2] | Should -Be 'A: /usr/git/foo.csproj'
            $writeHostInvocationLines[3] | Should -Be ''
        }
    }

    Context 'Multi Vulnerability, Single Package' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'single-version-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            $vulnerableOutput = Get-FakeOutput -OutputFileName 'multi-vulnerability-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:vulnerableOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Displays vulnerability tags after reference project letters' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 4
            $writeHostInvocationLines[0] | Should -Be "Foo: 0.1.1 -> 1.0.0 (A) [ABCD-1234-5678-9012] [EFGH-1234-5678-9012]"
            $writeHostInvocationLines[1] | Should -Be ''
            $writeHostInvocationLines[2] | Should -Be 'A: /usr/git/foo.csproj'
            $writeHostInvocationLines[3] | Should -Be ''
        }
    }

    Context 'Single Vulnerability, Multi Package' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'multi-version-multi-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            $vulnerableOutput = Get-FakeOutput -OutputFileName 'multi-vulnerability-multi-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:vulnerableOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Adds vulnerability tag only after specified reference versions' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'

            $writeHostInvocationLines.Count | Should -Be 9
            $writeHostInvocationLines[0] | Should -Be 'Qux:'
            $writeHostInvocationLines[1] | Should -Be '  0.1.0 -> 1.0.0 (B) [ABCD-1234-5678-9012]'
            $writeHostInvocationLines[2] | Should -Be '  0.2.0 -> 1.0.0 (B)'
            $writeHostInvocationLines[3] | Should -Be '  0.3.0 -> 1.0.0 (A) [EFGH-1234-5678-9012]'
            $writeHostInvocationLines[4] | Should -Be '  0.4.0 -> 1.0.0 (A)'
            $writeHostInvocationLines[5] | Should -Be ''
            $writeHostInvocationLines[6] | Should -Be 'A: /usr/git/bar.csproj'
            $writeHostInvocationLines[7] | Should -Be 'B: /usr/git/foo.csproj'
            $writeHostInvocationLines[8] | Should -Be ''
        }
    }

    Context 'Transitive Vulnerability' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'transitive-outdated'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            $vulnerableOutput = Get-FakeOutput -OutputFileName 'transitive-vulnerable'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:vulnerableOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage -IncludeTransitive
        }

        It 'Displays vulnerability tag after transitive tag' {
            $writeHostInvocationLines = ($writeHostInvocations -join '') -split '`n'
            $writeHostInvocationLines | Should -Contain "Baz: 0.1.0 -> 1.0.0 (A) [Transitive] [ABCD-1234-5678-9012]"
        }
    }
}

Describe 'Coloring' {
    Context 'Versions' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'version-sorting'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

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
            $outdatedOutput = Get-FakeOutput -OutputFileName 'project-sorting'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            Mock Write-Host -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes project letters in varying colors' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq 'A' -and $ForegroundColor -eq 'DarkRed' }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq 'B' -and $ForegroundColor -eq 'DarkGreen' }
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter { $Object -eq 'C' -and $ForegroundColor -eq 'DarkYellow' }
        }
    }

    Context 'Deprecations' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'single-version-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            $deprecatedOutput = Get-FakeOutput -OutputFileName 'single-deprecation'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:deprecatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            Mock Write-Host -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes deprecation tag using red font' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $Object -eq ' [Deprecated]' -and $ForegroundColor -eq 'DarkRed' }
        }
    }

    Context 'Vulnerabilities' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'single-version-single-project'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            $vulnerableOutput = Get-FakeOutput -OutputFileName 'vulnerability-sorting'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:vulnerableOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            $writeHostInvocations = [System.Collections.Generic.List[string]]::new()
            Mock Write-Host { $writeHostInvocations.Add($Object ? $Object : '`n') } -ModuleName Lance

            Get-DotnetOutdatedPackage
        }

        It 'Writes vulnerability tag using white font when low severity' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $Object -eq ' [ABCD-1234-5678-9012]' -and $ForegroundColor -eq 'White' }
        }

        It 'Writes vulnerability tag using yellow font when moderate severity' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $Object -eq ' [EFGH-1234-5678-9012]' -and $ForegroundColor -eq 'Yellow' }
        }

        It 'Writes vulnerability tag using red font when high severity' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $Object -eq ' [IJKL-1234-5678-9012]' -and $ForegroundColor -eq 'Red' }
        }

        It 'Writes vulnerability tag using dark red font when critical severity' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $Object -eq ' [MNOP-1234-5678-9012]' -and $ForegroundColor -eq 'DarkRed' }
        }

        It 'Writes vulnerability tag using magenta font when unknown severity' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $Object -eq ' [QRST-1234-5678-9012]' -and $ForegroundColor -eq 'Magenta' }
        }
    }

    Context 'Top-Level / Transitive' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'top-level-and-transitive'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

            Mock Write-Host -ModuleName Lance

            Get-DotnetOutdatedPackage -IncludeTransitive
        }

        It 'Writes direct tag using magenta font' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $Object -eq ' [Direct]' -and $ForegroundColor -eq 'Magenta' }
        }

        It 'Writes transitive tag using blue font' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $Object -eq ' [Transitive]' -and $ForegroundColor -eq 'Blue' }
        }
    }

    Context 'Unknown Latest Version' {
        BeforeEach {
            $outdatedOutput = Get-FakeOutput -OutputFileName 'unknown-latest-version'
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:outdatedOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Outdated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Deprecated }
            Mock Get-NuGetPackageJson { Start-ThreadJob { $using:emptyOutput } } -ModuleName Lance -ParameterFilter {
                $Path -eq $path -and $Kind -eq [DotnetPackageKind]::Vulnerable }

                Mock Write-Host -ModuleName Lance

                Get-DotnetOutdatedPackage
        }

        It 'Writes question mark using default font color' {
            Should -Invoke Write-Host -ModuleName Lance -ParameterFilter {
                $Object -eq '?' -and
                $ForegroundColor -eq [System.Console]::ForegroundColor }
        }
    }
}
