$Properties = @{
    Prefix       = New-xDscResourceProperty -Name Prefix -Type String -Attribute Read `
                                             -Description Prefix for which properties are set'
    Name          = New-xDscResourceProperty -Name Name -Type String -Attribute Required `
                                         -Description 'Name of DHCP Scope'
    AddressFamily = New-xDscResourceProperty -Name AddressFamily -Type String -Attribute Write `
                                        -ValidateSet 'IPv4' -Description 'Address family type'
    LeaseDuration = New-xDscResourceProperty -Name LeaseDuration -Type String -Attribute Write `
                                         -Description 'Time interval for which an IP address should be leased'
    State         = New-xDscResourceProperty -Name State -Type String -Attribute Write `
                                      -ValidateSet 'Active','Inactive' `
                                      -Description 'Whether scope should be active or inactive'
    Ensure        = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write `
                                      -ValidateSet 'Present','Absent' `
                                      -Description 'Whether scope should be set or removed'
}

New-xDscResource -Name MSFT_xDhcpServerV6Scope -Property $Properties.Values -ModuleName xDhcpServer -FriendlyName xDhcpServerV6Scope
