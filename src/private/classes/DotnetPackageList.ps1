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
    [DotnetVulnerabilitySeverity]$Severity
    [string]$AdvisoryUrl

    DotnetVulnerability([PSCustomObject]$object) {
        $this.Severity = [DotnetVulnerabilitySeverity]::FromName($object.severity)
        $this.AdvisoryUrl = $object.advisoryUrl
    }
}

class DotnetVulnerabilitySeverity {
    [string]$Name
    [System.ConsoleColor]$ForegroundColor
    [int]$Order

    hidden DotnetVulnerabilitySeverity([string]$name, [System.ConsoleColor]$foregroundColor, [int]$order) {
        $this.Name = $name
        $this.ForegroundColor = $foregroundColor
        $this.Order = $order
    }

    static [DotnetVulnerabilitySeverity] FromName([string]$name) {
        $severity = switch ($name)
        {
            Low { [DotnetVulnerabilitySeverity]::new($name, [System.ConsoleColor]::White, 4) }
            Moderate { [DotnetVulnerabilitySeverity]::new($name, [System.ConsoleColor]::Yellow, 3) }
            High { [DotnetVulnerabilitySeverity]::new($name, [System.ConsoleColor]::Red, 2) }
            Critical { [DotnetVulnerabilitySeverity]::new($name, [System.ConsoleColor]::DarkRed, 1) }
            default { [DotnetVulnerabilitySeverity]::new($name, [System.ConsoleColor]::Magenta, 5) }
        }

        return $severity
    }
}

enum DotnetPackageKind {
    Deprecated
    Outdated
    Vulnerable
}

enum DotnetPackageReferenceKind {
    Direct
    Transitive
}

class OutputPackage {
    [string]$Id
    [string]$LatestVersion
    [hashtable]$References

    OutputPackage([string]$id) {
        $this.Id = $id
        $this.References = @{}
    }
}

class OutputPackageReference {
    [string]$Version
    [hashtable]$Projects

    [bool]$IsDirect
    [bool]$IsTransitive
    [bool]$IsDeprecated
    [DotnetVulnerability[]]$Vulnerabilities

    OutputPackageReference([string]$version) {
        $this.Version = $version
        $this.Projects = @{}
        $this.Vulnerabilities = @()
    }
}
