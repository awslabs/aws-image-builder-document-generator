![Build Status](https://codebuild.eu-west-1.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiNWh6N21DcnM4NWdqcTluVnJUTGVMOEQ0MWwzSHdQYVIveVIrbDFpeXpKV2ptSEdXZ2taSEdqc3ZHZGVodk5JeWttcDNkMXlwcHArTEFNRjVkcFhzdi9nPSIsIml2UGFyYW1ldGVyU3BlYyI6IklacnVXeWQraFBSc0UxQ2wiLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master)

# aws-image-builder-document-generator

This module allows you use file content from script files (Such as `.ps1` or `.sh`) and embed them inside Image Builder YAML documents.

This enables users to develop and test scripts using their favorite IDE's, Linters and Testing frameworks which is not possible when you are writing code directly in YAML documents.

This tool is developed in PowerShell to enable cross-platform support making it compatible with both Linux and Windows CI/CD pipelines. The goal of this module is to help accelerate the development of EC2 Image Builder components.

## Functions & Aliases

This module provides the following Functions and Aliases:

| Function                       | Alias                                 |
| ------------------------------ | ------------------------------------- |
| New-ImageBuilderDocument       | IBD, New-EC2IBDocument, IBDocument    |
| New-ImageBuilderPhase          | IBP, New-EC2IBPhase, IBPhase          |
| New-ImageBuilderStep           | IBS, New-EC2IBStep, IBStep            |
| New-ImageBuilderS3Action       | IBS3A, New-EC2IBS3Action, IBS3Action  |
| New-ImageBuilderRegistryAction | IBRA, New-EC2IBRegAction, IBRegAction |

## Workflow

Below we will provide multiple options to generate the following EC2 Image Builder YAML document. The command for the second step is stored as `install-sw.ps1`

```yaml
name: ExampleDoc
description: For Readme File
schemaVersion: '1.0'
phases:
  - name: build
    steps:
      - name: HelloWorld
        action: ExecutePowerShell
        inputs:
          commands:
            - Write-Output "HelloWorld!"
      - name: install-sw
        action: ExecutePowerShell
        inputs:
          commands:
            - |-
              [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
              Install-Module PowerShellGet, PackageManagement  -Force -SkipPublisherCheck -Scope CurrentUser -AllowClobber
              $pkg = Install-PackageProvider -Name NuGet -Force
              Write-Output "Installed NuGet version '$($pkg.version)'"
```

### Option 1 - DSL Syntax

```PowerShell
IBD 'ExampleDoc' -Description 'For Readme File' @(
  IBP 'build' @(
     (IBS 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"'),
     (IBS 'install-sw' -pwsh (Get-Content ./install-sw.ps1 -Raw))
  )
)
```

### Option 2 - Verbose PowerShell example

```PowerShell
$step1  = New-ImageBuilderStep 'HelloWorld' -ExecutePowerShell -Commands 'Write-Output "HelloWorld!"'
$step2  = New-ImageBuilderStep 'install-sw' -ExecutePowerShell -Commands (Get-Content ./install-sw.ps1 -Raw)
$phase1 = New-ImageBuilderPhase 'build' -steps $step1, $step2
New-ImageBuilderDocument -phases $phase1 -name 'ExampleDoc' -Description 'For Readme File'
```

### Option 3 - Using the pipeline

```PowerShell
(IBS 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"'),
(IBS 'install-sw' -pwsh (Get-Content ./install-sw.ps1 -Raw))
| IBP 'build' | IBD 'ExampleDoc' -Description 'For Readme File'
```

## Available step actions

A more complex **fictional** example to demonstrate available **actions**:

```PowerShell
IBD 'ExampleDoc' -Description 'For Readme File' @(
  IBP 'build' @(
    IBS 'InstallDotnet' -ExecuteBinary -path 'C:\PathTo\dotnet_installer.exe' -arguments '/qb','/norestart','/silent'
    IBS 'HelloWorld' -pwsh -commands 'Write-Output "HelloWorld!"'
    IBS 'CreateLogsFolder' -sh 'mkdir logs' -onFailure 'Abort'
    IBS 'Reboot' -Reboot -DelaySeconds 0
    IBS 'AnotherReboot' -Reboot -maxAttempts 3
    IBS 'DownloadFile' -S3Download -ImageBuilderS3Actions (ibs3a 'C:\myfolder\*' 's3://mybucket/path/to/' -recurse)
    IBS 'RegAddVersion' -SetRegistry (ibra 'Version' '1.1' 'DWORD' 'HKCU:\Software\Test')
  )
)
```

Would create:

```YAML
name: ExampleDoc
description: For Readme File
schemaVersion: "1.0"
phases:
- name: build
  steps:
  - name: InstallDotnet
    action: ExecuteBinary
    inputs:
      path: C:\PathTo\dotnet_installer.exe
      arguments:
      - /qb
      - /norestart
      - /silent
  - name: HelloWorld
    action: ExecutePowerShell
    inputs:
      commands:
      - Write-Output "HelloWorld!"
  - name: CreateLogsFolder
    action: ExecuteBash
    onFailure: Abort
    inputs:
      commands:
      - mkdir logs
  - name: Reboot
    action: Reboot
    inputs:
      delaySeconds: 0
  - name: AnotherReboot
    action: Reboot
    maxAttempts: 3
  - name: DownloadFile
    action: S3Download
    inputs:
    - source: C:\myfolder\*
      destination: s3://mybucket/path/to/
      recurse: true
  - name: RegAddVersion
    action: SetRegistry
    inputs:
    - path: HKCU:\Software\Test
      name: Version
      value: "1.1"
      type: DWORD
```

## Validating the whether documents are formatted correctly

You can validate whether these documents are considered valid in your CI/CD pipeline by leveraging TOE.

The TOE application allows you to validate whether a document is valid using the `validate` command. For example, you can use it as follows on Windows:

```powershell
(& 'C:\toe.exe' validate -d 'c:\document.yml' | ConvertFrom-json).validationStatus
```

This should return 'success' if your document is formatted correctly.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.