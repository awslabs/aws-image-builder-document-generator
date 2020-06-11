[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Install-Module PowerShellGet, PackageManagement  -Force -SkipPublisherCheck -Scope CurrentUser -AllowClobber
$pkg = Install-PackageProvider -Name NuGet -Force
Write-Output "Installed NuGet version '$($pkg.version)'"