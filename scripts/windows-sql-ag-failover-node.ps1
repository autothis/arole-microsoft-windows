    Param
    (
      [Parameter(Mandatory)]
      [Alias("Instance")] 
      [string[]]$Instance,

      [Parameter(Mandatory)]
      [Alias("FailoverNode")] 
      [string[]]$FailoverNode,

      [Parameter(Mandatory)]
      [Alias("AvailabilityGroup")] 
      [string[]]$AvailabilityGroup
    )
    
    # Import Required Powershell Modules
      Import-Module SqlServer

    # Initalise Variables
      $ErrorActionPreference = 'Stop'

    # Failover Availability Group
      $Path = "SQLSERVER:\Sql\$($FailoverNode)\Default\AvailabilityGroups\$($AvailabilityGroup)"
      Switch-SqlAvailabilityGroup -Path $Path