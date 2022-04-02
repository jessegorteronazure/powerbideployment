#this model looks for the reports.json file and attempts to deploy the reports listed to the specified workspace. you can add a workspace prefix for development, test or acceptance workspaces.
#it will remove the existing report, republish it and attempts to bind it to the dataset in that worspace, specified in the json. this only works for reports with a live connection to power bi 
function DeployReports
{
    param(
      [string]$scriptLocation = "",
      [string]$apiId = "",
      [string]$apiKey = "",
      [string]$workspacePrefix = "",
      [string]$tenant = ""
    )

    $clientsecret = $apiKey | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $apiId, $clientsecret
    Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credential -TenantId $tenant

    $scriptPath = [System.IO.Path]::Combine($scriptLocation,  "Reports.json")
    [string]$reportsJson = Get-content -Path $scriptPath
    $Reports = ConvertFrom-Json -InputObject $reportsJson


    foreach($report in $Reports.Reports)
    {
       $workspaceName = $workspacePrefix + $report.Workspace
       $workspaceObject = ( Get-PowerBIWorkspace -Name $workspaceName )
       $pbixPath = [System.IO.Path]::Combine($scriptLocation, $report.FileName)

       $ReportsResponse = Invoke-PowerBIRestMethod -Url "groups/$($workspaceObject.id)/reports" -Method Get | ConvertFrom-Json
       $reportsList = $ReportsResponse.value
       foreach($pbireport in $reportsList)
       {
            if($pbireport.name -eq $report.Name){
                $reportid = $pbireport.id
                Remove-PowerBIReport -Id $reportid -WorkspaceId $workspaceObject.id
                break;
            }
       }

       $result = New-PowerBIReport -Path $pbixPath -Name $report.Name  -Workspace $workspaceObject -ConflictAction CreateOrOverwrite

        $DatasetResponse=Invoke-PowerBIRestMethod -Url "groups/$($workspaceObject.id)/datasets" -Method Get | ConvertFrom-Json
        $datasets = $DatasetResponse.value
        foreach($dataset in $datasets){
                    if($dataset.name -eq $report.Dataset){
                    $datasetid= $dataset.id;
                    break;
                    }

                }
        $body = '{
        "datasetId" : "' + $datasetid + '"
        }
        '
        Invoke-PowerBIRestMethod -Url "groups/$($workspaceObject.id)/reports/$($result.Id)/Rebind/" -Method Post -Body $body  


}

}

