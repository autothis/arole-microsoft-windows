# Import Required Powershell Modules and SnapIns

    Import-Module RemoteDesktop

# Initalise Variables

    $ErrorActionPreference = 'Stop'

# Functions

    Function Get-AmIActive {
        $CurrentFQDN = [System.Net.Dns]::GetHostByName($env:computerName).HostName
			try {
					$ActiveBroker = (Get-RDConnectionBrokerHighAvailability).ActiveManagementServer
				} catch {
					$BrokerError = $True
				}
			if ($BrokerError) {
					Write-Output "Failed"
				} else {
					if ($ActiveBroker -eq $CurrentFQDN -and $BrokerError -ne $True) {
						Write-Output $True
					} else {
						Write-Output $False
					}
				}
		}

# Gather Data

    $AmIActive = Get-AmIActive

# Format Results in JSON
    
    $BrokerResults = [PSCustomObject]@{
      amiactive = $AmIActive
      timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
      error = $error
      }
    
    $BrokerResults | convertto-json | Out-File "c:\temp\amiactive.json"