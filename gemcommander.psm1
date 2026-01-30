<#
.Module Name
    GemCommander
.SYNOPSIS
    A PowerShell module for managing the lifecycle of Ruby Gems.
#>

# -----------------------------------------------------------------------------
# Local Scoped Variables
# -----------------------------------------------------------------------------
$script:SemVer = ''
# -----------------------------------------------------------------------------
# helper Functions
# -----------------------------------------------------------------------------
function New-CtString {
    [CmdletBinding()]
    param(
        [parameter(Mandatory, Position = 0)]
        [string]$Message
    )

    process {
        # 1. Define standard 3/4-bit color map (Standard ANSI)
        $stdColors = @{
            'black'   = '30'
            'red'     = '31'
            'green'   = '32'
            'yellow'  = '33'
            'blue'    = '34'
            'magenta' = '35'
            'cyan'    = '36'
            'white'   = '37'
            'default' = '39'
        }

        # 2. Regex Pattern
        # Matches: {ct:color:flags:message} or {ct:color:message}
        # Flags are optional (u, b, i)
        $pattern = '(?i)\{ct:(?<Color>[^:{}]+)(?::(?<Flags>[ubi](?::[ubi])*))?:(?<Message>.*?)\}'

        $finalMessage = $Message
        $ESC = [char]27

        # 3. Get all matches
        $allMatches = [regex]::Matches($finalMessage, $pattern)

        # 4. Process right-to-left to prevent index shifting
        for ($i = $allMatches.Count - 1; $i -ge 0; $i--) {
            $match = $allMatches[$i]
            
            # -- Extract Raw Values --
            $rawColor = $match.Groups['Color'].Value.ToLower()
            $content = $match.Groups['Message'].Value
            $flagsStr = $match.Groups['Flags'].Value

            # -- Build ANSI Code List --
            $codes = [System.Collections.Generic.List[string]]::new()

            # A. Handle Flags (Bold, Underline, Italic)
            if ($flagsStr -match 'b') { $codes.Add('1') } # Bold
            if ($flagsStr -match 'i') { $codes.Add('3') } # Italic
            if ($flagsStr -match 'u') { $codes.Add('4') } # Underline

            # B. Handle Color
            if ($rawColor -match '^\d+$') {
                # Logic: 256 Color Palette (ID 0-255)
                # ANSI Format: 38;5;<n>
                $codes.Add("38;5;$rawColor")
            }
            elseif ($stdColors.ContainsKey($rawColor)) {
                # Logic: Standard Named Color
                $codes.Add($stdColors[$rawColor])
            }
            else {
                # Fallback if color name is unknown (Default to white/default)
                $codes.Add('39') 
            }

            # -- Construct Replacement String --
            # Format: <ESC>[<codes>m<Content><ESC>[0m
            $ansiSequence = "$ESC[" + ($codes -join ';') + "m"
            $replacement = "$ansiSequence$content$ESC[0m"

            # -- Replace in original string --
            $finalMessage = $finalMessage.Remove($match.Index, $match.Length).Insert($match.Index, $replacement)
        }

        return $finalMessage
    }
}
function New-kvstring {
    [CmdletBinding()]
    param(
        [parameter(Mandatory, Position = 0)]
        [string]$message
    )
    process {
        # safety check
        if ($null -eq (Get-Command "kvinc" -ErrorAction SilentlyContinue)) {
            Write-Host "ckvstring: Missing dependency: kvinc"
            return 
        }

        $pattern = '\{((?<Level>prop|property|meta|metadata|confval|inf|err|wrn|api|git|value|type|key):)?kv:(?<Key>[^=]+)=(?<Value>.*?)\}'
        $finalMessage = $Message

        # Get all matches first
        $allMatches = [regex]::Matches($finalMessage, $pattern)

        # Process matches from right to left to avoid index shifting issues
        for ($i = $allMatches.Count - 1; $i -ge 0; $i--) {
            $match = $allMatches[$i]
            $Level = $match.Groups['Level'].Value.Trim()
            $key = $match.Groups['Key'].Value
            $value = $match.Groups['Value'].Value.Trim()

            if ([string]::IsNullOrEmpty($Level)) {
                $replacement = New-Kvinc -KeyName $key -KeyValue $value
            }
            else {
                $replacement = New-Kvinc -KeyName $key -KeyValue $value -Type $Level
            }
            
            $finalMessage = $finalMessage.Remove($match.Index, $match.Length).Insert($match.Index, $replacement)
        }

        return $finalMessage
    }
}

function New-Kvinc {
    [CmdletBinding()]
    param(
        [parameter(Mandatory, Position = 0)]
        [string]$keyName,

        [parameter(Mandatory, Position = 1)]
        [string]$KeyValue,

        [parameter(Mandatory = $false, Position = 2)]
        [ValidateSet(
            'inf',
            'err',
            'wrn',
            'prop',
            'property',
            'api',
            'git',
            'value',
            'type',
            'key',
            'meta',
            'metadata',
            'confval',
            'none'
        )]
        [string]$type
    )
    
    [string]$string = ''
    
    if (!$type) {
        $type = 'none'
    }

    $utility = @{
        kvinc_bracket_color  = "95"
        kvinc_bracket_format = ";1"
        kvinc_type_color     = "90"
        kvinc_type_format    = ";1"
        kvinc_key_color      = "94"
        kvinc_key_format     = ";1"
        kvinc_value_color    = "90"
        kvinc_value_format   = ";1"
    }
    
    if ($type -eq 'none') {
        
        $string += "`e[$($utility.kvinc_bracket_color)$($utility.kvinc_bracket_format)m{`e[0m"
      
        $string += " `e[$($utility.kvinc_key_color)$($utility.kvinc_key_format)m$keyName`e[0m"
        $string += " `e[$($utility.kvinc_bracket_color)$($utility.kvinc_bracket_format)m:`e[0m"
        $string += " `e[$($utility.kvinc_value_color)$($utility.kvinc_value_format)m$KeyValue`e[0m"
      
        $string += "`e[$($utility.kvinc_bracket_color)$($utility.kvinc_bracket_format)m }`e[0m"
      
        return $string.replace("^\{", "")
    
    }
    else {

        $string += "`e[$($utility.kvinc_bracket_color)$($utility.kvinc_bracket_format)m{`e[0m "

        switch ($type) {
            # NOTE: Add in more options
            'inf' { $string += "`e[37$($utility.kvinc_type_format)mINF`e[0m ≡" }
            'wrn' { $string += "`e[33$($utility.kvinc_type_format)mWRN`e[0m ≡" }
            'err' { $string += "`e[31$($utility.kvinc_type_format)mERR`e[0m ≡" }
            'prop' { $string += "`e[31$($utility.kvinc_type_format)mPROP`e[0m ≡" }
            'property' { $string += "`e[31$($utility.kvinc_type_format)mPROPERTY`e[0m ≡" }
            'api' { $string += "`e[31$($utility.kvinc_type_format)mAPI`e[0m ≡" } 
            'git' { $string += "`e[31$($utility.kvinc_type_format)mGIT`e[0m ≡" }
            'value' { $string += "`e[31$($utility.kvinc_type_format)mVALUE`e[0m ≡" }
            'key' { $string += "`e[31$($utility.kvinc_type_format)mKEY`e[0m ≡" }
            'type' { $string += "`e[31$($utility.kvinc_type_format)mTYPE`e[0m ≡" }
            'meta' { $string += "`e[31$($utility.kvinc_type_format)mMETA`e[0m ≡" }
            'metadata' { $string += "`e[31$($utility.kvinc_type_format)mMETADATA`e[0m ≡" }
            'confval' { $string += "`e[31$($utility.kvinc_type_format)mCONFVAL`e[0m ≡" }
            'none' { $string = "" }
            default {  }
        }
        $string += " `e[$($utility.kvinc_key_color)$($utility.kvinc_key_format)m$keyName`e[0m"
        $string += " `e[$($utility.kvinc_bracket_color)$($utility.kvinc_bracket_format)m:`e[0m"
        $string += " `e[$($utility.kvinc_value_color)$($utility.kvinc_value_format)m$KeyValue`e[0m"
       
        $string += " `e[$($utility.kvinc_bracket_color)$($utility.kvinc_bracket_format)m}`e[0m"

        return $string
    }
}

#! Requires kvinc, ckvstring
#! Requires kvinc, ckvstring
function Write-logr {
    [cmdletbinding()]
    [Alias('logr')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet( 
            'create',
            'read',
            'update',
            'delete',
            'push',
            'pull',
            'convert',
            'check',
            'config',
            'fetch',
            'request',
            'response',
            'patch',
            'build',
            'sticher',
            'compile',
            'astscan',
            'exc',
            'ast',
            'test',
            'lint',
            'format',
            'gitpull',
            'gitpush',
            'gitfetch',
            'gitclone',
            'gitmerge',
            'gitbranch',
            'success',
            'complete',
            'finished',
            'failed',
            'error',
            'warning',
            'info',
            'debug',
            'trace',
            'bootstrap',
            'gemparser',
            'action'
        )]
        [string]$Action,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateSet('err', 'inf', 'wrn', 'chk', 'api', 'git', 'exc', 'act')]
        [string]$Type,

        [Parameter(Mandatory = $false, Position = 3)]
        [string]$LogName = 'logr',

        [Parameter(Mandatory = $false)]
        [switch]$childLog,

        [Parameter(Mandatory = $false)]
        [string]$EmbeddedName,

        [Parameter(Mandatory = $false)]
        [validateSet('Standard', 'LongDate', 'logDate', 'ShortDate', 'FileName', 'logShort', 'logShortTime')]
        [string]$TimestampFormat
    )

    begin {
        function Format-DateTime {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [datetime]$DateTime,

                [Parameter(Mandatory = $true)]
                [validateSet(
                    'Standard',
                    'LongDate',
                    'logDate',
                    'ShortDate',
                    'FileName',
                    'logShort',
                    'logShortTime'
                )]
                [string]$FormatName
            )

            # Defined internally since it is no longer a class member
            $DateFormats = @{
                Standard     = 'yyyy-MM-dd HH:mm:ss'
                LongDate     = 'yyyy-MM-dd HH:mm:ss'
                logDate      = 'yy-MM-dd-HH:mm:ss'
                logShort     = 'MM-dd-HH:mm:ss'
                logShortTime = 'HH:mm:ss'
                ShortDate    = 'yyyy-MM-dd'
                FileName     = 'yyyyMMdd_HHmmss'
                # Add more formats as needed
            }

            if ($DateFormats.ContainsKey($FormatName)) {
                return $DateTime.ToString($DateFormats[$FormatName])
            }
            return $DateTime.ToString($FormatName)
        }
    }

    process {
        $utility = @{
            logr_logname_color        = "95"
            logr_logname_format       = ";1;2;3"
            logr_type_format          = ";1"
            logr_action_format        = ";1"
            logr_message_color        = "90"
            logr_message_format       = ";1"
            # Note- below color and format in same string
            logr_pointer              = "⇛"
            logr_pointer_format       = "90;1"
            logr_seperator            = "┊>"
            logr_seperator_format     = "90;1"
            logr_child_pointer        = ">"
            logr_child_pointer_format = ""
            logr_timestamp_format     = "90"
        }

        # Run Message Through kvstring and ctstring for
        # color and formatting
        $Message = New-Kvstring $Message
        $Message = New-Ctstring $Message
        
        # Build log message with ANSI colors
        # as minifore for created to be used with other others lets set a custom $EmbeddedName 
        # which we attach to the logname for better tracing if flagged

        [string] $logMessage = ''
        [string] $timestamp = ''

        if ($TimestampFormat) {
            $timestamp = (Format-DateTime -DateTime (Get-Date) -FormatName $TimestampFormat)

            $timestamp = switch ($TimestampFormat) {
                'Standard' { (Format-DateTime -DateTime (Get-Date) -FormatName $TimestampFormat) }
                'LongDate' { (Format-DateTime -DateTime (Get-Date) -FormatName $TimestampFormat) }
                'logDate' { (Format-DateTime -DateTime (Get-Date) -FormatName $TimestampFormat) }
                'ShortDate' { (Format-DateTime -DateTime (Get-Date) -FormatName $TimestampFormat) }
                'FileName' { (Format-DateTime -DateTime (Get-Date) -FormatName $TimestampFormat) }
                'logShort' { (Format-DateTime -DateTime (Get-Date) -FormatName $TimestampFormat) }
                'logShortTime' { (Format-DateTime -DateTime (Get-Date) -FormatName $TimestampFormat) }
            }
        }

        # Calulate the Timestamp length for child logging
        $timestampLength = $timestamp.Length

        if ($EmbeddedName -ne '' -and $TimestampFormat) {
            $logMessage += "[`e[$($utility.logr_timestamp_format)m$timestamp`e[0m] $EmbeddedName "
        }
        else {
            $logMessage += "$EmbeddedName "
        }

        if ($TimestampFormat -and -not $EmbeddedName) {
            $logMessage += "[`e[$($utility.logr_timestamp_format)m$timestamp`e[0m] "
        }

        $logMessage += "`e[$($utility.logr_logname_color)$($utility.logr_logname_format)m$LogName `e[0m"
        
        if (!$childLog) {
            $logMessage += "`e[$($utility.logr_pointer_format)m$($utility.logr_pointer) `e[0m"
            # Add type prefix with color
            # Use ASCII (ANSI) color codes for type prefix
            switch ($Type) {
                'err' { $logMessage += "`e[31$($utility.logr_type_format)merr`e[0m" }      # Red
                'inf' { $logMessage += "`e[37$($utility.logr_type_format)minf`e[0m" }      # Gray/White
                'wrn' { $logMessage += "`e[33$($utility.logr_type_format)mwrn`e[0m" }      # Yellow
                'chk' { $logMessage += "`e[36$($utility.logr_type_format)mchk`e[0m" }      # Cyan
                'api' { $logMessage += "`e[90$($utility.logr_type_format)mapi`e[0m" }      # Dark Gray
                'git' { $logMessage += "`e[94$($utility.logr_type_format)mgit`e[0m" }      # Light Blue
                'exc' { $logMessage += "`e[31$($utility.logr_type_format)mexc`e[0m" }      # Red
                'act' { $logMessage += "`e[32$($utility.logr_type_format)mact`e[0m" }      # Green
                'cpl' { $logMessage += "`e[32$($utility.logr_type_format)mcpl`e[0m" }      # 
                default {  }
            }
        }
        else {
            $logMessage += "$(" " * (5 + $timestampLength))"
        }

        # Add separator
        $logMessage += "`e[$($utility.logr_seperator_format)m$($utility.logr_seperator) `e[0m"
        
        # Add action with color using ASCII (ANSI) escape codes
        $logMessage += switch ($Action) {
            # --- STATUS BADGES (Background Colors) ---
            { $_ -in 'success', 'complete', 'completed', 'finished', 'done' } { 
                # Bg: Neon Green (46), Fg: Black (232) -> High Contrast Badge
                "`e[38;5;232;48;5;46m $Action `e[0m" 
            }
            { $_ -in 'failed', 'error', 'exc', 'exception', 'critical' } { 
                # Bg: Red (196), Fg: White (255) -> Alarm Badge
                "`e[38;5;255;48;5;196m $Action `e[0m" 
            }
            { $_ -in 'warning', 'wrn' } { 
                # Bg: Yellow (226), Fg: Black (232) -> Caution Badge
                "`e[38;5;232;48;5;226m $Action `e[0m" 
            }

            # --- CRUD (Foreground Colors) ---
            'create' { "`e[38;5;45mcreate`e[0m" }   # Bright Blue
            'read' { "`e[38;5;40mread`e[0m" }     # Green
            'update' { "`e[38;5;214mupdate`e[0m" }  # Orange/Gold
            'delete' { "`e[38;5;160mdelete`e[0m" }  # Deep Red

            # --- Extended CRUD ---
            'push' { "`e[38;5;27mpush`e[0m" }       # Deep Blue
            'pull' { "`e[38;5;129mpull`e[0m" }      # Purple

            # --- Git Actions (The "Git Brand" Orange) ---
            { $_ -like 'git*' } { 
                # Fg: Git Orange (202)
                "`e[38;5;202m$Action`e[0m" 
            }

            # --- Build / Compile (Industrial Colors) ---
            { $_ -in 'build', 'sticher', 'compile' } { 
                # Fg: Industrial Yellow/Orange (172)
                "`e[38;5;172m$Action`e[0m" 
            }
            
            # --- AST / Linting (Tech Teals) ---
            { $_ -in 'astscan', 'astcheck', 'ast', 'lint', 'format', 'test' } { 
                # Fg: Cyan/Teal (51)
                "`e[38;5;51m$Action`e[0m" 
            }

            # --- API Actions (Distinct Pastels) ---
            'fetch' { "`e[38;5;157mfetch`e[0m" }    # Pale Green
            'request' { "`e[38;5;229mrequest`e[0m" }  # Pale Yellow
            'response' { "`e[38;5;203mresponse`e[0m" } # Pale Red
            'patch' { "`e[38;5;213mpatch`e[0m" }    # Pink

            # --- Other Actions ---
            'convert' { "`e[38;5;242mconvert`e[0m" } # Grey
            'config' { "`e[38;5;111mconfig`e[0m" }  # Sky Blue
            'check' { "`e[38;5;255mcheck`e[0m" }   # Bright White
            'action' { "`e[38;5;105maction`e[0m" }   # Light Blue

            # --- Logging Levels ---
            'info' { "`e[38;5;39minfo`e[0m" }     # Dodger Blue
            'debug' { "`e[38;5;245mdebug`e[0m" }   # Light Grey
            'trace' { "`e[38;5;239mtrace`e[0m" }   # Dark Grey

            # --- Ruby Gems ---
            'gemparser' { "`e[38;5;202mgemparser`e[0m" } # Orange


            default {
                logr "Unknown action type '$Action' provided for logging." 'logr' 'err' $LogName $EmbeddedName
                return
            }
        }
        $childMessage_Type = switch ($Type) {
            'err' { "`e[31$($utility.logr_type_format)merr`e[0m" }      # Red
            'inf' { "`e[37$($utility.logr_type_format)minf`e[0m" }      # Gray/White
            'wrn' { "`e[33$($utility.logr_type_format)mwrn`e[0m" }      # Yellow
            'chk' { "`e[36$($utility.logr_type_format)mchk`e[0m" }      # Cyan
            'api' { "`e[90$($utility.logr_type_format)mapi`e[0m" }      # Dark Gray
            'git' { "`e[94$($utility.logr_type_format)mgit`e[0m" }      # Light Blue
            'exc' { "`e[31$($utility.logr_type_format)mexc`e[0m" }      # Red
            'act' { "`e[32$($utility.logr_type_format)mact`e[0m" }      # Green
            'cpl' { "`e[32$($utility.logr_type_format)mcpl`e[0m" }      # Green
            default {  }
        }
        $logMessage += "`e[$($utility.logr_seperator_format)m$($utility.logr_seperator) `e[0m"
        # Add message
        if ($childLog) {
            $logMessage += "$childMessage_Type `e[$($utility.logr_message_color)$($utility.logr_message_format)m$Message`e[0m "
        }
        else {
            $logMessage += "`e[$($utility.logr_message_color)$($utility.logr_message_format)m$Message`e[0m"
        }

        if ($global:__logging -or $script:__logging -or $verbose -or $log) {
            [System.Console]::WriteLine($logMessage)
        }
    }
}
# -----------------------------------------------------------------------------
# Controller Function
# -----------------------------------------------------------------------------

function Invoke-GemCommander {
    <#
    .SYNOPSIS
        The central controller for GemCommander operations.
    .EXAMPLE
        Invoke-GCom -Command Build -Path ".\build_config.json"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Build", "Publish", "Find", "Verify", "Template", "Install", "Env")]
        [string]$Command,

        [Parameter(ValueFromPipeline = $true)]
        [object]$InputObject,

        [string]$Path,
        [string]$Name,
        [string]$Source,
        [string]$ApiKey,
        [string]$TemplateType = "Compact" # Options: Full, Compact, Minimal
    )
    begin {
        if (-not (Test-Path $Path)) { 
            logr "Path '{ct:red:u:$Path}' does not exist." 'error' 'err'
            return 
        }
    }
    process {
        switch ($Command) {
            "Build" { Invoke-GemBuild -ConfigPath $Path }
            "Publish" { Publish-RubyGem -GemPath $Path -Source $Source -ApiKey $ApiKey }
            "Find" { Find-RubyGem -Name $Name }
            "Verify" { Test-Gemspec -Path $Path }
            "Template" { New-GemspecTemplate -Path $Path -Type $TemplateType }
            "Install" { Install-RubyGem -Name $Name -Version $InputObject }
            "Env" { Get-GemEnvironment }
        }
    }
}

# -----------------------------------------------------------------------------
# Lifecycle Functions
# -----------------------------------------------------------------------------

function Invoke-GemBuild {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath,
        [string]$OutputDirectory = "$PWD"
    )

    logr 'Building Ruby Gem...' 'build' 'info'
    $RequiredProperties = @('name', 'version', 'authors', 'email', 'summary', 'homepage', 'files')

    if (-not (Test-Path $ConfigPath)) { 
        logr "Config file {ct:yellow:u:$ConfigPath} not found." 'error' 'err' -ChildLog
        return;
    }

    try { $JsonConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json }
    catch {
        logr "Failed to parse config file {ct:yellow:u:$ConfigPath}." 'error' 'err' -ChildLog
        return;
    }

    $Missing = $RequiredProperties | Where-Object { $null -eq $JsonConfig.GemCommander.$_ }
    if ($Missing) { 
        logr "Missing config properties: {prop:kv:missing=$($Missing -join ', ')}" 'error' 'err' -ChildLog
        return;
    }

    # Format files for Ruby array syntax
    $FileList = $JsonConfig.GemCommander.files | ForEach-Object { "'$_'" }
    $FileListStr = $FileList -join ", "

    # Use SemVer Auto-Version
    if ($JsonConfig.GemCommander.prerelease) {
        $version = "$((Get-GitAutoVersion).Version)-$($JsonConfig.GemCommander.prerelease)"
        $script:SemVer = $version
    }else{
        $script:SemVer = $version
        $version = (Get-GitAutoVersion).Version
    }

    logr "Generating Semantic Version {kv:ref:version=$version}" 'info' 'inf' -ChildLog

    $GemspecContent = @"
Gem::Specification.new do |s|
  s.name        = '$($JsonConfig.GemCommander.name)'
  s.version     = '$version
  s.authors     = ['$($JsonConfig.GemCommander.authors)']
  s.email       = '$($JsonConfig.GemCommander.email)'
  s.summary     = '$($JsonConfig.GemCommander.summary)'
  s.homepage    = '$($JsonConfig.GemCommander.homepage)'
  s.files       = [$FileListStr]
  s.license     = '$($JsonConfig.GemCommander.license)'
  s.description = '$($JsonConfig.GemCommander.description)'
end
"@

    $GemspecFile = Join-Path $OutputDirectory "$($JsonConfig.GemCommander.name).gemspec"
    Set-Content -Path $GemspecFile -Value $GemspecContent -Encoding UTF8
    logr "Generated: {kv:GemFile=$GemspecFile}" 'info' 'inf' -ChildLog

    try {
        logr "Building Ruby Gem..." 'build' 'info' -ChildLog
        [console]::writeline("------------------------------`n") 
        & gem build $GemspecFile
        [console]::writeline("`n------------------------------") 
    }catch {
        logr "Failed to build Ruby Gem." 'error' 'err' -ChildLog
    }

    logr 'Done' 'build' 'info'
}

function Publish-RubyGem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$GemPath,
        [string]$Source,
        [string]$ApiKey
    )

    logr "Pushing Ruby Gem..." 'push' 'info'
    if (-not (Test-Path $GemPath)) { Write-Error "Gem '$GemPath' not found."; return }
    
    $MetaData = @("push", $GemPath)
    if ($Source) { $MetaData += "--host"; $MetaData += $Source }
    if ($ApiKey) { $MetaData += "--key"; $MetaData += $ApiKey }

    logr "Pushing {kv:GemFilePath=$GemPath} to {kv:Source=$Source} with {kv:version=$script:SemVer}" 'push' 'info' -ChildLog
    [console]::writeline("------------------------------`n")
    & gem $MetaData
    [console]::writeline("`n------------------------------") 
}

function Find-RubyGem {
    [CmdletBinding()]
    param ([string]$Name, [switch]$Local)
    
    logr "Initiate Ruby Gem Search..." 'search' 'info'
    logr "Searching for Ruby Gem {ct:75:u:$Name} {kv:Local=$Local}" 'search' 'info'
    $MetaData = @("search", $Name)
    if ($Local) { $MetaData += "--local" } else { $MetaData += "--remote" }
    [console]::writeline("------------------------------`n")
    & gem $MetaData
    [console]::writeline("`n------------------------------") 
}

# -----------------------------------------------------------------------------
# Validation & Templates
# -----------------------------------------------------------------------------

function Test-Gemspec {
    <#
    .SYNOPSIS
        Validates a .gemspec file syntax and dependencies.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    logr "Validating Ruby Gemspec..."

    if (-not (Test-Path $Path)) { logr "Path '{ct:red:u:$Path}' does not exist." 'error' 'err' -ChildLog; return }

    logr "Validating $Path..." 'check' 'chk' -ChildLog
    
    # We use 'gem spec' which tries to parse the spec and output it.
    # If it fails, the gemspec is invalid.
    $Result = & gem spec $Path --ruby 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        logr "Gemspec is valid." 'success' 'info' -ChildLog
        return $true
    }
    else {
        logr "Gemspec is invalid." 'error' 'err' -ChildLog
        logr "$Result" 'error' 'error' -ChildLog
        return $false
    }
}

function New-GemspecTemplate {
    <#
    .SYNOPSIS
        Generates a .gemspec template.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [ValidateSet("Full", "Compact", "Minimal")]
        [string]$Type = "Compact"
    )

    $Content = ""

    if ($Type -eq "Minimal") {
        $Content = @"
Gem::Specification.new do |s|
  s.name        = 'my-gem'
  s.version     = '0.0.1'
  s.summary     = 'Short summary'
  s.authors     = ['Author Name']
  s.files       = ['lib/my_gem.rb']
end
"@
    }
    elseif ($Type -eq "Compact") {
        $Content = @"
Gem::Specification.new do |s|
  s.name        = 'my-gem'
  s.version     = '0.0.1'
  s.summary     = 'A short summary of this gem'
  s.description = 'A longer description of what this gem does.'
  s.authors     = ['Author Name']
  s.email       = 'email@example.com'
  s.homepage    = 'http://github.com/user/my-gem'
  s.license     = 'MIT'
  s.files       = Dir['lib/**/*.rb']
end
"@
    }
    else {
        # Full
        $Content = @"
# This is a full gemspec template with comments explaining options
Gem::Specification.new do |s|
  # Basic Info
  s.name        = 'my-gem'
  s.version     = '0.0.1'
  s.summary     = 'A brief summary'
  s.description = 'A detailed description of the gem.'
  s.license     = 'MIT'

  # Contact
  s.authors     = ['Author Name']
  s.email       = 'email@example.com'
  s.homepage    = 'http://your-site.com'

  # Platform (usually strictly ruby, or java for JRuby)
  s.platform    = Gem::Platform::RUBY

  # Files
  # It is common to use git ls-files or Dir globbing
  s.files       = Dir['lib/**/*', 'README.md', 'LICENSE']
  s.test_files  = Dir['test/**/*_test.rb']
  
  # Dependencies
  # runtime: needed to run the code
  # development: needed only for testing/building
  # s.add_runtime_dependency 'rails', '> 5.0'
  # s.add_development_dependency 'rspec', '~> 3.0'
end
"@
    }

    $OutFile = if ($Path.EndsWith(".gemspec")) { $Path } else { Join-Path $Path "template.gemspec" }
    Set-Content -Path $OutFile -Value $Content -Encoding UTF8
    logr "Generated: {ct:green:u:$Type} {kv:GemFile=$OutFile}" 'complete' 'inf' -ChildLog
}

# -----------------------------------------------------------------------------
# Admin Helpers
# -----------------------------------------------------------------------------

function Install-RubyGem {
    <#
    .SYNOPSIS
        Installs a gem.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Version
    )

    $MetaData = @("install", $Name)
    if ($Version) { $MetaData += "-v"; $MetaData += $Version }
    
    Write-Host "Installing $Name..." -ForegroundColor Cyan
    & gem $MetaData
}

function Get-GemEnvironment {
    <#
    .SYNOPSIS
        Displays the current Ruby Gem environment details.
    #>
    [CmdletBinding()]
    param()
    & gem env
}

$module_config = @{
    function = @(
        'Invoke-GemCommander', 
        'Invoke-GemBuild', 
        'Publish-RubyGem', 
        'Find-RubyGem', 
        'Test-Gemspec', 
        'New-GemspecTemplate', 
        'Install-RubyGem', 
        'Get-GemEnvironment'
    )
    alias = @(

    )
}

# Export Functions
Export-ModuleMember @module_config