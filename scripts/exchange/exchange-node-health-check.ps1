# Import Required Powershell Modules and SnapIns

    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

# Initalise Variables

    $SystemHostname = (hostname).ToString()
    $ErrorActionPreference = 'Stop'
    $MailboxDatabaseCopyStatus = @()

# Gather Data

    #Get Node State
    $NodeState = Get-ClusterNode $SystemHostname

    # Get Node Services Health
    $ServiceHealth = Test-ServiceHealth
        # I need $servicehealth.ServicesNotRunning to be empty, will need to use an until loop here

    # Get Replication Health
    $ReplicationHealth = Test-ReplicationHealth
        # I need:
        #   $replicationhealth.Result to be Passed
        #   $replicationhealth.Error to be empty
    
    # Get Server Component Health
    $ServerComponentState = Get-ServerComponentState $SystemHostname
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
      noda_state = $NodeState
      service_health = $ServiceHealth
      replication_health = $ReplicationHealth
      server_component_state = $ServerComponentState
      mailbox_database_copy_status = $MailboxDatabaseCopyStatus | Select Name,Server,Status,ContentIndexState,CopyQueueLength,ReplayqueueLength
      }
    
    $ExchangeNodeHealth | convertto-json