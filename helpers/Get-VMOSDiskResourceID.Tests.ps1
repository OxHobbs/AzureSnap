$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Get-VMOSDiskResourceID" {
    # Context "Required Params" {
    #     It "throws with no RG" {
    #     }
    # }
    It 'does something' {
        $true | Should Be $true
    }
}
