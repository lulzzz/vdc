[CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $NetworkWatcherRegion,
        [Parameter(Mandatory=$true)]
        [string]
        $NetworkSecurityGroupId,
        [Parameter(Mandatory=$true)]
        [string]
        $DiagnosticStorageAccountId,
        [Parameter(Mandatory=$true)]
        [string]
        $WorkspaceId,
        [Parameter(Mandatory=$true)]
        [string]
        $LogAnalyticsWorkspaceId,
        [Parameter(Mandatory=$true)]
        [string]
        $WorkspaceRegion
    )

$NW = Get-AzNetworkWatcher -ResourceGroupName NetworkWatcherRg -Name "NetworkWatcher_$NetworkWatcherRegion"

#Configure Version 2 FLow Logs with Traffic Analytics Configured
Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $NW -TargetResourceId $NetworkSecurityGroupId -StorageAccountId $DiagnosticStorageAccountId -EnableFlowLog $true -FormatType Json -FormatVersion 2 -EnableTrafficAnalytics -WorkspaceResourceId $LogAnalyticsWorkspaceId -WorkspaceGUID $WorkspaceId -WorkspaceLocation $WorkspaceRegion