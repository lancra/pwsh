function ConvertTo-Hyperlink {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Text,
        [Parameter(Mandatory)]
        [string]$Uri
    )
    process {
        "`e]8;;$Uri`e\$Text`e]8;;`e\"
    }
}
