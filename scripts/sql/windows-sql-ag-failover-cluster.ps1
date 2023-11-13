Param
(
  [Parameter(Mandatory)]
  [string[]]$FailoverNode
)

# Initalise Variables
  $CurrentHost = (hostname).tostring()

# Failover Availability Group
  $Failover = Suspend-ClusterNode -Name $CurrentHost -Target $FailoverNode -Drain
  $FailoverStatus = Get-ClusterGroup
  if ($FailoverStatus.OwnerNode.Name -eq $CurrentHost -and $FailoverStatus.Name -ne "Available Storage") {
      Write-Output $False
    } elseif ($FailoverStatus.OwnerNode.Name -ne $CurrentHost -and $FailoverStatus.Name -ne "Available Storage") {
      Write-Output $True
    }