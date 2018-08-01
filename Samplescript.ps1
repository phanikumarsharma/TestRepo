Param(

    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string] $SubscriptionId,
    
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroupName,

    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string] $Location,

    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [string] $AppServicePlan = "msft-rdmi-saas-$((get-date).ToString("ddMMyyyyhhmm"))",

    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [string] $WebApp = "RDmiMgmtWeb-$((get-date).ToString("ddMMyyyyhhmm"))",

    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [string] $ApiApp = "RDmiMgmtApi-$((get-date).ToString("ddMMyyyyhhmm"))",

    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string] $UserName,

    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [string] $Password
)


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#Install AzureRM Module   
        
    Write-Output "Checking if AzureRm module is installed.."
    $azureRmModule = Get-Module AzureRM -ListAvailable | Select-Object -Property Name -ErrorAction SilentlyContinue
    if (!$azureRmModule.Name) {
        Write-Output "AzureRM module Not Available. Installing AzureRM Module"
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module Azure -Force
        Install-Module AzureRm -Force
        Write-Output "Installed AzureRM Module successfully"
    } 
    else
    {
        Write-Output "AzureRM Module Available"
    }

    #Import AzureRM Module

    Write-Output "Importing AzureRm Module.."
    Import-Module AzureRm -ErrorAction SilentlyContinue -Force

    #Login to AzureRM Account

    Write-Output "Login Into Azure RM.."
    
    $Psswd = $Password | ConvertTo-SecureString -asPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential($UserName,$Psswd)
    Login-AzureRmAccount -Credential $Credential

    #Select the AzureRM Subscription

    Write-Output "Selecting Azure Subscription.."
    Select-AzureRmSubscription -SubscriptionId $SubscriptionId

 ##################################### RESOURCE GROUP #####################################

    # Create a resource group.

    Write-Output "Checking if the resource group $ResourceGroupName exists";
    $ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (! $ResourceGroup)
    {
        Write-Output "Creating the resource group $ResourceGroupName ...";
        New-AzureRmResourceGroup -Name $ResourceGroupName -Location "$Location" -ErrorAction Stop 
        Write-Output "Resource group with name $ResourceGroupName has been created"
    }
    elseif($ResourceGroup)
    {
        try
        {
            ##################################### APPSERVICE PLAN #####################################
               
            #create a appservice plan
        
            Write-Output "Creating AppServicePlan in resource group  $ResourceGroupName ...";
            New-AzureRmAppServicePlan -Name $AppServicePlan -Location $Location -ResourceGroupName $ResourceGroupName -Tier Standard
            $AppPlan = Get-AzureRmAppServicePlan -Name $AppServicePlan -ResourceGroupName $ResourceGroupName
            Write-Output "AppServicePlan with name $AppServicePlan has been created"

        }
        catch [Exception]
        {
            Write-Output $_.Exception.Message
        }

        if($AppServicePlan)
        {
            try
            {

                ##################################### CREATING WEB-APP #####################################

                #create a web app
            
                Write-Output "Creating a WebApp in resource group  $ResourceGroupName ...";
                New-AzureRmWebApp -Name $WebApp -Location $Location -AppServicePlan $AppServicePlan -ResourceGroupName $ResourceGroupName
                Write-Output "WebApp with name $WebApp has been created"
            }
            catch [Exception]
            {
                Write-Output $_.Exception.Message
            }
        }
    }

    $t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
    add-type -name win -member $t -namespace native
    [native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)


    $null = Set-AzureRmContext -SubscriptionId $SubscriptionId

    @(
      'Microsoft.Compute/virtualMachineScaleSets'
      'Microsoft.Compute/virtualMachines'
      'Microsoft.Storage/storageAccounts'
      'Microsoft.Compute/availabilitySets'
      'Microsoft.ServiceBus/namespaces'
      'Microsoft.Network/connections'
      'Microsoft.Network/virtualNetworkGateways'
      'Microsoft.Network/loadBalancers'
      'Microsoft.Network/networkInterfaces'
      'Microsoft.Network/publicIPAddresses'
      'Microsoft.Network/networkSecurityGroups'
      'Microsoft.Network/virtualNetworks'

      '*' # this will remove everything else in the resource group regarding of resource type
    ) | % {
      $odataQuery = "`$filter=resourcegroup eq '$ResourceGroupName'"

      if ($_ -ne '*') {
        $odataQuery += " and resourcetype eq '$_'"
      }

      $resources = Get-AzureRmResource -ODataQuery $odataQuery
      $resources | Where-Object { $_.ResourceGroupName -eq $ResourceGroupName } | % { 
        Write-Host ('Processing {0}/{1}' -f $_.ResourceType, $_.ResourceName)
        $_ | Remove-AzureRmResource -Verbose -Force
      }
    }