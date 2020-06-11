$step1 = New-ImageBuilderStep 'HelloWorld' -ExecutePowerShell -Commands 'Write-Output "HelloWorld!"'
$step2 = New-ImageBuilderStep 'install-sw' -ExecutePowerShell -Commands (Get-Content ./install-sw.ps1 -Raw)
$phase1 = New-ImageBuilderPhase 'build' -steps $step1, $step2
New-ImageBuilderDocument -phases $phase1 -name 'ExampleDoc' -Description 'For Readme File'