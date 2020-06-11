. $PSScriptRoot/testhelpers.ps1

BeforeAll {
    . $PSScriptRoot/testhelpers.ps1
}

Describe 'Testing integration with Task Orchestrator and Executor (TOE).' -Tag 'WindowsOnly' {
    BeforeAll {
        $file = New-TemporaryFile
        IBD 'TestDoc' -description 'Test document generated from PowerShell' @(
            IBP 'build' @(
                (IBS -Name 'Test_1' -ExecutePowerShell -commands "Write-Host 'HelloWorld'")
                (IBS -Name 'Reboot' -Reboot -delaySeconds 30)
            )
        ) | Out-File $file.FullName
    }
    Context 'Testing whether the module returns valid Image Builder YAML documents' {
        It 'TOE Should be able to validate document succesfully' {
            $awstoe = 'c:\toe\awstoe.exe'
            $awstoe | Should -Exist

            (& $awstoe validate -d $file.FullName | ConvertFrom-Json).validationStatus | Should -Be 'success'
        }
    }
    AfterAll { Remove-Item $file.FullName }
}