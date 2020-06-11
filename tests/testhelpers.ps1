Function Get-ExampleYaml {
    [cmdletbinding()]
    Param (
        [string]$Path
    )
    Get-Content -Path $Path -Raw |
    ConvertFrom-Yaml -Ordered |
    ConvertTo-Yaml
}

$requiredModules = 'powershell-yaml', 'PSScriptAnalyzer'
$requiredModules.forEach{
    if (!(Get-Module $_ -ListAvailable)) {
        Install-Module -Name $_ -Repository PSGallery -Force
    }
}

$Modules = Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Filter '*.psd1'
$Modules | ForEach-Object {
    if (! (Get-Module | Where-Object { $_.Path -eq $_.FullName })) {
        Import-Module $_.FullName -Force
    }
}