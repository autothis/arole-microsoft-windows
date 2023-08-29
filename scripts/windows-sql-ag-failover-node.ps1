    # Import Required Powershell Modules
      Import-Module SqlServer

    # Initalise Variables
      $ErrorActionPreference = 'Stop'
      $Instance = "{{ item['InstanceName'] }}"
      $FailoverNode = "{{ sql_current_replica['failover_to_node'] }}"
      $AvailabilityGroup = "{{ item['Name'] }}"

    # Failover Availability Group
      $Path = "SQLSERVER:\Sql\$($FailoverNode)\Default\AvailabilityGroups\$($AvailabilityGroup)"
      Switch-SqlAvailabilityGroup -Path $Path