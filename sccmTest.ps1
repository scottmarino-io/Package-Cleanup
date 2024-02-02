import-module ConfigurationManager

#New-PSDrive -name S01 -PSProvider CMSite -Root SERVER2   

set-location S01:

$sqlsrv = 'SERVER2'
$sqldb = 'CM_S01'
$results = @()
$result = @()
$items = @()
$AllApps = @()

$apps = Get-CMApplicationDeployment

ForEach ($app in $apps) {

$appname = $app.ApplicationName
$colname = $app.CollectionName


$query = "SELECT distinct
vrs.Name0 [Computer Name], vgos.Caption0 [OS],vrs.User_Name0 [User Name], arp6.InstallDate00 [Install Date], dbo.vAppDeploymentResultsPerClient.Descript [Software],
IIf([EnforcementState]=1001,'Installation Success',
IIf([EnforcementState]>=1000 And [EnforcementState]<2000 And [EnforcementState]<>1001,'Installation Success',
IIf([EnforcementState]>=2000 And [EnforcementState]<3000,'In Progress', IIf([EnforcementState]>=3000 And [EnforcementState]<4000,'Requirements Not Met ', IIf([EnforcementState]>=4000 And [EnforcementState]<5000,'Unknown', IIf([EnforcementState]>=5000 And [EnforcementState]<6000,'Error','Unknown')))))) AS Status
FROM dbo.v_R_System AS vrs
INNER JOIN (dbo.vAppDeploymentResultsPerClient
INNER JOIN v_CIAssignment
ON dbo.vAppDeploymentResultsPerClient.AssignmentID = v_CIAssignment.AssignmentID)
ON vrs.ResourceID = dbo.vAppDeploymentResultsPerClient.ResourceID
INNER JOIN dbo.fn_ListApplicationCIs(1033) lac
ON lac.ci_id=dbo.vAppDeploymentResultsPerClient.CI_ID
INNER JOIN dbo.v_GS_WORKSTATION_STATUS AS vgws
ON vgws.ResourceID=vrs.resourceid
INNER JOIN v_FullCollectionMembership coll
ON coll.ResourceID = vrs.ResourceID
INNER JOIN dbo.Add_Remove_Programs_64_DATA as arp6
ON vAppDeploymentResultsPerClient.Descript = arp6.DisplayName00
INNER JOIN dbo.v_GS_OPERATING_SYSTEM AS vgos
ON vgos.ResourceID = vrs.ResourceID
WHERE lac.DisplayName= `'$appname`' and CollectionName = `'$colname`'"

#AND arp6.InstallDate00 < '20240201'"


$results = Invoke-Sqlcmd -TrustServerCertificate -ServerInstance $sqlsrv -Database $sqldb -Query $query

#$results | Format-Table -AutoSize


$result += $results


$items += $results | Where-Object { $_.'Install Date' -lt 20240201 }
$items | Format-Table -AutoSize

function GetInfoApplications {
   
    foreach ($Application in Get-CMApplication) {
 
        $AppMgmt = ([xml]$Application.SDMPackageXML).AppMgmtDigest
        $AppName = $AppMgmt.Application.DisplayInfo.FirstChild.Title

        foreach ($DeploymentType in $AppMgmt.DeploymentType) {

            # Calculate Size and convert to MB
             $size = 0
            foreach ($MyFile in $DeploymentType.Installer.Contents.Content.File) {
                $size += [int]($MyFile.GetAttribute("Size"))
            }
            $size = [math]::truncate($size/1MB)
 
            # Fill properties
            $AppData = @{            
                AppName            = $AppName
                Location           = $DeploymentType.Installer.Contents.Content.Location
                DeploymentTypeName = $DeploymentType.Title.InnerText
                Technology         = $DeploymentType.Installer.Technology
                 ContentId          = $DeploymentType.Installer.Contents.Content.ContentId
          
                SizeMB             = $size
             }                           

            # Create object
            $Object = New-Object PSObject -Property $AppData
    
            # Return it
            $Object
        }
    }
 }

 
Write-host "Applications" -ForegroundColor Yellow
$AppPath = GetInfoApplications | select-object AppName, Location, Technology | Where-Object -Property AppName -like $items.Software # | Format-Table -AutoSize 
$AllApps += $AppPath
}
$AllApps #| Format-Table -AutoSize

Remove-CMApplicationDeployment -ApplicationName $AllApps.AppName -Force
Remove-CMApplication -Name $AllApps.AppName -Force
Remove-Item -Recurse -Path $AllApps.Location -Force

