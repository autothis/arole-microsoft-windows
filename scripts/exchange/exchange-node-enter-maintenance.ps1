# Param

    Param
    (
      [Parameter(Mandatory)]
      [string]$Username,

      [Parameter(Mandatory)]
      [string]$Password,

      [Parameter(Mandatory)]
      [string]$FailoverTarget
    )

# Initalise Variables

    $SystemHostname = (hostname).ToString()
    $ErrorActionPreference = 'Stop'
    $MailboxDatabaseCopyStatus = @()
    $ServiceHealth = @()
    
# Create Credential Object

    [securestring]$secStringPassword = ConvertTo-SecureString $Password -AsPlainText -Force
    [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($Username, $secStringPassword)

# Import Required Powershell Modules and SnapIns

    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$($SystemHostname)/PowerShell/ -Authentication Kerberos -Credential $credObject
    $CreateSession = Import-PSSession $Session -DisableNameChecking
    #Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

# Put Into Maintenance Mode

    # This is the current Exchange Server that is to be put into maintenance mode
    $CurrentExchangeServer = $SystemHostname
	
	# This is the node that will take over for $CurrentExchangeServer while it is in maintenance mode - a FQDN is expected
	$ExchangeFailoverTarget = $FailoverTarget
	
    # Suspend Exchange Components
    Set-ServerComponentState $CurrentExchangeServer –Component HubTransport –State Draining –Requester Maintenance
	
    # Redirect any messages to be sent to $CurrentExchangeServer to $ExchangeFailoverTarget
    Redirect-Message -Server $CurrentExchangeServer -Target $ExchangeFailoverTarget -confirm:$false
	
    # Suspend Windows Failover Cluster Node
	Suspend-ClusterNode -Name $CurrentExchangeServer
	
    # Disable Database Activation on $CurrentExchangeServer and move any active workloads
	Set-MailboxServer $CurrentExchangeServer –DatabaseCopyActivationDisabledAndMoveNow $true
	Set-MailboxServer $CurrentExchangeServer –DatabaseCopyAutoActivationPolicy Blocked
	Move-ActiveMailboxDatabase -Server $CurrentExchangeServer
	
    # Wait for all databases on $CurrentExchangeServer to be 'Mounted' elsewhere
	Do
	{
	  $activecopies = Get-MailboxDatabaseCopyStatus -Server $CurrentExchangeServer | Where {$_.Status -eq "Mounted"}
	} While ($activecopies.count –ne 0)
	
    # Wait for all databases now 'Mounted' elsewhere to be in a 'Healthy' State
	Do
	{
	  $healthycopies = Get-MailboxDatabaseCopyStatus -Server $CurrentExchangeServer | Where {$_.Status -ne "Healthy"}
	} While ($healthycopies.count –ne 0)
	
    # Set all components of $CurrentExchangeServer to be 'InActive' for Maintenance
    Set-ServerComponentState $CurrentExchangeServer –Component ServerWideOffline –State InActive –Requester Maintenance

# Cleanup Session

    Remove-PSSession $Session
