Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId,
    [Parameter(Mandatory=$True)]
    [String] $UserName,
    [Parameter(Mandatory=$True)]
    [string] $Password,
    [Parameter(Mandatory=$True)]
    [string] $ResourceGroupName
 
)


$LoadModule=Get-Module -ListAvailable "Azure*"
if(!$LoadModule){
Install-PackageProvider NuGet -Force
Install-Module -Name AzureRM.profile -AllowClobber -Force
Install-Module -Name AzureRM.resources -AllowClobber -Force
}
Import-Module AzureRM.profile
Import-Module AzureRM.Compute

$Securepass=ConvertTo-SecureString -String $Password -AsPlainText -Force
$Azurecred=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList($UserName, $Securepass)
$login=Login-AzureRmAccount -Credential $Azurecred -SubscriptionId $SubscriptionId

$ResourceGroup=Get-AzureRmResourceGroup -Name $ResourceGroupName
if($ResourceGroup){
Remove-AzureRmResourceGroup -Name $ResourceGroupName -Force
}
