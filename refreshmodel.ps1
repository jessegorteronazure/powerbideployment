#this script refreshes the dataset via the xmla endpoint.
function RefreshModel
{
param(
  [string]$asDatabaseName = "",
  [string]$apiId = "",
  [string]$apiKey = "",
  [string]$workspaceName = "",
  [string]$tenant = ""
)

$asServerName = ('powerbi://api.powerbi.com/v1.0/myorg/' + $workspaceName)
$password = ConvertTo-SecureString -String $apiKey -AsPlainText -Force
$user = $apiId + "@" + $tenant

$credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $user, $password
[string]$refreshScript = @"
{
  "refresh": {
    "type": "full",
    "objects": [
      {
        "database": "$($asDatabaseName)"
      }
    ]
  }
}
"@

$result = Invoke-ASCmd -Server $asServerName -Credential $credential -Query $refreshScript -ServicePrincipal -TenantId $tenant
}
