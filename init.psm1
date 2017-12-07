# Login-AzureRmAccount
Import-Module "$PSScriptRoot\SubscriptionManagement" -Force
Import-Module "$PSScriptRoot\EpicConfig" -Force
Import-Module "$PSScriptRoot\UserConfig" -Force
Import-Module "$PSScriptRoot\VMConfig" -Force
Import-Module "$PSScriptRoot\Helpers-Network" -Force

function Do_Init() {
    # Get Azure credentials if not already logged on,  Use -Force to select a different subscription 
    Initialize-Subscription -Verbose

    # Get the resource group and user names used when the application was deployed  
    #$Si3User = Get-UserConfig

    # Get the Si3 app configuration
    Get-Configuration

    Get-SQLVMConfiguration

}
