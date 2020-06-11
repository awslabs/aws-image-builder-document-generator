#---------------------------------#
# PSScriptAnalyzer tests          #
#---------------------------------#
$Modules = Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Filter '*.psm1'
$Modules | ForEach-Object {
    Import-Module $_.FullName -Force
}

if ($Modules.count -gt 0) {
    Describe 'PSScriptAnalyzer analysis' {
        It "<Path> Should not return any violation for the rule : <IncludeRule>" -TestCases @(
            Foreach ($m in $Modules) {
                Foreach ($r in (Get-ScriptAnalyzerRule)) {
                    @{
                        IncludeRule = $r.RuleName
                        Path        = $m.FullName
                    }
                }
            }
        ) {
            param($IncludeRule, $Path)
            Invoke-ScriptAnalyzer -Path $Path -IncludeRule $IncludeRule |
            Should -BeNullOrEmpty
        }
    }
}