# Installation

## Setup PowerShell Repository

1. Check for a local PowerShell repository. If one exists, note the name and skip to the next section.

   ```powershell
   Get-PSRepository
   ```

1. Create a local PowerShell repository.

   ```powershell
   Register-PSRepository -Name 'Local' -SourceLocation '<PATH>' -ScriptSourceLocation '<PATH>' -InstallationPolicy 'Trusted'
   ```

## Publish Module

1. Execute the build script.

   ```powershell
   ./build.ps1
   ```

1. Publish the module to the local repository.

   ```powershell
   $modulePath = Join-Path -Path '<GIT_REPOSITORY_ROOT_PATH>' -ChildPath 'artifacts' -AdditionalChildPath 'Lance'
   Publish-Module -Path $modulePath -Repository 'Local'
   ```

1. Install the module from the repository.

   ```powershell
   Install-Module -Name 'Lance' -Repository 'Local'
   ```

1. Import the module as part of your PowerShell profile.

   ```powershell
   Import-Module -Name 'Lance'
   ```
