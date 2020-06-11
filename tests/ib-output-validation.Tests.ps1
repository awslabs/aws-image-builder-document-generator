. $PSScriptRoot/testhelpers.ps1

BeforeAll {
    . $PSScriptRoot/testhelpers.ps1
}

Describe 'New-ImageBuilderStep output validation tests' {
    $testcases = @(
        @{
            step = 'ExecuteBinary'
            arg  =
            @{
                'name'          = 'InstallDotnet'
                'path'          = 'C:\PathTo\dotnet_installer.exe'
                'ExecuteBinary' = $true
                'arguments'     = '/qb', '/norestart'
            }
        }, @{
            step = 'ExecutePowerShell'
            arg  =
            @{
                'name'              = 'InstallMySoftware'
                'ExecutePowerShell' = $true
                'commands'          = 'Set-SomeConfiguration -Value 10', 'Write-Host "Successfully set the configuration."'
            }
        }, @{
            step = 'ExecuteBash'
            arg  =
            @{
                'name'        = 'InstallAndValidateCorretto'
                'ExecuteBash' = $true
                'commands'    = 'sudo yum install java-11-amazon-corretto-headless -y',
                (Get-Content -Path "$PSScriptRoot/test-yaml-files/ExecuteBashExampleCommand2.sh" -Raw)
            }
        }, @{
            step = 'Reboot'
            arg  = @{
                'name'         = 'RebootStep'
                'onFailure'    = 'Abort'
                'maxAttempts'  = 2
                'Reboot'       = $true
                'delaySeconds' = 60
            }
        }, @{
            step = 'UpdateOS'
            arg  = @{
                'name'        = 'UpdateMyLinux'
                'onFailure'   = 'Abort'
                'maxAttempts' = 3
                'UpdateOS'    = $true
                'exclude'     = 'ec2-hibinit-agent'
            }
        }, @{
            step = 'S3Upload'
            arg  = @{
                'name'                  = 'MyS3UploadFile'
                'onFailure'             = 'Abort'
                'maxAttempts'           = 3
                'S3Upload'              = $true
                'ImageBuilderS3Actions' = New-ImageBuilderS3Action -source 'C:\myfolder\package.zip' -destination 's3://mybucket/path/to/package.zip'
            }
        }, @{
            step = 'S3Upload2'
            arg  = @{
                'name'                  = 'MyS3UploadFolder'
                'onFailure'             = 'Abort'
                'maxAttempts'           = 3
                'S3Upload'              = $true
                'ImageBuilderS3Actions' = New-ImageBuilderS3Action -source 'C:\myfolder\*' -destination 's3://mybucket/path/to/' -recurse
            }
        }, @{
            step = 'S3Download'
            arg  = @{
                'name'                  = 'DownloadMyFile'
                'S3Download'            = $true
                'ImageBuilderS3Actions' = New-ImageBuilderS3Action -source 's3://mybucket/path/to/package.zip' -destination 'C:\myfolder\package.zip'
            }
        }, @{
            step = 'S3Download2'
            arg  = @{
                'name'                  = 'MyS3DownloadKeyprefix'
                'S3Download'            = $true
                'maxAttempts'           = 3
                'ImageBuilderS3Actions' = New-ImageBuilderS3Action -source 's3://mybucket/path/to/*' -destination 'C:\myfolder\'
            }
        }
    )

    Context 'Comparing New-ImageBuilderStep output to example yaml files' {
        It '<step> example (<step>Example.yml) should be equal to generated yml' -TestCases $testcases {
            param ($step, $arg)
            $ExampleYaml = Get-ExampleYaml -path "$PSScriptRoot/test-yaml-files/$($step)Example.yml"
            $GeneratedYaml = New-ImageBuilderStep @arg | ConvertTo-Yaml
            $GeneratedYaml | Should -BeExactly $ExampleYaml
        }


        It 'SetRegistry example (SetRegistryExample.yml) should be equal to generated yml' {
            $action1 = @{
                'path'  = 'HKLM:\SOFTWARE\MySoftWare'
                'name'  = 'MyName'
                'value' = 'FirstVersionSoftware'
                'type'  = 'SZ'
            }
            $action1 = New-ImageBuilderRegistryAction @action1
            $action2 = @{
                'path'  = 'HKEY_CURRENT_USER\Software\Test'
                'name'  = 'Version'
                'value' = 1.1
                'type'  = 'DWORD'
            }
            $action2 = New-ImageBuilderRegistryAction @action2

            $SetRegistryArg = @{
                'name'                        = 'SetRegistryKeyValues'
                'SetRegistry'                 = $true
                'maxAttempts'                 = 3
                'ImageBuilderRegistryActions' = $action1, $action2
            }
            $SetRegistryExampleYaml = Get-ExampleYaml -path "$PSScriptRoot/test-yaml-files/SetRegistryExample.yml"
            $SetRegistryGeneratedYaml = New-ImageBuilderStep @SetRegistryArg | ConvertTo-Yaml
            $SetRegistryGeneratedYaml | Should -BeExactly $SetRegistryExampleYaml
        }
    }
}