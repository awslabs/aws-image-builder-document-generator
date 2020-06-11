(IBS 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"'),
(IBS 'install-sw' -pwsh (Get-Content ./install-sw.ps1 -Raw))
| IBP 'build' | IBD 'ExampleDoc' -Description 'For Readme File'