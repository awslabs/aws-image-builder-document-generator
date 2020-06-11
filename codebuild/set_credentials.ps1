
<#
.SYNOPSIS
    This script is used in AWS CodeBuild to configure the default AWS
    Credentials for use by the AWS CLI and the AWS Powershell module.

    By default, the AWS PowerShell Module does not know about looking up
    an AWS Container's credentials path, so this works around that issue.
#>

'Configurating AWS credentials'
'  - Retrieving temporary credentials from metadata'
$uri = 'http://169.254.170.2{0}' -f $env:AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
$sts = Invoke-RestMethod -UseBasicParsing -Uri $uri

'  - Setting default AWS Credential'
$credentialsFile = New-Item -Path "$env:HOME\.aws\credentials" -Force

@"
[default]
aws_access_key_id={0}
aws_secret_access_key={1}
aws_session_token={2}
region={3}
"@ -f $sts.AccessKeyId, $sts.SecretAccessKey, $sts.Token, $env:AWS_DEFAULT_REGION |
Out-File -FilePath $credentialsFile.FullName -Append