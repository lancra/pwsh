BeforeAll {
    $moduleName = $env:BHProjectName
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $artifactsDirectory = Join-Path -Path $ENV:BHProjectPath -ChildPath 'artifacts'
    $artifactsModuleDirectory = Join-Path -Path $artifactsDirectory -ChildPath $env:BHProjectName
    $artifactsModuleVersionDirectory = Join-Path -Path $artifactsModuleDirectory -ChildPath $manifest.ModuleVersion
    $artifactsManifestPath = Join-Path -Path $artifactsModuleVersionDirectory -Child "$($moduleName).psd1"

    $manifestDataParams = @{
        ErrorAction = 'Stop'
        Path = $artifactsManifestPath
        Verbose = $false
        WarningAction = 'SilentlyContinue'
    }
    $script:manifestData = Test-ModuleManifest @manifestDataParams

    $changelogPath = Join-Path -Path $env:BHProjectPath -Child 'CHANGELOG.md'
    $script:changelogVersion = Get-Content $changelogPath |
        ForEach-Object {
            if ($_ -match '^##\s\[(?<Version>(\d+\.){1,3}\d+)\]') {
                $script:changelogVersion = $matches.Version
                break
            }
        }

    $script:manifest = $null
}

Describe 'Module Manifest' {

    Context 'Validation' {

        It 'Has a valid manifest' {
            $script:manifestData | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid name in the manifest' {
            $script:manifestData.Name | Should -Be $moduleName
        }

        It 'Has a valid root module' {
            $script:manifestData.RootModule | Should -Be "$($moduleName).psm1"
        }

        It 'Has a valid version in the manifest' {
            $script:manifestData.Version -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid description' {
            $script:manifestData.Description | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid author' {
            $script:manifestData.Author | Should -Not -BeNullOrEmpty
        }

        It 'Has a valid guid' {
            {[guid]::Parse($script:manifestData.Guid)} | Should -Not -Throw
        }

        # TODO: Enable these before first release.
        It 'Has a valid version in the changelog' -Skip {
            $script:changelogVersion | Should -Not -BeNullOrEmpty
            $script:changelogVersion -as [Version] | Should -Not -BeNullOrEmpty
        }

        It 'Changelog and manifest versions match' -Skip {
            $script:changelogVersion -as [Version] | Should -Be ( $script:manifestData.Version -as [Version] )
        }
    }
}
