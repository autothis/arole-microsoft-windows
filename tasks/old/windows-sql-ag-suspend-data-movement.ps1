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
      $Path = "SQLSERVER:\Sql\$($FailoverNode)\$($Instance)\AvailabilityGroups\$($AvailabilityGroup)\AvailabilityDatabases"
      Get-ChildItem $Path | Suspend-SqlAvailabilityDatabase -Confirm:$false