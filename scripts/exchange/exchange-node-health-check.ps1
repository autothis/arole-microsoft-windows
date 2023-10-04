# Param

    Param
    (
      [Parameter(Mandatory)]
      [string]$Username,

      [Parameter(Mandatory)]
      [string]$Password
    )

# Initalise Variables

    $SystemHostname = (hostname).ToString()
    $ErrorActionPreference = 'Stop'
    $MailboxDatabaseCopyStatus = @()
    $NodeState = @()
    
# Create Credential Object

    [securestring]$secStringPassword = ConvertTo-SecureString $Password -AsPlainText -Force
    [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($Username, $secStringPassword)

# Import Required Powershell Modules and SnapIns

    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$($SystemHostname)/PowerShell/ -Authentication Kerberos -Credential $credObject
    $CreateSession = Import-PSSession $Session -DisableNameChecking
    #Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

# Gather Data

    #Get Node State - This command will not work, unless the command is executed on an Exchange Server (even with importing the CMDLETs from a PSSession)
    $CurrentNodeState = Get-ClusterNode -Name $SystemHostname
    $NodeState += New-Object -TypeName PSObject -Property @{
        Name = $CurrentNodeState.Name;
        Id = $CurrentNodeState.Id;
        State = $CurrentNodeState.State;
        }

    # Get Node Services Health
    $ServiceHealth = Test-ServiceHealth -Identity $SystemHostname
        # I need $servicehealth.ServicesNotRunning to be empty, will need to use an until loop here

    # Get Replication Health
    $ReplicationHealth = Test-ReplicationHealth -Identity $SystemHostname
        # I need:
        #   $replicationhealth.Result to be Passed
        #   $replicationhealth.Error to be empty
    
    # Get Server Component Health
    $ServerComponentState = Get-ServerComponentState -Identity $SystemHostname
        # I Need $servercomponentstate.state to be Active, except for:
        #   ForwardSyncDaemon
        #   ProvisioningRps
    
    # Get Mailbox Database Health
    $MailboxDatabases = Get-MailboxDatabase -Server $SystemHostname
    ForEach ($MailboxDatabase in $MailboxDatabases) {
        ForEach ($MailboxDatabaseServer in $MailboxDatabase.Servers.Name) {
            $DatabaseCopyStatus = Get-MailboxDatabaseCopyStatus -Identity "$($MailboxDatabase.Name)\$($MailboxDatabaseServer)"
            $MailboxDatabaseCopyStatus += New-Object -TypeName PSObject -Property @{
                Name = $MailboxDatabase.Name;
                Server = $MailboxDatabaseServer;
                Status = $DatabaseCopyStatus.Status;
                ContentIndexState = $DatabaseCopyStatus.ContentIndexState;
                CopyQueueLength = $DatabaseCopyStatus.CopyQueueLength;
                ReplayqueueLength = $DatabaseCopyStatus.ReplayqueueLength;
                }
            }
        }
    $MailboxDatabaseCopyStatus | Select Name,Server,Status,ContentIndexState,CopyQueueLength,ReplayqueueLength | Sort-Object Name
        # I need:
        #   $mailboxcopystatus.status to be Mounted or Healthy
        #   $mailboxcopystatus.contentIndexState to be Healthy
        #   $mailboxcopystatus.CopyQueueLength to be less than 10
        #   $mailboxcopystatus.ReplayqueueLength to be less than 10

# Format Results in JSON
    
    $ExchangeNodeHealth = [PSCustomObject]@{
      node_state = $NodeState
      service_health = $ServiceHealth
      replication_health = $ReplicationHealth
      server_component_state = $ServerComponentState
      mailbox_database_copy_status = $MailboxDatabaseCopyStatus | Select Name,Server,Status,ContentIndexState,CopyQueueLength,ReplayqueueLength
      }
    
    Get-MailboxDatabase -Server $SystemHostname
    $MailboxDatabaseCopyStatus
    $ExchangeNodeHealth | ConvertTo-JSON

# Cleanup Session

    Remove-PSSession $Session
