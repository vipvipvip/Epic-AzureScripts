# Get and/or set PowerShell session to only run scripts targeting dbpertenant Epic deployment 
$Global:ErrorActionPreference = "Stop"
$scriptsTarget = 'dbpertenant'
if ($Global:EpicScriptsTarget -and ($Global:EpicScriptsTarget -ne $scriptsTarget))
{
    throw "This PowerShell session is setup to only run scripts targeting Epic '$Global:EpicScriptsTarget' architecture. Open up a new PowerShell session to run scripts targeting Epic '$scriptsTarget' architecture."  
}
elseif (!$Global:EpicScriptsTarget)
{
    Write-Verbose "Configuring PowerShell session to only run scripts targeting Epic '$scriptsTarget' architecture ..."
    Set-Variable EpicScriptsTarget -option Constant -value $scriptsTarget -scope global
}


<#
.SYNOPSIS
    Returns default configuration values that will be used by the Epic Tickets Platform application
#>
function Get-Configuration
{
    $configuration = @{`
            ResourceGroupName = "Si3RG1"
            Location = "eastus"
        }
    return $configuration
}
