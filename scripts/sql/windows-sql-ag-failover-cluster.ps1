    $CurrentHost = (hostname).tostring()
    $Failover = Get-ClusterNode -Name $CurrentHost | Get-ClusterGroup | Move-ClusterGroup
    if ($Failover.OwnerNode.Name -eq $CurrentHost -and $Failover.Name -ne "Available Storage") {
        Write-Output $False
      } elseif ($Failover.OwnerNode.Name -ne $CurrentHost -and $Failover.Name -ne "Available Storage") {
        Write-Output $True
      }