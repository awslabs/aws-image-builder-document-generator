#Schema: https://docs.aws.amazon.com/imagebuilder/latest/userguide/managing-image-builder-console.html#document-schema
#Actions: https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-action-modules.html
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
[CmdletBinding()]
param()

class ImageBuilderStep {
    [string]$name
    [string]$action
    [int]$timeoutSeconds
    [string]$onFailure
    [int]$maxAttempts
    $inputs

    ImageBuilderStep($name, $action, $inputs) {
        $this.name = $name
        $this.action = $action
        $this.inputs = $inputs
    }
}

class ImageBuilderPhase {
    [string]$name
    [ImageBuilderStep[]]$steps

    ImageBuilderPhase($name, $steps) {
        $this.name = $name
        $this.steps = $steps
    }
}

class ImageBuilderS3Action {
    [string]$source
    [string]$destination
    [bool]$recurse

    ImageBuilderS3Action($source, $destination) {
        $this.source = $source
        $this.destination = $destination
    }
}

class ImageBuilderRegistryAction {
    [string]$path
    [string]$name
    $value
    [string]$type

    ImageBuilderRegistryAction($path, $name, $value, $type) {
        $this.path = $path
        $this.name = $name
        $this.value = $value
        $this.type = $type
    }
}

Function New-ImageBuilderDocument {
    <#
      .SYNOPSIS
      Creates a new EC2 ImageBuilder Document (YAML)
      .DESCRIPTION
      This function creates a EC2 ImageBuilder Document from 'ImageBuilderPhase' objects.
      'ImageBuilderPhase' object are created from using the 'New-ImageBuilderPhase' command.
      .NOTES
      Author:      Javy de Koning
      Copyright:   Amazon Web Services
      .PARAMETER name
      Name of the document.
      .PARAMETER description
      Description of the document.
      .PARAMETER phases
      A list of phases. 'ImageBuilderPhase' objects are created using the 'New-ImageBuilderPhase' command.
      .EXAMPLE
      $step  = New-ImageBuilderStep 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"'
      $phase = New-ImageBuilderPhase 'build' -steps $step
      New-ImageBuilderDocument -phases $phase -name 'ibdoc' -Description 'sample description'

      name: ibdoc
      description: sample description
      schemaVersion: "1.0"
      phases:
      - name: build
        steps:
        - name: HelloWorld
          action: ExecutePowerShell
          inputs:
            commands:
            - Write-Output "HelloWorld!"
      .EXAMPLE
      New-ImageBuilderStep 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"' |
      New-ImageBuilderPhase 'build' |
      New-ImageBuilderDocument -name 'ibdoc' -Description 'sample description'

      name: ibdoc
      description: sample description
      schemaVersion: "1.0"
      phases:
      - name: build
        steps:
        - name: HelloWorld
          action: ExecutePowerShell
          inputs:
            commands:
            - Write-Output "HelloWorld!"
      .EXAMPLE
      IBD 'ExampleDoc' -Description 'For Readme File' @(
        IBP 'build' @(
          (IBS 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"')
        )
      )

      name: ExampleDoc
      description: For Readme File
      schemaVersion: "1.0"
      phases:
      - name: build
        steps:
        - name: HelloWorld
          action: ExecutePowerShell
          inputs:
            commands:
            - Write-Output "HelloWorld!"
      .OUTPUTS
      System.String. New-ImageBuilderDocument returns a YAML formatted string.
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-application-documents.html
      .LINK
      https://github.com/awslabs/aws-image-builder-document-generator/blob/master/README.md
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-action-modules.html
    #>
    [Alias('New-EC2IBDocument', 'IBDocument', 'IBD')]
    [CmdletBinding()]
    param(
        [parameter(Mandatory, Position = 0)]
        [string]$name,

        [parameter(Mandatory)]
        [string]$description,

        [parameter(Mandatory, Position = 1, ValueFromPipeline = $true)]
        [ImageBuilderPhase[]]$phases
    )

    Begin {
        $result = [ordered]@{
            'name'          = $name
            'description'   = $description
            'schemaVersion' = '1.0'
            'phases'        = @()
        }
    }

    Process {
        $result.phases += $Phases
    }

    End {
        $result | ConvertTo-Yaml
    }
}

Function New-ImageBuilderPhase {
    <#
      .SYNOPSIS
      Creates a new 'ImageBuilderPhase' object, to be consumed by 'New-ImageBuilderDocument'
      .DESCRIPTION
      Creates a new 'ImageBuilderPhase' object, to be consumed by 'New-ImageBuilderDocument'
      .NOTES
      Author:      Javy de Koning
      Copyright:   Amazon Web Services
      .PARAMETER name
      Name of the phase. Image Builder executes phases called build, validate, and test in the image build pipeline.
      .PARAMETER steps
      A list of steps. 'ImageBuilderStep' objects are created using the 'New-ImageBuilderStep' command.
      .EXAMPLE
      $step  = New-ImageBuilderStep 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"'
      $phase = New-ImageBuilderPhase 'build' -steps $step
      .EXAMPLE
      New-ImageBuilderStep 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"' |
      New-ImageBuilderPhase 'build'
      .EXAMPLE
      IBP 'build' @(
        (IBS 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"')
      )
      .OUTPUTS
      ImageBuilderPhase. object to be consumed by 'New-ImageBuilderDocument'
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-application-documents.html
      .LINK
      https://github.com/awslabs/aws-image-builder-document-generator/blob/master/README.md
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-action-modules.html
    #>
    [Alias('New-EC2IBPhase', 'IBPhase', 'IBP')]
    [CmdletBinding()]
    param(
        [parameter(Mandatory, Position = 0)]
        [ValidateSet('build', 'validate', 'test')]
        [string]$name,

        [parameter(Mandatory, Position = 1, ValueFromPipeline = $true)]
        [ImageBuilderStep[]]$steps
    )
    process {
        [array]$Result += $steps
        $Result.name | Group-Object | ForEach-Object {
            if ($_.count -gt 1) { Throw 'Step with name: {0} is NOT unique.' -f $_.name }
        }
    }
    end { [ImageBuilderPhase]::new($name, $result) }
}

Function New-ImageBuilderS3Action {
    <#
      .SYNOPSIS
      Creates a new 'ImageBuilderS3Action' object, to be consumed by 'New-ImageBuilderStep'
      .DESCRIPTION
      Creates a new 'ImageBuilderS3Action' object, to be consumed by 'New-ImageBuilderStep'
      .NOTES
      Author:      Javy de Koning
      Copyright:   Amazon Web Services
      .PARAMETER source
      Source supports wildcard denoted by a *.
      .PARAMETER destination
      Target path (remote when uploading, local when downloading).
      .PARAMETER recurse
      When set, performs S3Upload or S3Download actions recursively.
      .EXAMPLE
      New-ImageBuilderS3Action -source 's3://sample-bucket/sample1.ps1' -destination 'C:\Temp\sample1.ps1'

      source                         destination         recurse
      ------                         -----------         -------
      s3://sample-bucket/sample1.ps1 C:\Temp\sample1.ps1   False
      .EXAMPLE
      ibs3a 'C:\myfolder\*' 's3://mybucket/path/to/' -recurse

      source        destination            recurse
      ------        -----------            -------
      C:\myfolder\* s3://mybucket/path/to/    True
      .EXAMPLE
      ibs3a 'C:\myfolder\*' 's3://mybucket/path/to/' -recurse |
      ibs 'build' -S3Upload
      .OUTPUTS
      ImageBuilderS3Action. object to be consumed by 'New-ImageBuilderStep'
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-application-documents.html
      .LINK
      https://github.com/awslabs/aws-image-builder-document-generator/blob/master/README.md
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-action-modules.html
    #>
    [Alias('New-EC2IBS3Action', 'IBS3Action', 'IBS3A')]
    [CmdletBinding()]
    param(
        [parameter(Mandatory, Position = 0)]
        [string]$source,

        [parameter(Mandatory, Position = 1)]
        [string]$destination,

        [parameter()]
        [switch]$recurse
    )

    $obj = [ImageBuilderS3Action]::new($source, $destination)

    if ($PSBoundParameters.ContainsKey('recurse')) {
        $obj.recurse = $true
    }

    $obj
}

Function New-ImageBuilderRegistryAction {
    <#
      .SYNOPSIS
      Creates a new 'ImageBuilderRegistryAction' object, to be consumed by 'New-ImageBuilderStep'
      .DESCRIPTION
      Creates a new 'ImageBuilderRegistryAction' object, to be consumed by 'New-ImageBuilderStep'.
      The Registry action module allows you to set the value for the specified registry key.
      If a registry key does not exist, it is created in the defined path.
      This feature applies only to Windows.
      .NOTES
      Author:      Javy de Koning
      Copyright:   Amazon Web Services
      .PARAMETER name
      Name of registry key.
      .PARAMETER path
      Path of registry key. For example 'HKCU:\Software\Test'
      .PARAMETER type
      Value type of registry key. (BINARY, DWORD, QWORD, SZ, EXPAND_SZ, MULTI_SZ)
      .PARAMETER value
      Value of registry key.
      .EXAMPLE
      New-ImageBuilderRegistryAction -name 'Version' -Type 'DWORD' -Value '1.1' -Path 'HKCU:\Software\Test'

      path                name    value type
      ----                ----    ----- ----
      HKCU:\Software\Test Version   1.1 DWORD
      .EXAMPLE
      ibra 'Version' 1.1 'DWORD' 'HKCU:\Software\Test'

      path                name    value type
      ----                ----    ----- ----
      HKCU:\Software\Test Version   1.1 DWORD
      .OUTPUTS
      ImageBuilderRegistryAction. object to be consumed by 'New-ImageBuilderStep'
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-application-documents.html
      .LINK
      https://github.com/awslabs/aws-image-builder-document-generator/blob/master/README.md
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-action-modules.html
    #>
    [Alias('New-EC2IBRegAction', 'IBRegAction', 'IBRA')]
    [CmdletBinding()]
    param(
        [parameter(Mandatory, Position = 3)]
        [ValidatePattern('^(KEY_CLASSES_ROOT|HKCR:|HKEY_USERS|HKU:|HKEY_LOCAL_MACHINE|HKLM:|HKEY_CURRENT_CONFIG|HKCC:|HKEY_CURRENT_USER|HKCU:).*')]
        [string]$path,

        [parameter(Mandatory, Position = 0)]
        [string]$name,

        [parameter(Mandatory, Position = 1)]
        $value,

        [parameter(Mandatory, Position = 2)]
        [ValidateSet('BINARY', 'DWORD', 'QWORD', 'SZ', 'EXPAND_SZ', 'MULTI_SZ')]
        [string]$type
    )

    [ImageBuilderRegistryAction]::new($path, $name, $value, $type)
}
Function New-ImageBuilderStep {
    <#
      .SYNOPSIS
      Creates a new 'ImageBuilderStep' object, to be consumed by 'New-ImageBuilderPhase'
      .DESCRIPTION
      Creates a new 'ImageBuilderStep' object, to be consumed by 'New-ImageBuilderPhase'
      Steps are individual units of work that comprise the workflow for each phase.
      .NOTES
      Author:      Javy de Koning
      Copyright:   Amazon Web Services
      .PARAMETER name
      Name of registry key.
      .PARAMETER onFailure
      Path of registry key. For example 'HKCU:\Software\Test'.
      .PARAMETER timeoutSeconds
      Value type of registry key. (BINARY, DWORD, QWORD, SZ, EXPAND_SZ, MULTI_SZ).
      .PARAMETER maxAttempts
      Value of registry key
      .PARAMETER ExecuteBinary
      Sets the step action to ExecuteBinary.
      .PARAMETER path
      Specifies the path to the binary file for execution.
      .PARAMETER arguments
      Specifies the list of arguments to pass the the ExecuteBinary Action. For example: '/qb','/norestart','/silent'
      .PARAMETER ExecuteBash
      Sets the step action to ExecuteBash.
      .PARAMETER ExecutePowerShell
      Sets the step action to ExecutePowerShell.
      .PARAMETER commands
      Specifies the Bash or PowerShell commands to run.
      .PARAMETER Reboot
      Sets the step action to Reboot.
      .PARAMETER delaySeconds
      Specifies the seconds by which the Reboot needs to be delayed.
      .PARAMETER UpdateOS
      Sets the step action to UpdateOS.
      .PARAMETER exclude
      Specifies one or more updates to exclude from installation .
      .PARAMETER S3Upload
      Sets the step action to S3Upload.
      .PARAMETER S3Download
      Sets the step action to S3Download.
      .PARAMETER ImageBuilderS3Actions
      Accepts ImageBuilderS3Action objects created by the New-ImageBuilderS3Action command.
      .PARAMETER SetRegistry
      Sets the step action to SetRegistry.
      .PARAMETER ImageBuilderRegistryActions
      Accepts ImageBuilderRegistryAction objects created by the New-ImageBuilderRegistryActions command.
      .EXAMPLE
      New-ImageBuilderStep 'InstallDotnet' -ExecuteBinary -path 'C:\PathTo\dotnet_installer.exe' -arguments '/qb','/norestart','/silent'
      .EXAMPLE
      New-ImageBuilderStep 'HelloWorld' -pwsh -commands 'Write-Output "HelloWorld!"'
      .EXAMPLE
      New-ImageBuilderStep 'CreateLogsFolder' -sh 'mkdir logs' -onFailure 'Abort'
      .EXAMPLE
      New-ImageBuilderStep 'Reboot' -Reboot -DelaySeconds 0
      .EXAMPLE
      New-ImageBuilderStep 'AnotherReboot' -Reboot -maxAttempts 3
      .EXAMPLE
      New-ImageBuilderStep 'DownloadFile' -S3Download -ImageBuilderS3Actions (ibs3a 'C:\myfolder\*' 's3://mybucket/path/to/' -recurse)
      .EXAMPLE
      New-ImageBuilderStep 'RegAddVersion' -SetRegistry (ibra 'Version' 1.1 'DWORD' 'HKCU:\Software\Test')
      .OUTPUTS
      ImageBuilderStep. object to be consumed by 'New-ImageBuilderPhase'
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-application-documents.html
      .LINK
      https://github.com/awslabs/aws-image-builder-document-generator/blob/master/README.md
      .LINK
      https://docs.aws.amazon.com/imagebuilder/latest/userguide/image-builder-action-modules.html
    #>
    [Alias('New-EC2IBStep', 'IBStep', 'IBS')]
    [CmdletBinding()]
    param(
        [parameter(Mandatory, Position = 0)]
        [ValidatePattern('^[a-zA-Z0-9_-]+$')]
        [string]$name,

        [parameter()]
        [ValidateSet('Abort', 'Continue')]
        [string]$onFailure,

        [parameter()]
        [ValidateScript( { ($_ -eq -1) -or ($_ -gt 0) })]
        [int]$timeoutSeconds,

        [parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$maxAttempts,

        #Set for Binary
        [Parameter(ParameterSetName = 'ExecuteBinary')]
        [switch]$ExecuteBinary,
        [Parameter(ParameterSetName = 'ExecuteBinary', Position = 1)]
        [string]$path,
        [Parameter(ParameterSetName = 'ExecuteBinary', Position = 2)]
        [string[]]$arguments,

        #Set for Bash and PowerShell
        [Parameter(ParameterSetName = 'ExecuteBash')]
        [Alias('sh')]
        [switch]$ExecuteBash,
        [Parameter(ParameterSetName = 'ExecutePowerShell')]
        [Alias('pwsh')]
        [switch]$ExecutePowerShell,
        [Parameter(ParameterSetName = 'ExecutePowerShell', ValueFromPipeline = $true, Position = 1)]
        [Parameter(ParameterSetName = 'ExecuteBash', ValueFromPipeline = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]]$commands,

        #Set for Reboot
        [Parameter(ParameterSetName = 'Reboot')]
        [switch]$Reboot,
        [Parameter(ParameterSetName = 'Reboot', Position = 1)]
        [int]$delaySeconds = 0,

        #Set for UpdateOS
        [Parameter(ParameterSetName = 'UpdateOS')]
        [switch]$UpdateOS,
        [Parameter(ParameterSetName = 'UpdateOS')]
        [string[]]$exclude,

        #Set for s3 actions
        [Parameter(ParameterSetName = 'S3Upload')]
        [Alias('s3ul')]
        [switch]$S3Upload,
        [Parameter(ParameterSetName = 'S3Download')]
        [Alias('s3dl')]
        [switch]$S3Download,
        [Parameter(ParameterSetName = 'S3Upload', ValueFromPipeline = $true, Position = 1)]
        [Parameter(ParameterSetName = 'S3Download', ValueFromPipeline = $true, Position = 1)]
        [ImageBuilderS3Action[]]$ImageBuilderS3Actions,

        #Set for registry actions
        [Parameter(ParameterSetName = 'SetRegistry')]
        [switch]$SetRegistry,
        [Parameter(ParameterSetName = 'SetRegistry', ValueFromPipeline = $true, Position = 1)]
        [ImageBuilderRegistryAction[]]$ImageBuilderRegistryActions
    )

    process {
        $obj = [ImageBuilderStep]::new($name, $PsCmdlet.ParameterSetName, [ordered]@{ })
        if ($PSBoundParameters.ContainsKey('timeoutSeconds')) {
            $obj.timeoutSeconds = $timeoutSeconds
        }

        if ($PSBoundParameters.ContainsKey('onFailure')) {
            $obj.onFailure = $onFailure
        }

        if ($PSBoundParameters.ContainsKey('maxAttempts')) {
            $obj.maxAttempts = $maxAttempts
        }

        switch ($PsCmdlet.ParameterSetName) {
            'ExecutePowerShell' {
                $obj.inputs += @{ 'commands' = [array]$commands }
            }
            'ExecuteBash' {
                $obj.inputs += @{ 'commands' = [array]$commands }
            }
            'Reboot' {
                if ($PSBoundParameters.ContainsKey('delaySeconds')) {
                    $obj.inputs += @{ 'delaySeconds' = $delaySeconds }
                }
            }
            'ExecuteBinary' {
                $obj.inputs += [ordered]@{
                    'path'      = $path
                    'arguments' = $arguments
                }
            }
            'UpdateOS' {
                if ($PSBoundParameters.ContainsKey('exclude')) {
                    $obj.inputs += @{
                        'exclude' = [array]$exclude
                    }
                }
            }
            'S3Upload' {
                $obj.inputs = @($ImageBuilderS3Actions)
            }
            'S3Download' {
                $obj.inputs = @($ImageBuilderS3Actions)
            }
            'SetRegistry' {
                $obj.inputs = @($ImageBuilderRegistryActions)
            }
        }

        #Trash inputs if they don't exist
        if ($obj.inputs.Count -eq 0) {
            $obj.inputs = $null
        }

        [array]$Result += $obj
    }
    end { $Result }
}

$ExpArg = @{
    Function = 'New-ImageBuilderDocument',
    'New-ImageBuilderPhase',
    'New-ImageBuilderS3Action',
    'New-ImageBuilderRegistryAction',
    'New-ImageBuilderStep'
    Alias    = 'New-EC2IBDocument', 'IBDocument', 'IBD',
    'New-EC2IBPhase', 'IBPhase', 'IBP',
    'New-EC2IBS3Action', 'IBS3Action', 'IBS3A',
    'New-EC2IBRegAction', 'IBRegAction', 'IBRA',
    'New-EC2IBStep', 'IBStep', 'IBS'
}
Export-ModuleMember @ExpArg