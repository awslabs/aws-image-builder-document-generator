. $PSScriptRoot/testhelpers.ps1

BeforeAll {
    . $PSScriptRoot/testhelpers.ps1
}

Describe 'DSL like syntax should generate correct yml document.' {
    BeforeAll {
        $docName = 'Amazon Corretto 11'
        $docDesc = 'Installs Amazon Corretto 11 for Windows in accordance with the Amazon Corretto 11 User Guide at https://docs.aws.amazon.com/corretto/latest/corretto-11-ug/windows-7-install.html.'
        $ExampleYaml = Get-ExampleYaml -path "$PSScriptRoot/test-yaml-files/CorrettoExample.yml"
    }

    Context 'Testing whether the module returns valid Image Builder YAML documents' {
        It 'Generates a correct YAML' {
            IBD $docName -description $docDesc @(
                IBP 'build' @(
                    (IBS 'Installer' -ExecutePowerShell -timeoutSeconds 15 -commands "Write-Host 'amazon-corretto-11-x64-windows-jdk.msi'"),
                    (IBS 'InstallerUri' -ExecutePowerShell -timeoutSeconds 15 -commands "Write-Host 'https://corretto.aws/downloads/latest/{{build.Installer.outputs.stdout}}'")
                )
            ) | Should -BeExactly $ExampleYaml
        }
    }

    Context 'Users should be able to use Pipeline to generate valid Documents' {
        It 'Generates a correct IB document' {
            $Step1 = "Write-Host 'amazon-corretto-11-x64-windows-jdk.msi'" | IBS 'Installer' -ExecutePowerShell -timeoutSeconds 15
            $Step2 = "Write-Host 'https://corretto.aws/downloads/latest/{{build.Installer.outputs.stdout}}'" | IBS 'InstallerUri' -ExecutePowerShell -timeoutSeconds 15
            $Step1, $Step2 | IBP 'build' | IBD $docName -Description $docDesc | Should -BeExactly $ExampleYaml
        }
    }
}