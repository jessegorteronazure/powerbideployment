#this model looks for the xmla model  file, and deploys it using a service principal
function DeployModel {
    param(
        [string]$powerbiclientid,
        [string]$powerbiclientsecret,
        [string]$asDatabaseName,
        [string]$modelLocation,
        [string]$databaseServer = "",
        [string]$databaseName = "",
        [string]$databaseServerDev = "",
        [string]$workspaceName = "",
        [string]$tenant = ""
    )

    $ErrorActionPreference = "Stop"
    Write-Host "### Installing sqlserver module..." -ForegroundColor Green

    Install-Module -Name "SqlServer" -AllowClobber -Scope CurrentUser -Force -AllowPrerelease
    if (!$?) {
        Write-Error "Error installing SqlServer module"
        exit
    }

    $scriptFolder = $modelLocation
    $modelPath = [System.IO.Path]::Combine($modelLocation, "$asDatabaseName.xmla")
    $modelJson = Get-Content -Path $modelPath
    $modelJson = $modelJson -replace $databaseServerDev, $databaseServer
    Set-Content -Path $modelPath -Value $modelJson
    $asServerName = "powerbi://api.powerbi.com/v1.0/myorg/$workspaceName"

    $password = ConvertTo-SecureString -String $powerbiclientsecret -AsPlainText -Force
    $user = "$powerbiclientid@$tenant"
    $credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $user, $password

    $files = Get-ChildItem -Path $scriptFolder -File -Filter "*.xmla" | Sort-Object -Property Name
    foreach ($file in $files) {
        Write-Host "##[command] Execute the script $($file.Name) on $($asServerName)"
        $result = Invoke-ASCmd -Server $asServerName -Credential $credential -InputFile $file.FullName -ServicePrincipal -TenantId $tenant
        Write-Host $result
        if ($result.ToLower().Contains('error')) {
            Throw "XMLA script execution failed with error code $($result.ErrorCode). Error message: $($result.Error)"
        }
    }
}

# Call the DeployModel function with appropriate parameters
DeployModel -powerbiclientid "yourClientId" -powerbiclientsecret "yourClientSecret" -asDatabaseName "YourDatabaseName" -modelLocation "Path\To\Your\ModelFiles" -databaseServer "YourDatabaseServer" -databaseServerDev "YourDatabaseServerDev" -workspaceName "YourWorkspaceName" -tenant "YourTenant"

