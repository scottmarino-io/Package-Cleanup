import-module ConfigurationManager

#New-PSDrive -name S01 -PSProvider CMSite -Root SERVER2
if (-not (Get-PSDrive -Name S01 -PSProvider CMSite -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name S01 -PSProvider CMSite -Root SERVER2
}

set-location S01:

# Get the application
$apps = Get-CMApplication #-Name "7-Zip 23.01 (x64 edition)"
foreach ($app in $apps) {


# Access the SDMPackageXML property and cast it to an XML object
$xml = [xml]$app.SDMPackageXML

# Now you can navigate the XML. For example, to get the deployment types:
$deploymentTypes = $xml.AppMgmtDigest.DeploymentType

# For each deployment type, print its details
foreach ($dt in $deploymentTypes) {
    $dtId = $dt.LogicalName
    $installerType = $dt.Installer.Technology
    $contentLocation = $dt.Installer.Contents.Content.Location

$dtId
$installerType
$contentLocation

# $path = $xml.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location
# $xml.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location


}}

function GetInfoAppDeployments {

    foreach ($Deployment in Get-CMApplicationDeployment) {        
        $DeployMgmt = ([xml]$Deployment.SDMPackageXML).AppMgmtDigest
        $DeployName = $DeployMgmt.DeploymentType.DeploymentTypeName
    }

        foreach ($DeploymentType in $DeployMgmt.DeploymentType) {
            $DeployType = $DeploymentType.DeploymentTypeName
            $DeployContent = $DeploymentType.Installer.Contents.Content.Location
            $DeployInstaller = $DeploymentType.Installer.Technology
            $DeployContent
            $DeployInstaller
        }
}
