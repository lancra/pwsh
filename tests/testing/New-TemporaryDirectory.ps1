function New-TemporaryDirectory {
    [CmdletBinding()]
    param()
    process {
        $path = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath (New-Guid).Guid
        New-Item -ItemType Directory -Path $path > $null
        $path
    }
}
