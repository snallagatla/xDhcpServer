Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
AddingDNSSettingMessage        = Adding DHCP server DNSSetting with the given IP address range ...
CheckDNSSettingMessage         = Checking DHCP server DNSSetting with the given IP address range ...
SetDNSSettingMessage           = DHCP server DNSSetting with name '{0}' is now present.
RemovingDNSSettingMessage      = Removing DHCP server DNSSetting with the given IP address range ...
DeleteDNSSettingMessage        = DHCP server DNSSetting with the given IP address range is now absent.
TestDNSSettingMessage          = DHCP server DNSSetting with the given IP address range is '{0}' and it should be '{1}'.                           
                          
CheckPropertyMessage      = Checking DHCP server DNSSetting '{0}' ...
NotDesiredPropertyMessage = DHCP server DNSSetting '{0}' is not correct; expected '{1}', actual '{2}'.
DesiredPropertyMessage    = DHCP server DNSSetting '{0}' is correct.
SetPropertyMessage        = DHCP server DNSSetting '{0}' is set to '{1}'.
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

        [Parameter()] [ValidateSet('IPv4')]
        [String]$AddressFamily = 'IPv4'
    )
    #region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

    # Convert the Subnet Mask to be a valid IPAddress

    if($ScopeId -eq '*')
    {
    
    }
    else
    {
        $ScopeId = (Get-ValidIpAddress -ipString $ScopeId -AddressFamily $AddressFamily -parameterName 'ScopeId').ToString()
    }
    
#endregion Input Validation

$ensure = 'Absent'
        try
        {
            if($ScopeId -eq '*')
            {
            $DNSSetting = Get-DhcpServerv4DnsSetting
            }
            else
            {
            $DNSSetting = Get-DhcpServerv4DnsSetting -ScopeID $ScopeID
            }
            if($DNSSetting.DynamicUpdates -ne 'Never')
            {
                $DynamicUpdates = $DNSSetting.DynamicUpdates
                $DeleteDnsRROnLeaseExpiry = $DNSSetting.DeleteDnsRROnLeaseExpiry
                $UpdateDnsRRForOlderClients = $DNSSetting.UpdateDnsRRForOlderClients
            }
            else
            {
                $DynamicUpdates = $DNSSetting.DynamicUpdates
              
            }
        }
        catch
        {
        }
    

   return @{
        ScopeID = $ScopeID
        DynamicUpdates = $DynamicUpdates
        DeleteDnsRROnLeaseExpiry = $DeleteDnsRROnLeaseExpiry
        UpdateDnsRRForOlderClients = $UpdateDnsRRForOlderClients
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (

        [parameter(Mandatory)]
        [String]$ScopeId,

        [ValidateSet('IPv4')]
        [String]$AddressFamily = 'IPv4',

        [ValidateSet('Always','Never','OnClientRequest')]
        [String]$DynamicUpdates = 'OnClientRequest',
        
        [ValidateSet($true,$false)]
        [String]$DeleteDnsRROnLeaseExpiry,

        [ValidateSet($true,$false)]
        [String]$UpdateDnsRRForOlderClients,


        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )

    
    if($PSBoundParameters.ContainsKey('Debug')){ $null = $PSBoundParameters.Remove('Debug')}
    if($PSBoundParameters.ContainsKey('AddressFamily')) {$null = $PSBoundParameters.Remove('AddressFamily')}

    Validate-ResourceProperties @PSBoundParameters -Apply

}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory)]
        [String]$ScopeId,

        [ValidateSet('IPv4')]
        [String]$AddressFamily = 'IPv4',

        [ValidateSet('Always','Never','OnClientRequest')]
        [String]$DynamicUpdates = 'OnClientRequest',

        [ValidateSet($true,$false)]
        [String]$DeleteDnsRROnLeaseExpiry = $true,

        [ValidateSet($true,$false)]
        [String]$UpdateDnsRRForOlderClients = $true,
        
        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )

#region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

    
    if($ScopeId -eq '*')
    {
    
    }
    else
    {
       # Convert the Subnet Mask to be a valid IPAddress
    $ScopeId = (Get-ValidIpAddress -ipString $ScopeId -AddressFamily $AddressFamily -parameterName 'ScopeId').ToString()

    }
    
    
    
    
#endregion Input Validation

    if($PSBoundParameters.ContainsKey('Debug')){ $null = $PSBoundParameters.Remove('Debug')}
    if($PSBoundParameters.ContainsKey('AddressFamily')) {$null = $PSBoundParameters.Remove('AddressFamily')}

    Validate-ResourceProperties @PSBoundParameters

}

function Validate-ResourceProperties
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [String]$ScopeId,

        [ValidateSet('IPv4')]
        [String]$AddressFamily = 'IPv4',

        [ValidateSet('Always','Never','OnClientRequest')]
        [String]$DynamicUpdates = 'OnClientRequest',

        [ValidateSet($true,$false)]
        [String]$DeleteDnsRROnLeaseExpiry = $true,

        [ValidateSet($true,$false)]
        [String]$UpdateDnsRRForOlderClients = $true,
        
        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present',

        [Switch]$Apply
    )
    
    
    
    
    Write-Verbose "ScopeID is $ScopeId"
    if($ScopeId -eq '*')
    {
    $DNSUpdates = Get-DhcpServerv4DnsSetting
    }
    else
    {
    $DNSUpdates = Get-DhcpServerv4DnsSetting -ScopeId $ScopeId
    }

    $foundScopeIdMessage = $($LocalizedData.FoundScopeIDMessage) -f $ScopeID, $Ensure
     Write-Verbose -Message $foundScopeIdMessage

    # DNSSetting range is set
    if($DNSUpdates.DynamicUpdates -ne 'Never')
    {
        $TestDNSSettingMessage = $($LocalizedData.TestDNSSettingMessage) -f 'present', $Ensure
        Write-Verbose -Message $TestDNSSettingMessage

        # if it should be present, test individual properties to match parameter values
        
        if($DynamicUpdates -ne 'Never')
        {
        # If DynamicUpdates is specified, test that
            if($PSBoundParameters.ContainsKey('DynamicUpdates'))
            {
                $propertyName = 'Dynamic DNS Updates'
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'Dynamic DNS Updates'
                Write-Verbose -Message $checkPropertyMessage

                $DynamicUpdatesValue = $DNSUpdates.DynamicUpdates
                Write-Verbose "DNS Dynamic value is $DynamicUpdatesValue"
                if((-not $DynamicUpdatesValue) -or (Compare-Object $DynamicUpdatesValue $DynamicUpdates))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f $propertyName, ($DynamicUpdates -join ', '), ($DynamicUpdatesValue -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage

                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f $propertyName
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv4DnsSetting -DynamicUpdates $DynamicUpdates
                        
                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f $propertyName, ($DynamicUpdates -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                    } # end $Apply
                    else
                    { 
                        return $false
                    }
                } # end $DynamicUpdatesValue -ne $DynamicUpdates
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f $propertyName
                    Write-Verbose -Message $desiredPropertyMessage
                    return $false
                }
            } # end $PSBoundParameters.ContainsKey('DynamicUpdates')

            if($PSBoundParameters.ContainsKey('DeleteDnsRROnLeaseExpiry'))
            {
                $propertyName = 'Delete DNS RR on Lease expiry'
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'Delete DNS RR on Lease expiry'
                Write-Verbose -Message $checkPropertyMessage

                $DeleteDnsRROnLeaseExpiryValue = $DNSUpdates.DeleteDnsRROnLeaseExpiry
                Write-Verbose "DeleteDnsRROnLeaseExpiry value is $DeleteDnsRROnLeaseExpiryValue"
                if((-not $DeleteDnsRROnLeaseExpiryValue) -or (Compare-Object $DeleteDnsRROnLeaseExpiryValue $DeleteDnsRROnLeaseExpiry))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f $propertyName, ($DeleteDnsRROnLeaseExpiry -join ', '), ($DeleteDnsRROnLeaseExpiryValue -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage

                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f $propertyName
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv4DnsSetting -DeleteDnsRROnLeaseExpiry $DeleteDnsRROnLeaseExpiry
                        
                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f $propertyName, ($DeleteDnsRROnLeaseExpiry -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                    } # end $Apply
                    else
                    { 
                        return $false
                    }
                } # end $DeleteDnsRROnLeaseExpiryValue -ne $DeleteDnsRROnLeaseExpiry
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f $propertyName
                    Write-Verbose -Message $desiredPropertyMessage
                    return $false
                }
            } # end $PSBoundParameters.ContainsKey('DeleteDnsRROnLeaseExpiry')

            if($PSBoundParameters.ContainsKey('UpdateDnsRRForOlderClients '))
            {
                $propertyName = 'Update DNS RR for Older clients'
                $checkPropertyMessage = $($LocalizedData.CheckPropertyMessage) -f 'Update DNS RR for Older Clients'
                Write-Verbose -Message $checkPropertyMessage

                $DeleteDnsRROnLeaseExpiryValue = $DNSUpdates.DeleteDnsRROnLeaseExpiry
                Write-Verbose "UpdateDnsRRForOlderClients value is $UpdateDnsRRForOlderClients"
                if((-not $UpdateDnsRRForOlderClients) -or (Compare-Object $UpdateDnsRRForOlderClients $UpdateDnsRRForOlderClients))
                {
                    $notDesiredPropertyMessage = $($LocalizedData.NotDesiredPropertyMessage) -f $propertyName, ($UpdateDnsRRForOlderClients -join ', '), ($UpdateDnsRRForOlderClients -join ', ')
                    Write-Verbose -Message $notDesiredPropertyMessage

                    if($Apply)
                    {
                        $settingPropertyMessage = $($LocalizedData.SettingPropertyMessage) -f $propertyName
                        Write-Verbose -Message $settingPropertyMessage
                        Set-DhcpServerv4DnsSetting -UpdateDnsRRForOlderClients $UpdateDnsRRForOlderClients
                        
                        $setPropertyMessage = $($LocalizedData.SetPropertyMessage) -f $propertyName, ($UpdateDnsRRForOlderClients -join ', ')
                        Write-Verbose -Message $setPropertyMessage
                    } # end $Apply
                    else
                    { 
                        return $false
                    }
                } # end $DeleteDnsRROnLeaseExpiryValue -ne $DeleteDnsRROnLeaseExpiry
                else
                {
                    $desiredPropertyMessage = $($LocalizedData.DesiredPropertyMessage) -f $propertyName
                    Write-Verbose -Message $desiredPropertyMessage
                    return $false
                }
            } # end $PSBoundParameters.ContainsKey('UpdateDnsRRForOlderClients ')
        }

        #If dhcpScope is not set, create it if needed
        else
        {
        $TestDNSSettingMessage = $($LocalizedData.TestDNSSettingMessage) -f 'absent', $Ensure
        Write-Verbose -Message $TestDNSSettingMessage

        if($Ensure -eq 'Present')
        {
            if($Apply)
            {
                               
                $addingDNSSettingMessage = $LocalizedData.AddingDNSSettingMessage
                Write-Verbose -Message $addingDNSSettingMessage

                try
                {
                    # Create a new scope with specified properties
                    if($ScopeId -eq '*')
                    {
                    $DNSSetting = Set-DhcpServerv4DnsSetting -DynamicUpdates $DynamicUpdates
                    }
                    else
                    {
                    $DNSSetting = Set-DhcpServerv4DnsSetting -ScopeID $ScopeID -DynamicUpdates $DynamicUpdates
                    }

                    $setDNSSettingMessage = $($LocalizedData.SetDNSSettingMessage) -f $Name
                    Write-Verbose -Message $setDNSSettingMessage
                }
                catch
                {
                    New-TerminatingError -errorId DhcpServerScopeFailure -errorMessage $_.Exception.Message -errorCategory InvalidOperation
                }
            }# end Apply
            else
            {
                return $false
            }  
        } # end Ensure -eq Present
        else
        {
            return $true
        }
    } # else !dhcpscope
}
else
    {
        $notFoundScopeIdMessage = $($LocalizedData.NotFoundScopeIDMessage) -f $ScopeID, $Ensure
        Write-Verbose -Message $notFoundScopeIdMessage

        if($Apply)
        {
            # If Options should be present, create those
            if($DynamicUpdaes -ne 'Never')
            {
                $addingScopeIdMessage = $($LocalizedData.AddingScopeIDMessage) -f $ScopeID
                Write-Verbose -Message $addingScopeIdMessage

                if($ScopeId -eq '*')
                {$parameters = @{}}
                else
                {
                $parameters = @{ScopeID = $ScopeID;}
                }

                
                if($PSBoundParameters.ContainsKey('DynamicUpdates'))
                {
                    $parameters['DynamicUpdates'] = $DynamicUpdates
                    
                }

                if($PSBoundParameters.ContainsKey('DeleteDnsRROnLeaseExpiry'))
                {
                    $parameters['DeleteDnsRROnLeaseExpiry'] = $DeleteDnsRROnLeaseExpiry
                    
                }
                
                if($PSBoundParameters.ContainsKey('UpdateDnsRRForOlderClients '))
                {
                    $parameters['UpdateDnsRRForOlderClients '] = $UpdateDnsRRForOlderClients 
                    
                }

                Set-DhcpServerv4DnsSetting @parameters

                $setScopeIdMessage = $($LocalizedData.SetScopeIDMessage) -f $ScopeID
                Write-Verbose -Message $setScopeIdMessage
            } # end Ensure -eq 'Present
        } # end if $Apply
        else
        {
            # If Options should be present, return false else true
                $addingScopeIdMessage = $($LocalizedData.AddingScopeIDMessage) -f $ScopeID
                Write-Verbose -Message $addingScopeIdMessage

                if($ScopeId -eq '*')
                {$parameters = @{}}
                else
                {
                $parameters = @{ScopeID = $ScopeID;}
                }

                
                if($PSBoundParameters.ContainsKey('DynamicUpdates'))
                {
                    $parameters['DynamicUpdates'] = $DynamicUpdates
                    
                }

                
                Set-DhcpServerv4DnsSetting @parameters

                $setScopeIdMessage = $($LocalizedData.SetScopeIDMessage) -f $ScopeID
            return ($Ensure -eq 'Absent')
        }

}

}
Export-ModuleMember -Function *-TargetResource


