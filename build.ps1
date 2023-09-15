#requires -Version 5.1

[CmdletBinding()]
param(
    # Build task(s) to execute
    [ValidateSet('Init', 'Clean', 'Build', 'Analyze', 'Import', 'Pester', 'Hack', 'Test')]
    [string]$Task = 'Test',

    # Bootstrap dependencies
    [switch]$Bootstrap,

    # Executed for continuous integration
    [switch]$CI
)

$sut = Join-Path -Path $PSScriptRoot -ChildPath 'src'
$manifestPath = Join-Path -Path $sut -ChildPath 'Lance.psd1'
$version = (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion
$artifactsDirectory = Join-Path -Path $PSScriptRoot -ChildPath 'artifacts'
$artifactsModuleDirectory = Join-Path -Path $artifactsDirectory -ChildPath 'Lance'
$artifactsModuleVersionDirectory = Join-Path -Path $artifactsModuleDirectory -ChildPath $version
$artifactsManifest = Join-Path -Path $artifactsModuleVersionDirectory -ChildPath 'Lance.psd1'

$PSDefaultParameterValues = @{
    'Get-Module:Verbose' = $false
    'Import-Module:Verbose' = $false
    'Remove-Module:Verbose' = $false
}

if ($Bootstrap) {
    Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    if (-not (Get-Module -Name PSDepend -ListAvailable)) {
        Install-Module -Name PSDepend -Repository PSGallery -Scope CurrentUser -Force
    }

    Import-Module -Name PSDepend -Verbose:$false
    Invoke-PSDepend -Path './requirements.psd1' -Install -Import -Force -WarningAction SilentlyContinue
}

# Taken with love from Jaykul @ https://gist.github.com/Jaykul/e0c08be051bed56d62474ae12b9b1b8a
class DependsOn : System.Attribute {
    [string[]]$Name

    DependsOn([string[]]$name) {
        $this.Name = $name
    }
}

<#
.SYNOPSIS
Runs a command, taking care to run it's dependencies first
.DESCRIPTION
Invoke-Step supports the [DependsOn("...")] attribute to allow you to write tasks or build steps that take dependencies on other tasks
completing first.

When you invoke a step, dependencies are run first, recursively. The algorithm for this is depth-first and *very* naive. Don't build
cycles!
.EXAMPLE
function init {
    param()
    Write-Information "INITIALIZING build variables"
}

function update {
    [DependsOn("init")]param()
    Write-Information "UPDATING dependencies"
}

function build {
    [DependsOn(("update","init"))]param()
    Write-Information "BUILDING: $ModuleName from $Path"
}

Invoke-Step build -InformationAction continue

Defines three steps with dependencies, and invokes the "build" step.
Results in this output:

Invoking Step: init
Invoking Step: update
Invoking Step: build
#>
function Invoke-Step {
    [CmdletBinding()]
    param(
        [string]$Step,
        [string]$Script
    )

    begin {
        # Source Build Scripts, if any
        if ($Script) {
            . $Script
        }

        # Don't reset on nested calls
        if (((Get-PSCallStack).Command -eq 'Invoke-Step').Count -eq 1) {
            $script:InvokedSteps = @()
        }
    }

    end {
        if ($stepCommand = Get-Command -Name $Step -CommandType Function) {

            $dependencies = $stepCommand.ScriptBlock.Attributes.Where{$_.TypeId.Name -eq 'DependsOn'}.Name
            foreach ($dependency in $dependencies) {
                if ($dependency -notin $script:InvokedSteps) {
                    Invoke-Step -Step $dependency
                }
            }

            if ($Step -notin $script:InvokedSteps) {
                Write-Host "Invoking Step: $Step" -ForegroundColor Cyan
                try {
                    & $stepCommand
                    $script:InvokedSteps += $Step
                } catch {
                    throw $_
                }
            }
        } else {
            throw "Could not find step [$Step]"
        }
    }
}

function Init {
    [CmdletBinding()]
    param()
    process {
        Remove-Module -Name Lance -Force -ErrorAction SilentlyContinue
        Set-BuildEnvironment -Force
    }
}

function Clean {
    [DependsOn('Init')]
    [CmdletBinding()]
    param()
    process {
        if (Test-Path -Path $artifactsModuleVersionDirectory) {
            Remove-Item -Path $artifactsModuleVersionDirectory -Recurse -Force | Out-Null
        }
    }
}

function Build {
    [DependsOn('Clean')]
    [CmdletBinding()]
    param()
    process {
        if (-not (Test-Path -Path $artifactsDirectory)) {
            New-Item -Path $artifactsDirectory -ItemType Directory | Out-Null
        }

        New-Item -Path $artifactsModuleVersionDirectory -ItemType Directory | Out-Null
        Copy-Item -Path (Join-Path -Path $sut -ChildPath *) -Destination $artifactsModuleVersionDirectory -Recurse
    }
}

function Analyze {
    [DependsOn('Init')]
    [CmdletBinding()]
    param()
    process {
        $analysisSettings = @{
            ExcludeRules = @('PSAvoidUsingWriteHost')
        }

        $analysis = Invoke-ScriptAnalyzer -Path $sut -Recurse -Settings $analysisSettings -Verbose:$false
        $errors = $analysis | Where-Object { $_.Severity -eq 'Error' }
        $warnings = $analysis | Where-Object { $_.Severity -eq 'Warning' }

        if (($errors.Count -eq 0) -and ($warnings.Count -eq 0)) {
            'PSScriptAnalyzer passed without errors or warnings'
        }

        if (@($errors).Count -gt 0) {
            Write-Error -Message 'One or more Script Analyzer errors were found. Build cannot continue!'
            $errors | Format-Table -AutoSize
        }

        if (@($warnings).Count -gt 0) {
            Write-Warning -Message 'One or more Script Analyzer warnings were found. These should be corrected.'
            $warnings | Format-Table -AutoSize
        }
    }
}

function Import {
    [DependsOn('Init')]
    [CmdletBinding()]
    param()
    process {
        Import-Module -Name $artifactsManifest -Force
    }
}

function Pester {
    [DependsOn('Import')]
    [CmdletBinding()]
    param()
    process {
        Import-Module -Name $artifactsManifest -Force

        $excludedTags = @()

        if ($CI) {
            $excludedTags = @('Windows')
        }

        $pesterParams = @{
            Path = './tests'
            Output = 'Detailed'
            PassThru = $true
            ExcludeTagFilter = $excludedTags
        }

        $testResults = Invoke-Pester @pesterParams
        if ($testResults.FailedCount -gt 0) {
            throw "$($testResults.FailedCount) tests failed!"
        }
    }
}

function Hack {
    [DependsOn(('Build', 'Import'))]
    [CmdletBinding()]
    param()
    process {}
}

function Test {
    [DependsOn(('Build', 'Analyze', 'Pester'))]
    [CmdletBinding()]
    param()
    process {}
}

try {
    Push-Location
    Invoke-Step -Step $Task
} catch {
    throw $_
    exit 1
} finally {
    Pop-Location
}
