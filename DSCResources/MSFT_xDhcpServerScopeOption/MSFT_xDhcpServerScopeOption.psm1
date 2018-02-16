Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
InvalidScopeIDMessage     = DHCP server scopeID {0} is not valid. Supply a valid scopeID and try again
CheckScopeIDMessage       = Checking DHCP server options for scopeID {0} ...
AddingScopeIDMessage      = Adding DHCP server options for scopeID {0} ...
SetScopeIDMessage         = DHCP server options is set for scopeID {0}.
FoundScopeIDMessage       = Found DHCP server options for scopeID {0} and they should be {1}
NotFoundScopeIDMessage    = Can not find DHCP server options for scopeID {0} and they should be {1}
RemovingScopeOptions      = Removing DHCP Server options for scopeID {0}...
ScopeOptionsRemoved       = DHCP Server options are removed.

CheckPropertyMessage      = Checking {0} option ...
NotDesiredPropertyMessage = {0} is not correct. Expected {1}, actual {2}
DesiredPropertyMessage    = {0} option is correct.
                          
SettingPropertyMessage    = Setting {0} option ...
SetPropertyMessage        = {0} option is set to {1}.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]$ScopeID,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$DnsServerIPAddress,

        [Parameter()] [ValidateSet('IPv4')]
        [String]$AddressFamily = 'IPv4'
    )

#region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer
    
    # Convert the ScopeID to be a valid IPAddress
    $ScopeID = (Get-ValidIpAddress -ipString $ScopeID -AddressFamily $AddressFamily -parameterName 'ScopeID').ToString()
    
    # Test if the ScopeID is valid
    $null = Get-DhcpServerv4Scope -ScopeId $ScopeID -ErrorAction SilentlyContinue -ErrorVariable err
    if($err)
    {
        $errorMsg = $($LocalizedData.InvalidScopeIdMessage) -f $ScopeID
        New-TerminatingError -errorId ScopeIdNotFound -errorMessage $errorMsg -errorCategory InvalidOperation
    }
    

#endregion Input Validation

    $ensure = 'Absent'
        try
        {
            $dhcpOption = Get-DhcpServerv4OptionValue -ScopeID $ScopeID
            $dhcpMicrosoftOption = Get-DhcpServerv4OptionValue -VendorClass 'Microsoft Options' -ScopeId $ScopeID
            if($dhcpOption)
            {
                $dnsDomain = (($dhcpOption | Where-Object Name -like 'DNS Domain Name').value)[0]
                $ensure = 'Present'
                $dnsServerIP = ($dhcpOption | Where-Object Name -like 'DNS Servers').value
                $Router = ($dhcpOption | Where-Object OptionId -Like 3).value
                $ReleaseDHCPonShutdown = ($dhcpMicrosoftOption | Where-Object OptionId -Like 2).value
                $TimeServerIP = ($dhcpOption | Where-Object OptionId -Like 4).value
                $NTPServerIP = ($dhcpOption | Where-Object OptionId -Like 42).value
            }
        }
        catch
        {
        }
    

    @{
        ScopeID = $ScopeID
        DnsDomain = $dnsDomain
        AddressFamily = 'IPv4'
        Ensure = $ensure
        DnsServerIPAddress = $dnsServerIP
        Router = $Router
        NTPServer = $NTPServerIP
        TimeServer = $TimeServerIP
        ReleaseDHCPonShutdown = $ReleaseDHCPonShutdown
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String]$ScopeID,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$DnsServerIPAddress,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$Router,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$DnsDomain,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$TimeServer,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$NTPServer,

        [ValidateSet('IPv4')]
        [String]$AddressFamily = 'IPv4',

        [ValidateSet('1','0')]
        [String]$ReleaseDHCPonShutdown = '1',

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )

#region Input Validation
    
    # Convert the ScopeID to be a valid IPAddress
    $ScopeID = (Get-ValidIpAddress -ipString $ScopeID -AddressFamily $AddressFamily -parameterName 'ScopeID').ToString()
    
    # Array of valid IP Address
    [String[]]$validDnSServer = @()

    # Convert the input to be valid IPAddress
    foreach ($dnsServerIp in $DnsServerIPAddress)
    {
        $validDnSServer += (Get-ValidIpAddress -ipString $dnsServerIp -AddressFamily $AddressFamily -parameterName 'DnsServerIPAddress').ToString()
    }
    $DnsServerIPAddress = $validDnSServer

    # Array of valid IP Address
    [String[]]$validRouter = @()

    # Convert the input to be valid IPAddress
    foreach ($routerIp in $Router)
    {
        $validRouter += (Get-ValidIpAddress -ipString $routerIp -AddressFamily $AddressFamily -parameterName 'Router').ToString()
    }
    $Router = $validRouter

    # Array of valid TimeServer IP Address
    [String[]]$validTimeServer = @()
    
    # Convert the TimeServer data to be valid IPAddress
    foreach ($TimeServerIp in $TimeServer)
    {
        $validTimeServer += (Get-ValidIpAddress -ipString $TimeServerIP -AddressFamily $AddressFamily -parameterName 'TimeServer').ToString()
    }
    $Timeserver = $validTimeServer

    # Array of valid NTPServer IP Address
    [String[]]$validNTPServer = @()

    # Convert the NTPServer data to be valid IPAddress
    foreach ($NTPServerIp in $NTPServer)
    {
        $validNTPServer += (Get-ValidIpAddress -ipString $NTPServerIP -AddressFamily $AddressFamily -parameterName 'NTPServer').ToString()
    }
    $NTPserver = $validNTPServer


#endregion Input Validation

    # Remove $AddressFamily and $debug from PSBoundParameters and pass it to validate-properties helper function
    If($PSBoundParameters['Debug'])      {$null = $PSBoundParameters.Remove('Debug')}
    If($PSBoundParameters['AddressFamily']){$null = $PSBoundParameters.Remove('AddressFamily')}

    ValidateResourceProperties @PSBoundParameters -Apply
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [String]$ScopeID,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$DnsServerIPAddress,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$Router,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$DnsDomain,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$TimeServer,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$NTPServer,

        [ValidateSet('1','0')]
        [String]$ReleaseDHCPonShutdown = '1',

        [ValidateSet('IPv4')]
        [String]$AddressFamily = 'IPv4',

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )

#region Input Validation
    
    # Array of valid IP Address
    [String[]]$validDnSServer = @()
    
    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

    # Convert the ScopeID to be a valid IPAddress
    $ScopeID = (Get-ValidIpAddress -ipString $ScopeID -AddressFamily $AddressFamily -parameterName 'ScopeID').ToString()
    
   # Array of valid IP Address
    [String[]]$validDnSServer = @()
    
    # Convert the input to be valid IPAddress
    foreach ($dnsServerIp in $DnsServerIPAddress)
    {
        $validDnSServer += (Get-ValidIpAddress -ipString $dnsServerIp -AddressFamily $AddressFamily -parameterName 'DnsServerIPAddress').ToString()
    }
    $DnsServerIPAddress = $validDnSServer

    # Array of valid IP Address
    [String[]]$validRouter = @()

    # Convert the input to be valid IPAddress
    foreach ($routerIp in $Router)
    {
        $validRouter += (Get-ValidIpAddress -ipString $routerIp -AddressFamily $AddressFamily -parameterName 'Router').ToString()
    }
    $Router = $validRouter

    # Array of valid TimeServer IP Address
    [String[]]$validTimeServer = @()
    
    # Convert the TimeServer data to be valid IPAddress
    foreach ($TimeServerIp in $TimeServer)
    {
        $validTimeServer += (Get-ValidIpAddress -ipString $TimeServerIP -AddressFamily $AddressFamily -parameterName 'TimeServer').ToString()
    }
    $Timeserver = $validTimeServer

    # Array of valid NTPServer IP Address
    [String[]]$validNTPServer = @()

    # Convert the NTPServer data to be valid IPAddress
    foreach ($NTPServerIp in $NTPServer)
    {
        $validNTPServer += (Get-ValidIpAddress -ipString $NTPServerIP -AddressFamily $AddressFamily -parameterName 'NTPServer').ToString()
    }
    $NTPserver = $validNTPServer


    
    $null = Get-DhcpServerv4Scope -ScopeId $ScopeID -ErrorAction SilentlyContinue -ErrorVariable err
    if($err)
    {
        $errorMsg = $($LocalizedData.InvalidScopeIdMessage) -f $ScopeID
        New-TerminatingError -errorId ScopeIdNotFound -errorMessage $errorMsg -errorCategory InvalidOperation
    }
    
    
#endregion Input Validation

    # Remove $AddressFamily and $debug from PSBoundParameters and pass it to validateProperties helper function
    If($PSBoundParameters['Debug'])      {$null = $PSBoundParameters.Remove('Debug')}
    If($PSBoundParameters['AddressFamily']){$null = $PSBoundParameters.Remove('AddressFamily')}

    ValidateResourceProperties @PSBoundParameters
}

#region Helper function

# Internal function to validate dhcpOptions properties
function ValidateResourceProperties
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$ScopeID,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$DnsServerIPAddress,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$DnsDomain,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$Router,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$TimeServer,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$NTPServer,

        [ValidateSet('1','0')]
        [String]$ReleaseDHCPonShutdown = '1',

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present',

        [switch]$Apply
    )

    $scopeIDMessage = $($LocalizedData.CheckScopeIDMessage) -f $ScopeID
    Write-Verbose -Message $scopeIDMessage
    

    $dhcpOption = Get-DhcpServerv4OptionValue -ScopeID $ScopeID
    $dhcpMicrosoftOption = Get-DhcpServerv4OptionValue -VendorClass 'Microsoft Options' -ScopeId $ScopeID

    # Found DHCPOption
    if($dhcpOption)
    {
        $foundScopeIdMessage = $($LocalizedData.FoundScopeIDMessage) -f $ScopeID, $Ensure
        Write-Verbose -Message $foundScopeIdMessage

        # If Options should be present, check other properties
        if($Ensure -eq 'Present')
        {

            # If DNS Server is specified, test that
            if($PSBoundParameters.ContainsKey('DnsServerIPAddress'))
            {
                # Test the DNS Server IPs
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'Dns server ip'
                Write-Verbose -Message $checkPropertyMessage
                
                $dnsServerIP = ($DhcpOption | Where-Object OptionId -eq 6).Value
                # If comparison return something, they are not equal
                if((-not $dnsServerIP) -or (Compare-Object $dnsServerIP $DnsServerIPAddress))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f 'DNS server ip', ($DnsServerIPAddress -join ', '), ($dnsServerIP -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage
                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f 'DNS server ip'
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv4OptionValue -ScopeId $ScopeID -DnsServer $DnsServerIPAddress -Force

                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f 'DNS server ip', ($DnsServerIPAddress -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                        
                    } # end $Apply
                    else
                    {
                        return $false
                    }
                } # end Compare-object
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f 'DNS server ip'
                    Write-Verbose -Message $desiredPropertyMessage
                }
            }
            
            # If Time Server is specified, test that
            if($PSBoundParameters.ContainsKey('TimeServer'))
            {
                # Test the DNS Server IPs
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'Time Server'
                Write-Verbose -Message $checkPropertyMessage
                
                $TimeserverIP = ($DhcpOption | Where-Object OptionId -eq 4).Value
                # If comparison return something, they are not equal
                if((-not $TimeServerIP) -or (Compare-Object $TimeServerIP $TimeServer))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f 'Time server ip', ($TimeServer -join ', '), ($TimeServerIP -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage
                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f 'Time server ip'
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv4OptionValue -ScopeId $ScopeID -OptionId 4 -Value $TimeServer -Force

                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f 'Time Server ip', ($TimeServer -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                        
                    } # end $Apply
                    else
                    {
                        return $false
                    }
                } # end Compare-object
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f 'Time server ip'
                    Write-Verbose -Message $desiredPropertyMessage
                }
            }

            # If NTP Server is specified, test that
            if($PSBoundParameters.ContainsKey('NTPserver'))
            {
                # Test the DNS Server IPs
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'NTP Server'
                Write-Verbose -Message $checkPropertyMessage
                
                $NTPserverIP = ($DhcpOption | Where-Object OptionId -eq 42).Value
                # If comparison return something, they are not equal
                if((-not $NTPServerIP) -or (Compare-Object $NTPServerIP $NTPserver))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f 'NTP server ip', ($NTPserver -join ', '), ($NTPServerIP -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage
                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f 'NTP server ip'
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv4OptionValue -ScopeId $ScopeID -OptionId 42 -Value $NTPServer -Force

                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f 'NTP Server ip', ($NTPServer -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                        
                    } # end $Apply
                    else
                    {
                        return $false
                    }
                } # end Compare-object
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f 'NTP server ip'
                    Write-Verbose -Message $desiredPropertyMessage
                }
            }

            # If DNS Domain is specified, test that
            if($PSBoundParameters.ContainsKey('DnsDomain'))
            {
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'Dns domain name'
                Write-Verbose -Message $checkPropertyMessage

                $dnsDomainName = ($DhcpOption | Where-Object OptionId -eq 15).Value
                if($dnsDomainName -ne $DnsDomain) 
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f 'DNS domain name', $DnsDomain, ($dnsDomainName -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage

                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f 'DNS domain name'
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv4OptionValue -ScopeId $ScopeID -DnsDomain $DnsDomain
    
                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f 'DNS domain name', ($DnsDomain -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                    } # end $Apply
                    else
                    { 
                        return $false
                    }
                } # end $dnsDomainName -ne $DnsDomain
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f 'DNS domain name'
                    Write-Verbose -Message $desiredPropertyMessage
                }
            } # end $PSBoundParameters.ContainsKey('DnsDomain')

            # If Release DHCP on Shutdown is specified, test that
            if($PSBoundParameters.ContainsKey('ReleaseDHCPonShutdown'))
            {
                $propertyName = 'Release DHCP on Shutdown'
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'Release DHCP on Shutdown'
                Write-Verbose -Message $checkPropertyMessage
                
                $ReleaseDHCPonShutdownValue = ($dhcpMicrosoftOption | Where-Object OptionId -eq 2).Value

                if((-not $ReleaseDHCPonShutdownValue) -or (Compare-Object $ReleaseDHCPonShutdownValue $ReleaseDHCPonShutdown))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f $propertyName, ($ReleaseDHCPonShutdownValue -join ', '), ($ReleaseDHCPonShutdown -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage

                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f $propertyName
                        Write-Verbose -Message $settingPropertyMessage
    
                        Set-DhcpServerv4OptionValue -ScopeId $ScopeID -VendorClass 'Microsoft Options' -OptionId 2 -Value $ReleaseDHCPonShutdown
    
                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f $propertyName, ($ReleaseDHCPonShutdown -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                    } # end $Apply
                    else
                    { 
                        return $false
                    }
                } # end $ReleaseDHCPonShutdownValue -ne $ReleaseDHCPonShutdown
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f $propertyName
                    Write-Verbose -Message $desiredPropertyMessage
                }
            } # end $PSBoundParameters.ContainsKey('ReleaseDHCPonShutdown')

            # If Router is specified, test that
            if($PSBoundParameters.ContainsKey('Router'))
            {
                $propertyName = 'Router ip addresses'
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'Router ip addresses'
                Write-Verbose -Message $checkPropertyMessage

                $routerIP = ($DhcpOption | Where-Object OptionId -eq 3).Value

                if((-not $routerIP) -or (Compare-Object $routerIP $Router))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f $propertyName, ($Router -join ', '), ($routerIP -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage

                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f $propertyName
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv4OptionValue -ScopeId $ScopeID -Router $Router
    
                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f $propertyName, ($Router -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                    } # end $Apply
                    else
                    { 
                        return $false
                    }
                } # end $routerIP -ne $Router
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f $propertyName
                    Write-Verbose -Message $desiredPropertyMessage
                }
            } # end $PSBoundParameters.ContainsKey('Router')
            
            if(-not $Apply)
            {
                return $true
            }
        } # end $Ensure -eq 'Present'

        # If Options should be absent, return False or remove it
        else
        {
            if($Apply)
            {
                Write-Verbose -Message ($LocalizedData.RemovingScopeOptions -f $ScopeID)
                foreach($option in $dhcpOption.OptionID)
                {
                    Remove-DhcpServerv4OptionValue -ScopeId $ScopeID -OptionId $option
    
                }
                Write-Verbose -Message ($LocalizedData.ScopeOptionsRemoved)
            } # end if $Apply
            else {return $false}
        }
    }
    else
    {
        $notFoundScopeIdMessage = $($LocalizedData.NotFoundScopeIDMessage) -f $ScopeID, $Ensure
        Write-Verbose -Message $notFoundScopeIdMessage

        if($Apply)
        {
            # If Options should be present, create those
            if($Ensure -eq 'Present')
            {
                $addingScopeIdMessage = $($LocalizedData.AddingScopeIDMessage) -f $ScopeID
                Write-Verbose -Message $addingScopeIdMessage

                $parameters = @{ScopeID = $ScopeID;}
    

                ## If DnsServer(s) specified, pass it
                if ($PSBoundParameters.ContainsKey('DnsServerIPAddress'))
                {
                    $parameters['DnsServer'] = $DnsServerIPAddress
                }
                
                # If Dns domain is specified pass it
                if($PSBoundParameters.ContainsKey('DnsDomain'))
                {
                    $parameters['DnsDomain'] = $DnsDomain
                }

                Set-DhcpServerv4OptionValue @parameters -Force

                $setScopeIdMessage = $($LocalizedData.SetScopeIDMessage) -f $ScopeID
                Write-Verbose -Message $setScopeIdMessage
            } # end Ensure -eq 'Present
        } # end if $Apply
        else
        {
            # If Options should be present, return false else true
            return ($Ensure -eq 'Absent')
        }
    }
}
#endregion Helper function
if($global:DhpcOptionTest -ne $true)
{
    Export-ModuleMember -Function *-TargetResource
}
