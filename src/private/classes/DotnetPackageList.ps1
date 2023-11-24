class DotnetPackageListResult {
    [string]$Version
    [string]$Parameters
    [string[]]$Sources
    [DotnetProject[]]$Projects

    DotnetPackageListResult([PSCustomObject]$object) {
        $this.Version = $object.version
        $this.Parameters = $object.parameters
        $this.Sources = $object.sources
        $this.Projects = $object.projects | ForEach-Object { [DotnetProject]::new($_) }
    }
}

class DotnetProject {
    [string]$Path
    [DotnetFramework[]]$Frameworks

    DotnetProject([PSCustomObject]$object) {
        $this.Path = $object.path
        $this.Frameworks = $null -ne $object.frameworks `
            ? @($object.frameworks | ForEach-Object { [DotnetFramework]::new($_) }) `
            : @()
    }
}

class DotnetFramework {
    [string]$Name
    [DotnetPackage[]]$TopLevelPackages
    [DotnetPackage[]]$TransitivePackages

    DotnetFramework([PSCustomObject]$object) {
        $this.Name = $object.framework
        $this.TopLevelPackages = $null -ne $object.topLevelPackages `
            ? @($object.topLevelPackages | ForEach-Object { [DotnetPackage]::new($_) }) `
            : @()
        $this.TransitivePackages = $null -ne $object.transitivePackages `
            ? @($object.transitivePackages | ForEach-Object { [DotnetPackage]::new($_) }) `
            : @()
    }
}

class DotnetPackage {
    [string]$Id
    [string]$ResolvedVersion
    [string]$RequestedVersion
    [string]$LatestVersion
    [string[]]$DeprecationReasons
    [DotnetVulnerability[]]$Vulnerabilities

    DotnetPackage([PSCustomObject]$object) {
        $this.Id = $object.id
        $this.ResolvedVersion = $object.resolvedVersion
        $this.RequestedVersion = $object.requestedVersion
        $this.LatestVersion = $object.latestVersion
        $this.DeprecationReasons = $object.deprecationReasons
        $this.Vulnerabilities = $null -ne $object.vulnerabilities `
            ? @($object.vulnerabilities | ForEach-Object { [DotnetVulnerability]::new($_) }) `
            : @()
    }
}

class DotnetVulnerability {
    [string]$Severity
    [string]$AdvisoryUrl

    DotnetVulnerability([PSCustomObject]$object) {
        $this.Severity = $object.severity
        $this.AdvisoryUrl = $object.advisoryUrl
    }
}
