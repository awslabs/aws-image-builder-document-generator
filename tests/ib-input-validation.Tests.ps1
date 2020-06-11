. $PSScriptRoot/testhelpers.ps1

BeforeAll {
    . $PSScriptRoot/testhelpers.ps1
}

Describe "Input validation tests" {
    Context 'New-ImageBuilderStep input validation tests' {
        $IbStepNameTestCases = 'Space Test', 'Tab   Test', ' StartingWhiteSpace', 'TrailingWhiteSpace ' |
        ForEach-Object {
            @{
                Step = $_
                Prop = 'name'
                Arg  = @{
                    name              = $_
                    commands          = 'HelloWorld'
                    ExecutePowerShell = $true
                }
            }
        }

        $IbInvalidTimeOutCases = -2, 0, 'astring' |
        ForEach-Object {
            @{
                Step = $_
                Prop = 'timeoutSeconds'
                Arg  = @{
                    name              = 'Test'
                    timeoutSeconds    = $_
                    commands          = 'HelloWorld'
                    ExecutePowerShell = $true
                }
            }
        }

        $IbValidTimeOutCases = -1, 20, 60 |
        ForEach-Object {
            @{
                Step = $_
                Arg  = @{
                    name              = 'Test'
                    timeoutSeconds    = $_
                    commands          = 'HelloWorld'
                    ExecutePowerShell = $true
                }
            }
        }

        It 'New-ImageBuilderStep should NOT accept "<step>" in "<Prop>" property' -TestCases (
            $IbStepNameTestCases + $IbInvalidTimeOutCases) {
            param($Arg)
            $block = {
                New-ImageBuilderStep @Arg
            }
            $block | Should -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
        }

        It 'New-ImageBuilderStep should accept "<step>" in "timeoutSeconds" property' -TestCases $IbValidTimeOutCases {
            param($Arg)
            $block = {
                New-ImageBuilderStep @Arg
            }
            $block | Should -Not -Throw -ExceptionType ([System.Management.Automation.ParameterBindingException])
        }

        It 'New-ImageBuilderStep should NOT accept empty string or empty array as commands' {
            { IBS -Name 'Test' -ExecutePowerShell -Commands '' } | Should -Throw
            { IBS -Name 'Test' -ExecuteBash -Commands '' } | Should -Throw
            { IBS -Name 'Test' -ExecutePowerShell -Commands @() } | Should -Throw
            { IBS -Name 'Test' -ExecuteBash -Commands @() } | Should -Throw
        }

        It 'New-ImageBuilderPhase should NOT accept duplicate step names' {
            $Step = IBS -Name 'Test' -ExecutePowerShell -Commands 'Write-Output "Test"'
            { $Step, $Step | New-ImageBuilderPhase -Name 'build' } | Should -Throw
            { New-ImageBuilderPhase -Name 'test' -steps $Step, $Step } | Should -Throw
        }
    }
}