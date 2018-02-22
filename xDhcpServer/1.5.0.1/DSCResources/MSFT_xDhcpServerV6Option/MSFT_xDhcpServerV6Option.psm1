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
        [String]$Prefix,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$DnsServerIPAddress,

        [Parameter()] [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6'
    )

#region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer
    
    # If the prefix if Invalid, Terminate the program.
    
    
    # Test if the Prefix is valid
    

#endregion Input Validation

    $ensure = 'Absent'
        try
        {
            $dhcpOption = Get-DhcpServerv6OptionValue 
            
            if($dhcpOption)
            {
                $DomainSearchList = (($dhcpOption | Where-Object Name -like 'Domain Search List').value)[0]
                $ensure = 'Present'
                $dnsServerIP = ($dhcpOption | Where-Object Name -like 'DNS Recursive Name Server IPv6 Address List').value|Expand-IPv6Address
                
            }
        }
        catch
        {
        }
    

    @{
        Prefix = $Prefix
        DomainSearchList = $DomainSearchList
        AddressFamily = 'IPv6'
        Ensure = $ensure
        DnsServerIPAddress = $dnsServerIP
        
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [String]$Prefix,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$DnsServerIPAddress,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$DomainSearchList,

        [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6',

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )

#region Input Validation

    # Array of valid IP Address
    [String[]]$validDnSServer = @()

    # Convert the input to be valid IPAddress
    foreach ($dnsServerIp in $DnsServerIPAddress)
    {
        $validDnSServer += (Get-ValidIpAddress -ipString $dnsServerIp -AddressFamily $AddressFamily -parameterName 'DnsServerIPAddress').ToString()
    }
    $DnsServerIPAddress = $validDnSServer|Expand-IPv6Address 
    
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
        [String]$Prefix,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$DnsServerIPAddress,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$DomainSearchList,

        [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6',

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )


    # Array of valid IP Address
    [String[]]$validDnSServer = @()
    
    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer
    Write-Verbose "Prefix is $Prefix and AddressFamily is $AddressFamily"

    
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
        [string]$Prefix,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String[]]$DnsServerIPAddress,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$DomainSearchList,

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present',

        [switch]$Apply
    )
    
    $scopeIDMessage = $($LocalizedData.CheckScopeIDMessage) -f $Prefix
    Write-Verbose -Message $scopeIDMessage
    

    $dhcpOption = Get-DhcpServerv6OptionValue 
    $DnsServerIPAddress = $DnsServerIPAddress|Expand-IPv6Address 
  
    # Found DHCPOption
    if($dhcpOption)
    {
        $foundScopeIdMessage = $($LocalizedData.FoundScopeIDMessage) -f $Prefix, $Ensure
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
                
                $dnsServerIP = ($DhcpOption | Where-Object OptionId -eq 23).Value|Expand-IPv6Address
                # If comparison return something, they are not equal
                if((-not $dnsServerIP) -or (Compare-Object $dnsServerIP $DnsServerIPAddress))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f 'DNS server ip', ($DnsServerIPAddress -join ', '), ($dnsServerIP -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage
                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f 'DNS server ip'
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv6OptionValue -DnsServer $DnsServerIPAddress -Force

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
            
            
            # If DNS Domain is specified, test that
            if($PSBoundParameters.ContainsKey('DomainSearchList'))
            {
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'Dns domain name'
                Write-Verbose -Message $checkPropertyMessage

                $dnsDomainName = ($DhcpOption | Where-Object OptionId -eq 24).Value
                if($dnsDomainName -ne $DomainSearchList) 
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f 'DNS domain name', $DomainSearchList, ($dnsDomainName -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage

                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f 'DNS domain name'
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv6OptionValue -DomainSearchList $DomainSearchList
    
                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f 'DNS domain name', ($DomainSearchList -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                    } # end $Apply
                    else
                    { 
                        return $false
                    }
                } # end $dnsDomainName -ne $DomainSearchList
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f 'DNS domain name'
                    Write-Verbose -Message $desiredPropertyMessage
                }
            } # end $PSBoundParameters.ContainsKey('DomainSearchList')

           
            
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
                Write-Verbose -Message ($LocalizedData.RemovingScopeOptions -f $Prefix)
                foreach($option in $dhcpOption.Prefix)
                {
                    Remove-DhcpServerv6OptionValue -OptionId $option
    
                }
                Write-Verbose -Message ($LocalizedData.ScopeOptionsRemoved)
            } # end if $Apply
            else {return $false}
        }
    }
    else
    {
        $notFoundScopeIdMessage = $($LocalizedData.NotFoundScopeIDMessage) -f $Prefix, $Ensure
        Write-Verbose -Message $notFoundScopeIdMessage

        if($Apply)
        {
            # If Options should be present, create those
            if($Ensure -eq 'Present')
            {
                $addingScopeIdMessage = $($LocalizedData.AddingScopeIDMessage) -f $Prefix
                Write-Verbose -Message $addingScopeIdMessage

                $parameters = @{}
    

                ## If DnsServer(s) specified, pass it
                if ($PSBoundParameters.ContainsKey('DnsServerIPAddress'))
                {
                    $parameters['DnsServer'] = $DnsServerIPAddress
                }
                
                # If Dns domain is specified pass it
                if($PSBoundParameters.ContainsKey('DomainSearchList'))
                {
                    $parameters['DomainSearchList'] = $DomainSearchList
                }

                Set-DhcpServerv6OptionValue @parameters -Force

                $setScopeIdMessage = $($LocalizedData.SetScopeIDMessage) -f $Prefix
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
