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


}}


# $xml.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location