#-----------------#
# Header          #
#-----------------#
$infoHeader = @'
Running install script

Build Image   : {0}
Build version : {1}
Initiator     : {2}
PSVersion     : {3}
PSEdition     : {4}
'@ -f $env:CODEBUILD_BUILD_IMAGE, $env:CODEBUILD_BUILD_NUMBER, $env:CODEBUILD_INITIATOR, $PSVersionTable.PSVersion, $PSVersionTable.PSEdition

Write-Output $infoHeader

#-----------------#
# Install NuGet   #
#-----------------#
# TLS v1.2 fix because 1.0 was deprecated
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Install-Module PowerShellGet, PackageManagement  -Force -SkipPublisherCheck -Scope CurrentUser -AllowClobber

Write-Output 'Installing NuGet PackageProvider'
$pkg = Install-PackageProvider -Name NuGet -Force
Write-Output "Installed NuGet version '$($pkg.version)'"

#-----------------#
# Install Modules #
#-----------------#
Install-Module -Name Pester -RequiredVersion 4.10.1 -Repository PSGallery -Force -SkipPublisherCheck -AllowClobber
Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.19.0 -Repository PSGallery -Force -SkipPublisherCheck -AllowClobber