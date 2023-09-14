@{
    RootModule = 'Lance.psm1'
    ModuleVersion = '0.1.0'
    Guid = '4cb79175-aa10-4939-a89c-92ac68caf0d9'
    Author = 'Lance Craig'
    PowerShellVersion = '7.0'
    Description = "Lance's general-use scripts."
    AliasesToExport = @(
        'gits',
        'superclean'
    )
    FunctionsToExport = @(
        'Invoke-SubDirectoryGitCommand',
        'Remove-BuildArtifact',
        'Resolve-Error',
        'Stop-Wsl',
        'Test-PathExecutable',
        'Write-GitRepositoryDetail'
    )
    VariablesToExport = 'Lance'
    PrivateData = @{
        PSData = @{
            Prerelease = 'preview3'
            ReleaseNotes = 'https://raw.githubusercontent.com/lancra/pwsh/main/CHANGELOG.md'
            LicenseUri = 'https://raw.githubusercontent.com/lancra/pwsh/main/LICENSE'
            ProjectUri = 'https://github.com/lancra/pwsh'
        }
    }
}
