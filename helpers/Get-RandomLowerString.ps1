function Get-RandomLowerString {
    param
    (
        $Length = 5
    )

    "$((97..122) | get-random -Count $Length | % { [char]$_ })".Replace(' ', '')
}