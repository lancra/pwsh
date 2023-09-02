BeforeAll {
    $moduleName = $env:BHProjectName
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $artifactsDirectory = Join-Path -Path $ENV:BHProjectPath -ChildPath 'artifacts'
    $artifactsModuleDirectory = Join-Path -Path $artifactsDirectory -ChildPath $env:BHProjectName
    $artifactsModuleVersionDirectory = Join-Path -Path $artifactsModuleDirectory -ChildPath $manifest.ModuleVersion
    $artifactsManifestPath = Join-Path -Path $artifactsModuleVersionDirectory -Child "$($moduleName).psd1"
    $script:manifestData = Test-ModuleManifest -Path $artifactsManifestPath -Verbose:$false -ErrorAction Stop -WarningAction SilentlyContinue

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

Describe 'Git Tags' -Skip {
    BeforeAll {
        $script:gitTagVersion = $null
        if (Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {
            # Aliased on my machine as "tags-latest".
            $tagMessage = git log --tags --decorate --oneline --simplify-by-decoration -1 --format='%(describe:tags)'
            if ($tagMessage -and $tagMessage[0] -eq 'v') {
                $script:gitTagVersion = $tagMessage
            }
        }
    }

    It 'Has a valid version tag' {
        $script:gitTagVersion | Should -Not -BeNullOrEmpty
        $script:gitTagVersion -as [Version] | Should -Not -BeNullOrEmpty
    }

    It 'Tag and manifest versions match' {
        $script:manifestData.Version -as [Version] | Should -Be ( $script:gitTagVersion -as [Version])
    }
}
