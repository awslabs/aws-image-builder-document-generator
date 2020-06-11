. $PSScriptRoot/testhelpers.ps1

Describe 'Document validation tests' {

    BeforeAll {
        . $PSScriptRoot/testhelpers.ps1
    
        Function Get-GeneratedStep {
            param($arg, $pipeline, $name)
    
            $arg.name = $name
    
            if ($pipeline) {
                $pipeline | New-ImageBuilderStep @arg
            }
            else {
                New-ImageBuilderStep @arg
            }
        }
    }
    
    $Document = 'RunConfig_UpdateWindows.yml'
    $ExampleYaml = Get-Content "$PSScriptRoot/test-yaml-files/$Document" -Raw |
    ConvertFrom-Yaml -Ordered

    Context "$Document generation tests" {
        #$generatedTests = @()
        $Phases = @(
            @{
                name   = 'build'
                source = $ExampleYaml.phases[0]
                steps  = @(
                    @{
                        name     = 'DownloadConfigScript'
                        arg      = @{
                            S3Download     = $true
                            onFailure      = 'Abort'
                            maxAttempts    = 3
                            timeoutSeconds = 60
                        }
                        pipeline = New-ImageBuilderS3Action 's3://customer-bucket/config.ps1' 'C:\Temp\config.ps1'
                        source   = $ExampleYaml.phases[0].steps[0]
                    }, @{
                        name     = 'RunConfigScript'
                        arg      = @{
                            ExecutePowerShell = $true
                            onFailure         = 'Abort'
                            maxAttempts       = 3
                            timeoutSeconds    = 120
                        }
                        pipeline = '{{build.DownloadConfigScript.inputs[0].destination}}'
                        source   = $ExampleYaml.phases[0].steps[1]
                    }, @{
                        name     = 'Cleanup'
                        arg      = @{
                            ExecutePowerShell = $true
                            onFailure         = 'Abort'
                            maxAttempts       = 3
                            timeoutSeconds    = 120
                        }
                        pipeline = 'Remove-Item {{build.DownloadConfigScript.inputs[0].destination}}'
                        source   = $ExampleYaml.phases[0].steps[2]
                    }, @{
                        name   = 'RebootAfterConfigApplied'
                        arg    = @{
                            Reboot       = $true
                            delaySeconds = 60
                        }
                        source = $ExampleYaml.phases[0].steps[3]
                    }, @{
                        name   = 'InstallWindowsUpdates'
                        arg    = @{
                            UpdateOS = $true
                        }
                        source = $ExampleYaml.phases[0].steps[4]
                    }
                )
            }, @{
                name   = 'validate'
                source = $ExampleYaml.phases[1]
                steps  = @(
                    @{
                        name     = 'DownloadTestConfigScript'
                        arg      = @{
                            S3Download     = $true
                            onFailure      = 'Abort'
                            maxAttempts    = 3
                            timeoutSeconds = 60
                        }
                        pipeline = New-ImageBuilderS3Action 's3://customer-bucket/testConfig.ps1' 'C:\Temp\testConfig.ps1'
                        source   = $ExampleYaml.phases[1].steps[0]
                    }, @{
                        name     = 'ValidateConfigScript'
                        arg      = @{
                            ExecutePowerShell = $true
                            onFailure         = 'Abort'
                            maxAttempts       = 3
                            timeoutSeconds    = 120
                        }
                        pipeline = '{{validate.DownloadTestConfigScript.inputs[0].destination}}'
                        source   = $ExampleYaml.phases[1].steps[1]
                    }, @{
                        name     = 'Cleanup'
                        arg      = @{
                            ExecutePowerShell = $true
                            onFailure         = 'Abort'
                            maxAttempts       = 3
                            timeoutSeconds    = 120
                        }
                        pipeline = 'Remove-Item {{validate.DownloadTestConfigScript.inputs[0].destination}}'
                        source   = $ExampleYaml.phases[1].steps[2]
                    }
                )
            }, @{
                name   = 'test'
                source = $ExampleYaml.phases[2]
                steps  = @(
                    @{
                        name     = 'DownloadTestConfigScript'
                        arg      = @{
                            S3Download     = $true
                            onFailure      = 'Abort'
                            maxAttempts    = 3
                            timeoutSeconds = 60
                        }
                        pipeline = New-ImageBuilderS3Action 's3://customer-bucket/testConfig.ps1' 'C:\Temp\testConfig.ps1'
                        source   = $ExampleYaml.phases[2].steps[0]
                    }, @{
                        name     = 'ValidateConfigScript'
                        arg      = @{
                            ExecutePowerShell = $true
                            onFailure         = 'Abort'
                            maxAttempts       = 3
                            timeoutSeconds    = 120
                        }
                        pipeline = '{{test.DownloadTestConfigScript.inputs[0].destination}}'
                        source   = $ExampleYaml.phases[2].steps[1]
                    }
                )
            }
        )

        $Phases | ForEach-Object {
            It "$Document - Phase: $($_.name) - Step: <name> - individual step generation test" -TestCases $_.steps {
                param($arg, $pipeline, $source, $name)

                $generated = Get-GeneratedStep -arg $arg -pipeline $pipeline -Name $name
                $source | ConvertTo-Yaml | Should -BeExactly ($generated | ConvertTo-Yaml)
            }

            It "$Document - Phase: <name> - individual phase generation test" -TestCases $_ {
                param($name, $source, $steps)

                $steps | ForEach-Object {
                    Get-GeneratedStep @_
                } |
                New-ImageBuilderPhase $name |
                ConvertTo-Yaml |
                Should -BeExactly ($source | ConvertTo-Yaml)
            }
        }
    }
}
