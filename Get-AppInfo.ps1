import-module ConfigurationManager

if (-not (Get-PSDrive -Name CAS -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name CAS -PSProvider CMSite -Root YourSiteServer.yourdomain.com
}

set-location CAS:

$AllAppsFull = Import-CSV C:\temp\AllAppsFull.csv
$AllDepsFull = Import-CSV C:\temp\AllDepsFull.csv

$AppMgmt = @()
$AppName = @()

# $AllAppsFull = Get-CMApplication | Select-Object -First 10

function GetInfoApplications {
   
    foreach ($Application in $AllAppsFull) {
 
        $AppMgmt = ([xml]$Application.SDMPackageXML).AppMgmtDigest
        $AppName = $AppMgmt.Application.DisplayInfo.FirstChild.Title

        foreach ($DeploymentType in $AppMgmt.DeploymentType) {

            # Calculate Size and convert to MB
            $size = 0
            foreach ($MyFile in $DeploymentType.Installer.Contents.Content.File) {
                $size += [float]($MyFile.GetAttribute("Size"))
            }
            $size = [math]::truncate($size/1MB)

            # Fill properties
            $AppData = [ordered]@{            
                AppName            = $AppName
                Location           = $DeploymentType.Installer.Contents.Content.Location
                DeploymentTypeName = $DeploymentType.Title.InnerText
                Technology         = $DeploymentType.Installer.Technology
                ContentId          = $DeploymentType.Installer.Contents.Content.ContentId
                SizeMB             = $size
                Expired            = $Application.IsExpired
                Deployed           = $Application.IsDeployed
                CreatedBy          = $Application.CreatedBy
                DateCreated        = $Application.DateCreated
                DateLastModified   = $Application.DateLastModified
                DependTaskSeq      = $Application.NumberofDependentTS
                DependDepTypes     = $Application.NumberofDependentDTs
            }                           

            # Create object
            $Object = New-Object PSObject -Property $AppData

            # Return it
            $Object
        }
    }
}

$ExpAppsNoDepend = GetInfoApplications | Where-Object {($_.Expired -eq 'True') -and ($_.Deployed -eq 'False') `
    -and ($_.DependTaskSeq -eq '0') -and ($_.DependDepTypes -eq '0')}

# $ExpAppsNoDepend | Export-Csv -Path C:\temp\ExpiredAppsNoDependency.csv -NoTypeInformation  

$choice = Read-Host "Do you want to export the results to a file? (Y/N)"
if ($choice -eq 'Y' -or $choice -eq 'y') {
    Write-Host "Exporting to C:\Temp\ExpiredAppsNoDependency.csv" -ForegroundColor Green
    $ExpAppsNoDepend | Export-Csv -Path C:\temp\ExpiredAppsNoDependency.csv -NoTypeInformation
} else {
    Write-Host "You can read the values with the variable ExpAppsNoDepend"
}


