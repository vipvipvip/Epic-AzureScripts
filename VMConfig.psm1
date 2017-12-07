
<#
.SYNOPSIS
    Returns default provisioning config values that will be used by the auto-provisioning WebJobs
#>
function Get-SQLVMConfiguration
{
    $config = @{`
        VMName = 'MyVm-Sql'
        VMSize = 'Standard_D8s_v3'
        VMOperatingSystem = "Windows"
        ComputerName = 'MyVm-Sql'
        PublisherName = 'MicrosoftSQLServer'
        Offer = 'SQL2016-WS2016'
        Skus = 'SQLDEV'
        Version =  'latest'
        }
    return $config
}
