    Param
    (
      [Parameter(Mandatory)]
      [string[]]$Instance,

      [Parameter(Mandatory)]
      [string[]]$FailoverNode,

      [Parameter(Mandatory)]
      [string[]]$AvailabilityGroup,

      [Parameter(Mandatory)]
      [string[]]$Action
    )
    
    # Import Required Powershell Modules
      Import-Module SqlServer

    # Initalise Variables
      $ErrorActionPreference = 'Stop'
      $Path = "SQLSERVER:\Sql\$($FailoverNode)\$($Instance)\AvailabilityGroups\$($AvailabilityGroup)\AvailabilityDatabases"

    # Suspend or Resume Availability Group Database
      If ($Action -eq "suspend") {
          Get-ChildItem $Path | Suspend-SqlAvailabilityDatabase -Confirm:$false
        } elseif ($Action -eq "resume") {
          Get-ChildItem $Path | Resume-SqlAvailabilityDatabase -Confirm:$false
        }