# Taken with love from @psake (https://github.com/psake/psake/blob/aca6ea9e99135f8a5620bd2496c532da6f3a4059/tests/Help.tests.ps1)

BeforeDiscovery {
    function script:Limit-Parameters {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [object[]]$Parameters
        )
        begin {
            $commonParameters = @(
                'Confirm',
                'Debug',
                'ErrorAction',
                'ErrorVariable',
                'InformationAction',
                'InformationVariable',
                'OutBuffer',
                'OutVariable',
                'PipelineVariable',
                'Verbose',
                'WarningAction',
                'WarningVariable',
                'Whatif'
            )
        }
        process {
            $Parameters |
                Where-Object { $_.Name -notin $commonParameters } |
                Sort-Object -Property Name -Unique
        }
    }

    $moduleName = $env:BHProjectName
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $artifactsDirectory = Join-Path -Path $ENV:BHProjectPath -ChildPath 'artifacts'
    $artifactsModuleDirectory = Join-Path -Path $artifactsDirectory -ChildPath $moduleName
    $artifactsModuleVersionDirectory = Join-Path -Path $artifactsModuleDirectory -ChildPath $manifest.ModuleVersion
    $artifactsManifestPath = Join-Path -Path $artifactsModuleVersionDirectory -Child "$($moduleName).psd1"

    # Get module commands
    # Remove all versions of the module from the session. Pester can't handle multiple versions.
    Get-Module -Name $moduleName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $artifactsManifestPath -Verbose:$false -ErrorAction Stop
    $getCommandParams = @{
        Module = (Get-Module -Name $moduleName)
        CommandType = @(
            [System.Management.Automation.CommandTypes]::Cmdlet,
            [System.Management.Automation.CommandTypes]::Function
        )
    }
    $script:commands = Get-Command @getCommandParams

    ## When testing help, remember that help is cached at the beginning of each session.
    ## To test, restart session.
}

Describe "Test help for <_.Name>" -ForEach $script:commands {

    BeforeDiscovery {
        # Get command help, parameters, and links
        $command = $_
        $script:commandHelp = Get-Help $command.Name -ErrorAction SilentlyContinue
        $commandParameters = Limit-Parameters -Parameters $command.ParameterSets.Parameters
        $script:commandParameterNames = $commandParameters.Name
    }

    BeforeAll {
        # These vars are needed in both discovery and test phases so we need to duplicate them here
        $command = $_
        $commandHelp = Get-Help $command.Name -ErrorAction SilentlyContinue
        $commandParameters = Limit-Parameters -Parameters $command.ParameterSets.Parameters
        $script:commandParameterNames = $commandParameters.Name
        $helpParameters = Limit-Parameters -Parameters $commandHelp.Parameters.Parameter
        $script:helpParameterNames = $helpParameters.Name
    }

    # If help is not found, synopsis in auto-generated help is the syntax diagram
    It 'Help is not auto-generated' {
        $commandHelp.Synopsis | Should -Not -BeLike '*`[`<CommonParameters`>`]*'
    }

    # Should be a description for every function
    It "Has description" {
        $commandHelp.Description | Should -Not -BeNullOrEmpty
    }

    # Should be at least one example
    It "Has example code" {
        ($commandHelp.Examples.Example | Select-Object -First 1).Code | Should -Not -BeNullOrEmpty
    }

    # Should be at least one example description
    It "Has example help" {
        ($commandHelp.Examples.Example.Remarks | Select-Object -First 1).Text | Should -Not -BeNullOrEmpty
    }

    Context "Parameter <_.Name>" -Foreach $commandParameters {

        BeforeAll {
            $parameter = $_
            $parameterHelp = $commandHelp.parameters.parameter | Where-Object Name -eq $parameter.Name
            $script:parameterHelpType = if ($parameterHelp.ParameterValue) { $parameterHelp.ParameterValue.Trim() }
        }

        # Should be a description for every parameter
        It "Has description" {
            $parameterHelp.Description.Text | Should -Not -BeNullOrEmpty
        }

        # Required value in Help should match IsMandatory property of parameter
        It "Has correct [mandatory] value" {
            $codeMandatory = $_.IsMandatory.toString()
            $parameterHelp.Required | Should -Be $codeMandatory
        }

        # Parameter type in help should match code
        It "Has correct parameter type" {
            $parameterHelpType | Should -Be $parameter.ParameterType.Name
        }
    }

    Context "Test <_> help parameter help for <commandName>" -Foreach $helpParameterNames {

        # Shouldn't find extra parameters in help.
        It "finds help parameter in code: <_>" {
            $_ -in $parameterNames | Should -Be $true
        }
    }
}
