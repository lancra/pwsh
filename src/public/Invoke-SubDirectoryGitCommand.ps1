<#
.SYNOPSIS
Invokes a Git command against all sub-directories within a provided path.

.DESCRIPTION
For all of the child directories from the provided path, this executes the
provided Git command using the "-C" flag, which prevents the need to change
directories.

.PARAMETER Command
The Git command to execute, excluding the Git executable.

.PARAMETER CommandText
The text of the Git command to execute, excluding the Git executable.

.PARAMETER Path
The parent directory to find all child Git repositories from.

.PARAMETER NoHead
Disables writing the current head to the host via the Write-GitRepositoryDetail
function.

.PARAMETER NoAheadBehind
Disables writing the remote ahead/behind to the host via the
Write-GitRepositoryDetail function.

.EXAMPLE
Invoke-SubDirectoryGitCommand -Command {fetch} -Path C:\Projects\git

Executes a fetch for a directory.

.EXAMPLE
Invoke-SubDirectoryGitCommand -Command {config --get commit.gpgSign} `
    -Path C:\Projects\git -NoHead -NoAheadBehind

Gets the value that determines whether commit are gpg-signed for a directory,
hiding the head and ahead/behind values for each repository.
#>
function Invoke-SubDirectoryGitCommand {
    [CmdletBinding(DefaultParameterSetName = 'String')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter',
        'Command',
        Justification = 'False positive since rule does not scan child scopes')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter',
        'NoHead',
        Justification = 'False positive since rule does not scan child scopes')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter',
        'NoAheadBehind',
        Justification = 'False positive since rule does not scan child scopes')]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'String', Position = 0)]
        [string]$CommandText,

        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Script', Position = 0)]
        [scriptblock]$Command,

        [Parameter(ParameterSetName = 'Script', Position = 1)]
        [Parameter(ParameterSetName = 'String', Position = 1)]
        [string]$Path = '.',

        [Parameter(ParameterSetName = 'Script')]
        [Parameter(ParameterSetName = 'String')]
        [switch]$NoHead,

        [Parameter(ParameterSetName = 'Script')]
        [Parameter(ParameterSetName = 'String')]
        [switch]$NoAheadBehind
    )
    process {
        if ($Command) {
            $CommandText = $Command.ToString()
        }

        Get-ChildItem -Path $Path -Directory |
            ForEach-Object {
                $gitDirectory = Join-Path -Path $_ -ChildPath '.git'
                if (-not (Test-Path -Path $gitDirectory)) {
                    return
                }

                Write-GitRepositoryDetail -Path $_.FullName -NoHead:$NoHead -NoAheadBehind:$NoAheadBehind

                $trimmedCommandText = $CommandText.Trim()
                if ($trimmedCommandText -like 'noop*') {
                    # Do not show the current branch via the provided command since it is displayed along with the directory name.
                    return
                }

                $executedCommand = "git -C '$($_.FullName)' $trimmedCommandText"
                Invoke-Command -ScriptBlock ([scriptblock]::Create($executedCommand))
            }
    }
}

New-Alias -Name gits -Value Invoke-SubDirectoryGitCommand
Export-ModuleMember -Alias gits
