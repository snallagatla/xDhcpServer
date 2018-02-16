$Global:DSCModuleName      = 'xDhcpServer'
$Global:DSCResourceName    = 'MSFT_xDhcpServerV6Scope'

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $Global:DSCModuleName `
    -DSCResourceName $Global:DSCResourceName `
    -TestType Unit 
#endregion

# Begin Testing
try
{
    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:DSCResourceName {

        #region Pester Test Initialization
        # TODO: Optopnal Load Mock for use in Pester tests here...
        #endregion

        $testScopeName = 'Test Scope';
        $testScopePrefix = '2405:2300:ff02:80::';
        $testState = 'Active';
        $testLeaseDuration = New-TimeSpan -Days 8;
        
        $testParams = @{
            Name = $testScopeName;
            
        }
                
        $fakeDhcpServerv4Scope = [PSCustomObject] @{
            Prefix = $testScopePrefix;
            Name = $testScopeName;
            LeaseDuration = $testLeaseDuration;
            State = $testState;
            AddressFamily = 'IPv6';
        }

        #region Function Get-TargetResource
        Describe "$($Global:DSCResourceName)\Get-TargetResource" {

            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }

            It 'Calls "Assert-Module" to ensure "DHCPServer" module is available' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                
                $result = Get-TargetResource @testParams;
                
                Assert-MockCalled Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } -Scope It;
            }
            
            It 'Returns a "System.Collections.Hashtable" object type' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                $result = Get-TargetResource @testParams;
                
                $result -is [System.Collections.Hashtable] | Should Be $true;
            }
        }
        #endregion Function Get-TargetResource

        #region Function Test-TargetResource
        Describe "$($Global:DSCResourceName)\Test-TargetResource" {
            
            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }

            It 'Returns a "System.Boolean" object type' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                
                $result = Test-TargetResource @testParams;
                
                $result -is [System.Boolean] | Should Be $true;
            }
            
            It 'Passes when all parameters are correct' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                
                $result = Test-TargetResource @testParams;
                
                $result | Should Be $true;
            }
            
            It 'Passes when optional "LeaseDuration" parameter is correct' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                
                $result = Test-TargetResource @testParams -LeaseDuration $testLeaseDuration.ToString();
                
                $result | Should Be $true;
            }
            
            It 'Passes when optional "State" parameter is correct' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                
                $result = Test-TargetResource @testParams -State 'Active';
                
                $result | Should Be $true;
            }
            
            It 'Passes when "Ensure" = "Absent" and scope does not exist' {
                Mock Get-DhcpServerv6Scope { }
                
                $result = Test-TargetResource @testParams -Ensure 'Absent';
                
                $result | Should Be $true;
            }
            
            It 'Fails when "Name" parameter is incorrect' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                $testNameParams = $testParams.Clone();
                $testNameParams['Name'] = 'IncorrectName';
                
                $result = Test-TargetResource @testNameParams;
                
                $result | Should Be $false;
            }
            
            It 'Fails when optional "LeaseDuration" parameter is incorrect' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                
                $result = Test-TargetResource @testParams -LeaseDuration '08:00:00';
                
                $result | Should Be $false;
            }
            
            It 'Fails when optional "State" parameter is incorrect' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                
                $result = Test-TargetResource @testParams -State 'Inactive';
                
                $result | Should Be $false;
            }
            
            It 'Fails when "Ensure" = "Absent" and scope does exist' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                
                $result = Test-TargetResource @testParams -Ensure 'Absent';
                
                $result | Should Be $false;
            }
                       
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Set-TargetResource" {
            
            Mock Assert-Module -ParameterFilter { $ModuleName -eq 'DHCPServer' } { }
            
            It 'Calls "Add-DhcpServerv6Scope" when "Ensure" = "Present" and scope does not exist' {
                Mock Get-DhcpServerv6Scope { }
                Mock Add-DhcpServerv6Scope { }
                
                Set-TargetResource @testParams;
                
                Assert-MockCalled Add-DhcpServerv6Scope -Scope It;
            }
            
            It 'Calls "Remove-DhcpServerv6Scope" when "Ensure" = "Absent" and scope does exist' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                Mock Remove-DhcpServerv6Scope { }
                
                Set-TargetResource @testParams -Ensure 'Absent';
                
                Assert-MockCalled Remove-DhcpServerv6Scope -Scope It;
            }
            
            It 'Calls "Set-DhcpServerv6Scope" when "Ensure" = "Present" and scope does exist' {
                Mock Get-DhcpServerv6Scope { return $fakeDhcpServerv6Scope; }
                Mock Set-DhcpServerv6Scope { }
                
                Set-TargetResource @testParams -LeaseDuration '08:00:00';
                
                Assert-MockCalled Set-DhcpServerv6Scope -Scope It;
            }
            
            
            
        }
        #endregion

        #region Function Set-TargetResource
        Describe "$($Global:DSCResourceName)\Validate-ResourceProperties" {
            # TODO: Complete Tests...
        }
        #endregion

    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
