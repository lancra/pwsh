Describe 'Result' {
    It 'Returns true when the executable is in the path' {
        Test-PathExecutable -Executable 'git.exe' | Should -Be $true
    }

    It 'Returns false when the executable is not in the path' {
        Test-PathExecutable -Executable 'foobarbaz.exe' | Should -Be $false
    }

    It 'Does not require a file extension for the executable' {
        Test-PathExecutable -Executable 'git' | Should -Be $true
    }
}
