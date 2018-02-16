Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
AddingExclusionMessage        = Adding DHCP server Exclusion with the given IP address range ...
CheckExclusionMessage         = Checking DHCP server Exclusion with the given IP address range ...
SetExclusionMessage           = DHCP server Exclusion with name '{0}' is now present.
RemovingExclusionMessage      = Removing DHCP server Exclusion with the given IP address range ...
DeleteExclusionMessage        = DHCP server Exclusion with the given IP address range is now absent.
TestExclusionMessage          = DHCP server Exclusion with the given IP address range is '{0}' and it should be '{1}'.                           
                          
CheckPropertyMessage      = Checking DHCP server Exclusion '{0}' ...
NotDesiredPropertyMessage = DHCP server Exclusion '{0}' is not correct; expected '{1}', actual '{2}'.
DesiredPropertyMessage    = DHCP server Exclusion '{0}' is correct.
SetPropertyMessage        = DHCP server Exclusion '{0}' is set to '{1}'.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [String]$IPStartRange,

        [parameter(Mandatory)]
        [String]$IPEndRange,

        [parameter(Mandatory)]
        [String]$Prefix,
        
        [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6'

    )
#region Input Validation
    Write-Verbose "I'm in Get targetResource"
    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

    # Convert the Start Range to be a valid IPAddress
    
    # Convert the End Range to be a valid IPAddress
    $IPEndRange = (Get-ValidIpAddress -ipString $IPEndRange -AddressFamily $AddressFamily -parameterName 'IPEndRange').ToString()

    # Convert the Subnet Mask to be a valid IPAddress
    $Prefix = (Get-ValidIpAddress -ipString $Prefix -AddressFamily $AddressFamily -parameterName 'Prefix').ToString()

    # Check to ensure startRange is smaller than endRange
    if($IPEndRange.Address -lt $IPStartRange.Address)
    {
        $errorMsg = $LocalizedData.InvalidStartAndEndRangeMessage
        New-TerminatingError -errorId RangeNotCorrect -errorMessage $errorMsg -errorCategory InvalidArgument
    }
    
#endregion Input Validation

    $ExclusionRange = Get-DhcpServerv6ExclusionRange | Where-Object {($_.StartRange -eq $IPStartRange) -and ($_.EndRange -eq $IPEndRange)}
    if($ExclusionRange)
    {
        $ensure = 'Present'
    }
    else
    {
        $ensure = 'Absent'
    }

    return @{
        Prefix       = $ExclusionRange.Prefix
        IPStartRange  = $ExclusionRange.StartRange
        IPEndRange    = $ExclusionRange.EndRange
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
        [String]$IPStartRange,

        [parameter(Mandatory)]
        [String]$IPEndRange,

        [parameter(Mandatory)]
        [String]$Prefix,

        [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6',

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )

     Write-Verbose "I'm in Set targetResource"
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
        [String]$IPStartRange,

        [parameter(Mandatory)]
        [String]$IPEndRange,

        [parameter(Mandatory)]
        [String]$Prefix,

        [ValidateSet('IPv6')]
        [String]$AddressFamily = 'IPv6',

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present'
    )

#region Input Validation
    Write-Verbose "I'n in Test Target"

    # Check for DhcpServer module/role
    Assert-Module -moduleName DHCPServer

    # Convert the Start Range to be a valid IPAddress
    $IPStartRange = (Get-ValidIpAddress -ipString $IPStartRange -AddressFamily $AddressFamily -parameterName 'IPStartRange').ToString()

    # Convert the End Range to be a valid IPAddress
    $IPEndRange = (Get-ValidIpAddress -ipString $IPEndRange -AddressFamily $AddressFamily -parameterName 'IPEndRange').ToString()

    # Convert the Subnet Mask to be a valid IPAddress
    $Prefix = (Get-ValidIpAddress -ipString $Prefix -AddressFamily $AddressFamily -parameterName 'Prefix').ToString()

    # Check to ensure startRange is smaller than endRange
    if($IPEndRange.Address -lt $IPStartRange.Address)
    {
        $errorMsg = $LocalizedData.InvalidStartAndEndRangeMessage
        New-TerminatingError -errorId RangeNotCorrect -errorMessage $errorMsg -errorCategory InvalidArgument
    }
    
#endregion Input Validation

    if($PSBoundParameters.ContainsKey('Debug')){ $null = $PSBoundParameters.Remove('Debug')}
    if($PSBoundParameters.ContainsKey('AddressFamily')) {$null = $PSBoundParameters.Remove('AddressFamily')}

    Validate-ResourceProperties @PSBoundParameters

}

function ValidateResourceProperties
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [String]$IPStartRange,

        [parameter(Mandatory)]
        [String]$IPEndRange,

        [parameter(Mandatory)]
        [String]$Prefix,

        [ValidateSet('Present','Absent')]
        [String]$Ensure = 'Present',

        [switch]$Apply
    )
    
    $checkExclusionMessage = $LocalizedData.CheckExclusionMessage
    Write-Verbose -Message $checkExclusionMessage
    
    Write-Verbose "Prefix is $Prefix"

     
    $ExclusionRange = Get-DhcpServerv6ExclusionRange | Where-Object {($_.StartRange -eq $IPStartRange) -and ($_.EndRange -eq $IPEndRange)}


     # Exclusion range is set
    if($ExclusionRange)
    {
        $TestExclusionMessage = $($LocalizedData.TestExclusionMessage) -f 'present', $Ensure
        Write-Verbose -Message $TestExclusionMessage

        # if it should be present, test individual properties to match parameter values
        if($Ensure -eq 'Present')
        {

            return $true
           
        } # end ensure eq present

        # If dhcpscope should be absent
        else
        {
            if($Apply)
            { 
                $removingScopeMsg = $LocalizedData.RemovingExclusionMessage
                Write-Verbose -Message $removingScopeMsg

                # Remove the Exclusion Range
                Remove-DhcpServerv6ExclusionRange -Prefix $Prefix -StartRange $IPStartRange -EndRange $IPEndRange

                $deleteScopeMsg = $LocalizedData.deleteExclusionMessage
                Write-Verbose -Message $deleteScopeMsg
            }
            else
            {
                return $false
            }
        }# end ensure -eq 'Absent'
    } # end ExclusionRange
    
    #If dhcpScope is not set, create it if needed
    else
    {
        $TestExclusionMessage = $($LocalizedData.TestExclusionMessage) -f 'absent', $Ensure
        Write-Verbose -Message $TestExclusionMessage

        if($Ensure -eq 'Present')
        {
            if($Apply)
            {
                               
                $addingExclusionMessage = $LocalizedData.AddingExclusionMessage
                Write-Verbose -Message $addingExclusionMessage

                try
                {
                    # Create a new scope with specified properties
                    Add-DhcpServerv6ExclusionRange -Prefix $Prefix -StartRange $IPStartRange -EndRange $IPEndRange

                    $setExclusionMessage = $($LocalizedData.SetExclusionMessage) -f $Name
                    Write-Verbose -Message $setExclusionMessage
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
