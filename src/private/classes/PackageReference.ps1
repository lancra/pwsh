class Package {
    [string]$Id
    [string]$LatestVersion
    [System.Collections.Generic.Dictionary[string, PackageReference]]$References

    Package([string]$id, [string]$latestVersion) {
        $this.Id = $id
        $this.LatestVersion = $latestVersion
        $this.References = [System.Collections.Generic.Dictionary[string, PackageReference]]::new()
    }
}

class PackageReference {
    [string]$Version
    [System.Collections.Generic.List[string]]$Projects

    PackageReference([string]$version) {
        $this.Version = $version
        $this.Projects = [System.Collections.Generic.List[string]]::new()
    }
}
