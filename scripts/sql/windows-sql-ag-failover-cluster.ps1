Param
(
  [Parameter(Mandatory)]
  [string[]]$FailoverNode,

  [Parameter(Mandatory)]
  [string[]]$Action
)

# Initalise Variables
  $CurrentHost = (hostname).tostring()

# Pause or Resume Failover Cluster Node
  If ($Action -eq "pause") {
      # Pause Failover Cluster Node
      Suspend-ClusterNode -Name $CurrentHost -Target $FailoverNode -Drain

      # Failover Status
      $FailoverStatus = Get-ClusterGroup
      if ($FailoverStatus.OwnerNode.Name -eq $CurrentHost -and $FailoverStatus.Name -ne "Available Storage") {
          Write-Output $False
        } elseif ($FailoverStatus.OwnerNode.Name -ne $CurrentHost -and $FailoverStatus.Name -ne "Available Storage") {
          Write-Output $True
        }
    } elseif ($Action -eq "resume") {
      # Resume Failover Cluster Node
      $ResumeNode = Resume-ClusterNode $CurrentHost -Failback NoFailback

      # Resume Node Status
      if ($ResumeNode.State -eq "Up") {
          Write-Output $True
        } else {
          Write-Output $False
        }
    }