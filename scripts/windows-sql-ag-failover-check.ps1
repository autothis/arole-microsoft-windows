    # Import Required Powershell Modules
      Import-Module SqlServer

    # Initalise Variables
      $SystemHostname = hostname
      $ErrorActionPreference = 'Stop'
      $AvailabilityGroupDatabases = @()
      $AvailabilityGroupReplicas = @()
      $CurrentReplicaStatus = @()
      $AvailabilityGroups = @()
      $Instances = @()

    # Gather Data
      ForEach ($Instance in (Get-ChildItem "SQLSERVER:\SQL\$($SystemHostName)")) {
        $Instances += New-Object -TypeName PSObject -Property @{
          InstanceName = $Instance.DisplayName;
          Version = $Instance.Version;
          ProductLevel = $Instance.ProductLevel;
          UpdateLevel = $Instance.UpdateLevel;
          HostPlatform = $Instance.HostPlatform;
          }
        
        ForEach ($AvailabilityGroup in (Get-ChildItem "SQLSERVER:\SQL\$($SystemHostName)\$($Instance.DisplayName)\AvailabilityGroups")) {
          $AvailabilityGroups += New-Object -TypeName PSObject -Property @{
            Name = $AvailabilityGroup.Name;
            PrimaryReplicaServerName = $AvailabilityGroup.PrimaryReplicaServerName;
            InstanceName = $Instance.DisplayName;
            }

          ForEach ($AvailabilityGroupDatabase in (Get-ChildItem "SQLSERVER:\SQL\$($SystemHostName)\$($Instance.DisplayName)\AvailabilityGroups\$($AvailabilityGroup.name)\AvailabilityDatabases")) {
            $AvailabilityGroupDatabases += New-Object -TypeName PSObject -Property @{
              Name = $AvailabilityGroupDatabase.Name;
              SynchronizationState = $AvailabilityGroupDatabase.SynchronizationState;
              IsSuspended = $AvailabilityGroupDatabase.IsSuspended;
              IsJoined = $AvailabilityGroupDatabase.IsJoined;
              AvailabilityGroup = $AvailabilityGroup.Name;
              InstanceName = $Instance.DisplayName;
              }
            ForEach ($AvailabilityGroupReplica in (Get-ChildItem "SQLSERVER:\SQL\$($SystemHostName)\$($Instance.DisplayName)\AvailabilityGroups\$($AvailabilityGroup.name)\AvailabilityReplicas")) {
              $AvailabilityGroupReplicas += New-Object -TypeName PSObject -Property @{
                Name = $AvailabilityGroupReplica.Name;
                Role = $AvailabilityGroupReplica.Role;
                ConnectionState = $AvailabilityGroupReplica.ConnectionState;
                RollupSynchronizationState = $AvailabilityGroupReplica.RollupSynchronizationState;
                AvailabilityGroup = $AvailabilityGroup.Name;
                InstanceName = $Instance.DisplayName;
                }
              }
            }
          }
        }

      $CurrentHost = $AvailabilityGroupReplicas | where-object {$_.name -eq $systemhostname}
      $FailoverNode = ($AvailabilityGroupReplicas | where-object {$_.Role -ne "Primary" -and $_.Name -ne $systemhostname})[0]
      If ($FailoverNode -eq $null) {
          $FailoverNode_FQDN = "Unable to identify"
        } else {
          $FailoverNode_FQDN = (Resolve-DNSName $($FailoverNode.Name)).Name | Sort-Object -Unique
        }
      $CurrentReplicaStatus = New-Object -TypeName PSObject -Property @{
        Name = $CurrentHost.Name;
        Role = ($CurrentHost.Role | Out-String).trim();
        ConnectionState = ($CurrentHost.ConnectionState | Out-String).trim();
        RollupSynchronizationState = ($CurrentHost.RollupSynchronizationState | Out-String).trim();
        }

    # Determine if Current Replica Role is Primary
      $HostPrimary = $CurrentHost.Role -eq "Primary"

    # Format Results in JSON
          
      $FailoverResults = [PSCustomObject]@{
        failover_required = $HostPrimary
        failover_to_node = $($FailoverNode.Name)
        failover_to_node_fqdn = $FailoverNode_FQDN
        current_replica_status = $CurrentReplicaStatus
        sql_availability_group_replicas = $AvailabilityGroupReplicas
        sql_availability_group_databases = $AvailabilityGroupDatabases
        sql_availability_groups = $AvailabilityGroups
        sql_instances = $Instances
        }

      $FailoverResults | convertto-json