# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Allow text-based sub-directory Git commands.
- Support JSON output for .NET target framework version check.

### Changed

- Skip Git command execution in non-Git directories.
- Remove dot path segment from relative output in .NET target framework check.
- Update .NET support policy for target framework check.

## [0.1.0] - 2024-06-20

### Added

- Add Invoke-SubDirectoryGitCommand cmdlet (#1).
- Add Write-GitRepositoryDetail cmdlet (#1).
- Add Remove-BuildArtifact cmdlet (#2).
- Add Resolve-Error cmdlet (#3).
- Add Stop-Wsl cmdlet (#3).
- Add Test-PathExecutable cmdlet (#4).
- Add Get-DotnetTargetFramework cmdlet (#4).
- Add Get-DotnetOutdatedPackage cmdlet (#5).

[Unreleased]: https://github.com/lancra/pwsh/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/lancra/pwsh/releases/tag/v0.1.0
