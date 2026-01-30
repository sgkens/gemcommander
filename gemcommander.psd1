@{
    RootModule         = 'gemcommander.psm1'
    ModuleVersion      = '0.1.0'
    GUID               = 'ccc9be26-17aa-4a86-8d5b-14d6d15def37'
    Author             = 'Garvey k. Snow'
    CompanyName        = 'Phellams'
    Copyright          = '(c) 2026 Garvey k. Snow. All rights reserved.'
    Description        = 'A PowerShell module for automating the Ruby Gem lifecycle. It bridges JSON configuration to `.gemspec` generation, providing a unified interface for building, verifying, and publishing gems.'
    FunctionsToExport  = @(
        'Invoke-GemCommander'
    )
    CmdletsToExport    = @()
    VariablesToExport  = @()
    AliasesToExport    = @(
        'GemCommander'
    )
    PrivateData        = @{
        PSData = @{
            Tags                     = @('psmodule','PowerShellModule','Help', 'Formatting', 'CLI', 'PowerShell', 'Documentation')
            ReleaseNotes             = @{
                # '1.2.1' = 'Initial release with New-PHWriter cmdlet for custom help formatting and enhanced layout.'
            }
            RequireLicenseAcceptance = $false
            LicenseUri               = 'https://choosealicense.com/licenses/mit'
            ProjectUri               = 'https://gitlab.com/phellams/gemcommander.git'
            IconUri                  = 'https://raw.githubusercontent.com/phellams/phellams-general-resources/main/logos/gemcommander/dist/png/gemcommander-logo-128x128.png'
            # CHOCOLATE ---------------------
            ChocoDescription         = 'A PowerShell module for automating the Ruby Gem lifecycle. It bridges JSON configuration to `.gemspec` generation, providing a unified interface for building, verifying, and publishing gems.'
            ChocoTitle               = 'gemcommander - A PowerShell module for automating the Ruby Gem lifecycle.'
            LicenseUrl               = 'https://choosealicense.com/licenses/mit'
            ProjectUrl               = 'https://github.com/phellams/gemcommander'
            IconUrl                  = 'https://raw.githubusercontent.com/phellams/phellams-general-resources/main/logos/gemcommander/gemcommander-logo-128x128.png'
            Docsurl                  = 'https://pages.gitlab.io/sgkens/ptoml'
            MailingListUrl           = 'https://github.com/phellams/gemcommander/issues'
            projectSourceUrl         = 'https://github.com/phellams/gemcommander'
            bugTrackerUrl            = 'https://github.com/phellams/gemcommander/issues'
            Summary                  = 'A PowerShell module for automating the Ruby Gem lifecycle. It bridges JSON configuration to `.gemspec` generation, providing a unified interface for building, verifying, and publishing gems.'
            # CHOCOLATE ---------------------
            Prerelease               = 'prerelease.rc'

        }        
    }
    RequiredModules    = @()
    RequiredAssemblies = @()
    FormatsToProcess   = @()
    TypesToProcess     = @()
    NestedModules      = @()
    ScriptsToProcess   = @()
}
