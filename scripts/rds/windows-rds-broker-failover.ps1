# Import Required Powershell Modules and SnapIns

    Import-Module RemoteDesktop

# Initalise Variables

    $ErrorActionPreference = 'Stop'

# Functions

    Function Get-AvailableBroker {
        $CurrentFQDN = [System.Net.Dns]::GetHostByName($env:computerName).HostName
		$CurrentBroker = (Get-RDConnectionBrokerHighAvailability).ActiveManagementServer
		$Brokers = (Get-RDConnectionBrokerHighAvailability).ConnectionBroker
		$AvailableBrokers = @()
		$BrokerError = @()
		
		ForEach ($Broker in ($Brokers | Where-Object {$_ -ne $CurrentFQDN -and $_ -ne $CurrentBroker})) {
				$AvailableBrokers += $Broker
			}
		
		If ($AvailableBrokers) {
				Write-Output ($AvailableBrokers)[0]
			} Else {
				$BrokerError = "No suitable broker found for failover (Suitable broker cannot be current server broker, or server to be failoved over from).  "
				$BrokerError += "Known brokers are $($Brokers).  "
				$BrokerError += "$($CurrentBroker) is the Current Broker, and so it not a suitable failover candidate as it is already active.  "
				$BrokerError += "$($CurrentFQDN) is the current server, and as you want to fail away from this server, is not a suitable failover candidate."
				Throw $BrokerError
			}
		}
# Failover Broker

    Set-RDActiveManagementServer -ManagementServer (Get-AvailableBroker)