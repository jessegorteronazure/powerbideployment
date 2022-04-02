#this function sets a sql user login as a credential via the service principal. this will only work for basic authentication. the sleep is needed to make sure the principal has taken over the dataset
function SetCredentials
{
    param(
      [string]$workspaceName = "",
      [string]$datasetName = "",
      [string]$apiId = "",
      [string]$apiKey = "",
      [string]$databaseUser = "",
      [string]$databasePassword = "",
      [string]$tenant = ""
    )

  
    $clientsecret = $apiKey | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $apiId, $clientsecret
    $t = Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenant
    
    $workspace =Get-PowerBIWorkspace -Name $workspaceName
    
    $DatasetResponse=Invoke-PowerBIRestMethod -Url "groups/$($workspace.id)/datasets" -Method Get | ConvertFrom-Json
    $datasets = $DatasetResponse.value

         foreach($dataset in $datasets){
                
                    if($dataset.name -eq $datasetName){
                    $datasetid= $dataset.id;
                    break;
                    }

                }


    $gatewayInfoString = Invoke-PowerBIRestMethod -Url "groups/$($workspace.id)/datasets/$($datasetid)/datasources" -Method Get


    $gatewayinfo = ConvertFrom-Json -InputObject $gatewayInfoString


[string]$body = @"
{
	"credentialDetails": {
    "credentialType": "Basic",
    "credentials": "{\"credentialData\":[{\"name\":\"username\", \"value\":\"$($databaseUser)\"},{\"name\":\"password\", \"value\":\"$($databasePassword)\"}]}",
    "encryptedConnection": "Encrypted",
    "encryptionAlgorithm": "None",
    "privacyLevel": "None",
    "useEndUserOAuth2Credentials": "False"
    }
}
"@

    Invoke-PowerBIRestMethod -Url "groups/$($workspace.id)/datasets/$($datasetid)/Default.TakeOver" -Method Post

    Start-Sleep -s 5

    Invoke-PowerBIRestMethod -Url "gateways/$($gatewayinfo.value.gatewayId)/datasources/$($gatewayinfo.value.datasourceId)" -Method Patch -Body $body
   

}

