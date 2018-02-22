Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
AddingScopeMessage        = Adding DHCP server scope with the given IP address range ...
CheckScopeMessage         = Checking DHCP server scope with the given IP address range ...
SetScopeMessage           = DHCP server scope with name '{0}' is now present.
RemovingScopeMessage      = Removing DHCP server scope with the given IP address range ...
DeleteScopeMessage        = DHCP server scope with the given IP address range is now absent.
TestScopeMessage          = DHCP server scope with the given IP address range is '{0}' and it should be '{1}'.                           
                          
CheckPropertyMessage      = Checking DHCP server scope '{0}' ...
NotDesiredPropertyMessage = DHCP server scope '{0}' is not correct; expected '{1}', actual '{2}'.
DesiredPropertyMessage    = DHCP server scope '{0}' is correct.
SetPropertyMessage        = DHCP server scope '{0}' is set to '{1}'.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [String]$Name,

        [parameter(Mandatory)]
        [String]$Prefix,

        [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6'

    )
#region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

    # Convert the Prefix to be a valid IPAddress
    
    # If the prefix if Invalid, Terminate the program.
    
#endregion Input Validation

    $dhcpScope = Get-DhcpServerv6Scope | Where-Object {($_.Prefix -eq $Prefix)}
    if($dhcpScope)
    {
        $ensure = 'Present'
    }
    else
    {
        $ensure = 'Absent'
    }

    return @{
        Prefix       = $dhcpScope.Prefix
        Name          = $dhcpScope.Name
        PreferredLifeTime = $dhcpScope.PreferredLifeTime.ToString()
        ValidLifeTime = $dhcpscope.ValidLifeTime.ToString()
        State         = $dhcpScope.State
        AddressFamily = 'IPv6'
        Ensure        = $Ensure
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [String]$Name,

        [parameter(Mandatory)]
        [String]$Prefix,

        [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6',

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$PreferredLifeTime,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$ValidLifeTime,

        [ValidateSet('Active','Inactive')]
        [String]$State = 'Active',

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
        [String]$Name,

        [parameter(Mandatory)]
        [String]$Prefix,

        [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6',

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$PreferredLifeTime,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$ValidLifeTime,

        [ValidateSet('Active','Inactive')]
        [String]$State = 'Active',

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )

#region Input Validation

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

    # Check to ensure startRange is smaller than endRange
    
    
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
        [String]$Name,

        [parameter(Mandatory)]
        [String]$Prefix,

        [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6',

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$PreferredLifeTime,

        [Parameter()] [ValidateNotNullOrEmpty()]
        [String]$ValidLifeTime,

        [ValidateSet('Active','Inactive')]
        [String]$State = 'Active',

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present',

        [Switch]$Apply
    )
    
    # Convert the PreferredLifeTime to be a valid timespan
    if($PreferredLifeTime)
    {
        $PreferredLifeTime = (Get-ValidTimeSpan -tsString $PreferredLifeTime -parameterName 'PreferredLifeTime').ToString()
    }

    if($ValidLifeTime)
    {
        $ValidLifeTime = (Get-ValidTimeSpan -tsString $ValidLifeTime -parameterName 'ValidLifeTime').ToString()
    }

    $checkScopeMessage = $LocalizedData.CheckScopeMessage
    Write-Verbose -Message $checkScopeMessage

    $dhcpScope = Get-DhcpServerv6Scope |  Where-Object {($_.Prefix -eq $Prefix)}
    # Initialize the parameter collection
    if($Apply)
    { 
        $parameters = @{}
    }

    # dhcpScope is set
    if($dhcpScope)
    {
        $TestScopeMessage = $($LocalizedData.TestScopeMessage) -f 'present', $Ensure
        Write-Verbose -Message $TestScopeMessage

        # if it should be present, test individual properties to match parameter values
        if($Ensure -eq 'Present')
        {
            #region Test the Scope Name
            $checkPropertyMsg = $($LocalizedData.CheckPropertyMessage) -f 'name'
            Write-Verbose -Message $checkPropertyMsg

            if($dhcpScope.Name -ne $Name) 
            {
                $notDesiredPropertyMsg = $($LocalizedData.NotDesiredPropertyMessage) -f 'name',$Name,$($dhcpScope.Name)
                Write-Verbose -Message $notDesiredPropertyMsg

                if($Apply)
                {
                    $parameters['Name'] = $Name
                }
                else 
                {
                    return $false
                }
            }
            else
            {
                $desiredPropertyMsg = $($LocalizedData.DesiredPropertyMessage) -f 'name'
                Write-Verbose -Message $desiredPropertyMsg
            }
            #endregion scope name

            #region Test the PreferredLifeTim
            if($PSBoundParameters.ContainsKey('PreferredLifeTime'))
            {
                $checkPropertyMsg = $($LocalizedData.CheckPropertyMessage) -f 'PreferredLifeTime'
                Write-Verbose -Message $checkPropertyMsg

                if($dhcpScope.PreferredLifeTime -ne $PreferredLifeTime) 
                {
                    $notDesiredPropertyMsg = $($LocalizedData.NotDesiredPropertyMessage) -f 'PreferredLifeTime',$PreferredLifeTime,$($dhcpScope.PreferredLifeTime)
                    Write-Verbose -Message $notDesiredPropertyMsg
 
                    if($Apply)
                    {
                        $parameters['PreferredLifeTime'] = $PreferredLifeTime
                    }
                    else
                    {
                        return $false
                    }
                }
                else
                {
                    $desiredPropertyMsg = $($LocalizedData.DesiredPropertyMessage) -f 'PreferredLifeTime'
                    Write-Verbose -Message $desiredPropertyMsg
                }
            }
            #endregion PreferredLeaseTime

            #region Test the ValidLifeTime
            if($PSBoundParameters.ContainsKey('ValidLifeTime'))
            {
                $checkPropertyMsg = $($LocalizedData.CheckPropertyMessage) -f 'ValidLifeTime'
                Write-Verbose -Message $checkPropertyMsg

                if($dhcpScope.ValidLifeTime -ne $ValidLifeTime) 
                {
                    $notDesiredPropertyMsg = $($LocalizedData.NotDesiredPropertyMessage) -f 'ValidLifeTime',$ValidLifeTime,$($dhcpScope.ValidLifeTime)
                    Write-Verbose -Message $notDesiredPropertyMsg
 
                    if($Apply)
                    {
                        $parameters['ValidLifeTime'] = $ValidLifeTime
                    }
                    else
                    {
                        return $false
                    }
                }
                else
                {
                    $desiredPropertyMsg = $($LocalizedData.DesiredPropertyMessage) -f 'ValidLifeTime'
                    Write-Verbose -Message $desiredPropertyMsg
                }
            }
            #endregion ValidLifeTime

            #region Test the Scope State
            if($PSBoundParameters.ContainsKey('State'))
            {
                $checkPropertyMsg = $($LocalizedData.CheckPropertyMessage) -f 'state'
                Write-Verbose -Message $checkPropertyMsg

                if($dhcpScope.State -ne $State) 
                {
                    $notDesiredPropertyMsg = $($LocalizedData.NotDesiredPropertyMessage) -f 'state',$State,$($dhcpScope.State)
                    Write-Verbose -Message $notDesiredPropertyMsg

                    if($Apply)
                    {
                        $parameters['State'] = $State
                    }
                    else
                    {
                        return $false
                    }
                }
                else
                {
                    $desiredPropertyMsg = $($LocalizedData.DesiredPropertyMessage) -f 'state'
                    Write-Verbose -Message $desiredPropertyMsg
                }
            }
            #endregion scope state

            

            if($Apply)
            {
                # If parameters contains more than 0 key, set the DhcpServer scope
                if($parameters.Count -gt 0) 
                {
                    Set-DhcpServerv6Scope @parameters -Prefix $dhcpScope.Prefix
                    Write-PropertyMessage -Parameters $parameters -keysToSkip Prefix `
                                          -Message $($LocalizedData.SetPropertyMessage) -Verbose
                }
            } # end Apply
            else
            {
                return $true
            }
        } # end ensure eq present

        # If dhcpscope should be absent
        else
        {
            if($Apply)
            {
                $removingScopeMsg = $LocalizedData.RemovingScopeMessage
                Write-Verbose -Message $removingScopeMsg

                # Remove the scope
                Remove-DhcpServerv6Scope -Prefix $dhcpScope.Prefix

                $deleteScopeMsg = $LocalizedData.deleteScopeMessage
                Write-Verbose -Message $deleteScopeMsg
            }
            else
            {
                return $false
            }
        }# end ensure -eq 'Absent'
    } # if $dhcpScope

    #If dhcpScope is not set, create it if needed
    else
    {
        $TestScopeMessage = $($LocalizedData.TestScopeMessage) -f 'absent', $Ensure
        Write-Verbose -Message $TestScopeMessage

        if($Ensure -eq 'Present')
        {
            if($Apply)
            {
                # Add mandatory parameters
                $parameters['Name']       = $Name
                

                # Check if PreferredLifeTime is specified, add to parameter collection
                if($PSBoundParameters.ContainsKey('Prefix'))
                {
                    $parameters['Prefix'] = $Prefix
                }
                
                # Check if PreferredLifeTime is specified, add to parameter collection
                if($PSBoundParameters.ContainsKey('PreferredLifeTime'))
                {
                    $parameters['PreferredLifeTime'] = $PreferredLifeTime
                }

                
                # Check if ValidLifeTime is specified, add to parameter collection
                if($PSBoundParameters.ContainsKey('ValidLifeTime'))
                {
                    $parameters['ValidLifeTime'] = $ValidLifeTime
                }

                # Check if State is specified, add to parameter collection
                if($PSBoundParameters.ContainsKey('State'))
                {
                        $parameters['State'] = $State
                }

                $addingScopeMessage = $LocalizedData.AddingScopeMessage
                Write-Verbose -Message $addingScopeMessage
                Write-Verbose $Name
                Write-Verbose $PreferredLifeTime
                Write-Verbose $ValidLifeTime
                Write-Verbose $state
                Write-Verbose "Prefix is $Prefix"
                try
                {
                    # Create a new scope with specified properties
                    Add-DhcpServerv6Scope @parameters

                    $setScopeMessage = $($LocalizedData.SetScopeMessage) -f $Name
                    Write-Verbose -Message $setScopeMessage
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

Export-ModuleMember -Function *-TargetResource
