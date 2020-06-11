#---------------------------------#
# Install TOE                     #
#---------------------------------#
# Create TOE folder
$path = Join-Path -Path $env:SystemDrive -ChildPath 'toe'
$toe = Join-Path $path 'awstoe.exe'
$null = New-Item -Path $path -ItemType 'Directory' -Force

# Download TOE
$uri = 'https://ec2imagebuilder-toe-us-east-1-prod.s3.amazonaws.com/bootstrap_scripts/bootstrap.ps1'
$bootstrap = [scriptblock]::Create(([System.Net.WebClient]::new().DownloadString($uri) -replace ' --quiet'))

#execute
Invoke-Command -ScriptBlock $bootstrap -ArgumentList $path

& $toe '-v'