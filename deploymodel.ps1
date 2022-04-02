#this model looks for the xmla model  file, and deploys it using a service principal (apiId and apiKey)
function DeployModel
{
    param(
      [string]$asDatabaseName,
      [string]$modelLocation ,
      [string]$databaseServer = "",
      [string]$databaseName = "",
      [string]$apiId = "",
      [string]$apiKey = "",
      [string]$workspaceName = "",
      [string]$tenant = ""
    )
    [string]$scriptFolder = $modelLocation

    $modelPath = [System.IO.Path]::Combine($modelLocation, $AsDatabaseName + ".xmla")
    
    [string]$modelJson = Get-content -Path $modelPath

    Set-Content -Path $modelPath -Value $modelJson
	
    $asServerName = ('powerbi://api.powerbi.com/v1.0/myorg/' + $workspaceName)

    $password = ConvertTo-SecureString -String $apiKey -AsPlainText -Force

    $user = $apiId + "@" + $tenant
 
    $credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $user, $password

    $files = Get-ChildItem -Path $scriptFolder -File -Filter "*.xmla" | Sort-Object -Property Name 

    foreach ($file in $files)
    {
        Write-Host  "##[command] Execute the script $($file.name) on $($asServerName)"  
        $result = Invoke-ASCmd -Server $asServerName -Credential $credential -InputFile $file.FullName -ServicePrincipal -TenantId $tenant
    }
    
}
