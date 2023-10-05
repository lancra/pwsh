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

## Execute Install

1. Execute the install script.

   ```powershell
   ./install.ps1
   ```

## Import from Profile

1. Import the module as part of your PowerShell profile.

   ```powershell
   Import-Module -Name 'Lance'
   ```
