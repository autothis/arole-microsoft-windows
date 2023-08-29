    Param
    (
      [Parameter(Mandatory)]
      [string[]]$Instance,

      [Parameter(Mandatory)]
      [string[]]$FailoverNode,

      [Parameter(Mandatory)]
      [string[]]$AvailabilityGroup
    )
    
    # Import Required Powershell Modules
      Import-Module SqlServer

    # Initalise Variables
      $ErrorActionPreference = 'Stop'

    # Failover Availability Group
      $Path = "SQLSERVER:\Sql\$($FailoverNode)\Default\AvailabilityGroups\$($AvailabilityGroup)"
      Switch-SqlAvailabilityGroup -Path $Path