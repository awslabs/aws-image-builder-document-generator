IBD 'ExampleDoc' -Description 'For Readme File' @(
    IBP 'build' @(
        (IBS 'HelloWorld' -pwsh 'Write-Output "HelloWorld!"'),
        (IBS 'install-sw' -pwsh (Get-Content ./install-sw.ps1 -Raw))
    )
)