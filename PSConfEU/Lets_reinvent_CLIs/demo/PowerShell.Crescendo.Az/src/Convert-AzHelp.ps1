[CmdletBinding(DefaultParameterSetName="Default")]
param ( [Parameter(Mandatory=$true,ParameterSetName="file")]$file, [Parameter(ParameterSetName="file")][switch]$Generate, [Parameter(ParameterSetName="file")][switch]$force )
$exe = "az"
$globalHelpChar = "--help"
$commandPattern = "(^Subgroups:)|(^Commands:)"
$usagePattern = "^Command\v*(?<usage>.*)"
$optionPattern = "^Arguments"
$argumentPattern = "Global Arguments"
$headerLength = 0
$linkPattern = "^More help can be found at: (?<link>.*)"
$parmPattern = "--(?<pname>[-\w]+)\s(?<ptype>\w+)\s+(?<phelp>.*)|--(?<pname>[-\w]+)\s+(?<phelp>.*)"

class ParsedHelpCommand {
    [string]$exe
    [string[]]$commandElements
    [string]$Verb
    [string]$Noun
    [cParameter[]]$Parameters
    [string]$Usage
    [string[]]$Help
    [string]$Link
    [string[]]$OriginalHelptext

    [object]GetCrescendoCommand() {
        $c = New-CrescendoCommand -Verb $this.Verb -Noun $this.Noun -originalname $this.exe
        #$c.Usage = New-UsageInfo -usage $this.Usage
        if ( $this.CommandElements ) {
            $c.OriginalCommandElements = $this.commandElements | foreach-object {$_}
        }
        $c.Platform = "Windows","Linux","MacOs"
        $c.OriginalText = $this.OriginalHelptext -join "`n"
        $c.Description = $this.Help -join "`n"
        $c.HelpLinks = $this.Link
        foreach ( $p in $this.Parameters) {
            $parm = New-ParameterInfo -name $p.Name -originalName $p.OriginalName
            $parm.Description = $p.Help
            if ( $p.Position -ne [int]::MaxValue ) {
                $parm.Position = $p.Position
            }
            if ( $p.ParameterType ) {
                $parm.ParameterType = $p.ParameterType
            }
            $parm.OriginalText = $p.OriginalText
            $c.Parameters.Add($parm)
        }
        return $c
    }
    [string]GetCrescendoJson() {
        return $this.GetCrescendoCommand().GetCrescendoConfiguration()
    }
    [string]GetNoun() {
        $segments = .{ $exe.Split("-"); $commandProlog.Foreach({$_.split("-")}) } | ForEach-Object { [char]::ToUpper($_.substring(0,1)) + $_.substring(1) }
        return ($segments -join "")
    }
}

class cParameter {
    [string]$Name
    [string]$OriginalName
    [string]$OriginalText
    [string]$Help
    [string]$ParameterType
    [int]$Position = [int]::MaxValue
    cParameter([string]$name, [string]$originalName, [string]$help) {
        $this.Name = $name
        $this.OriginalName = $originalName
        $this.Help = $help
    }
}

function parseHelp([string]$exe, [string[]]$commandProlog, [string]$helpChar = $globalHelpChar) {
    write-progress ("parsing help for '$exe " + ($commandProlog -join " ") + "'")
    if ( $commandProlog ) {
        $helpText = & $exe $commandProlog $helpChar
    }
    else {
        $helpText = & $exe $helpChar
    }
    $offset = $headerLength
    $cmdhelp = @()
    while ( $helpText[$offset] -ne "") {
        $cmdhelp += $helpText[$offset++]
    }
    #$cmdHelpString = $cmdhelp -join " "
    $parameters = @()
    $usage = ""
    for($i = $offset; $i -lt $helpText.Count; $i++) {
        if ($helpText[$i] -match $usagePattern) {
            $usage = $matches['usage']
        }
        elseif ($helpText[$i] -match $linkPattern ) {
            $link = $matches['link']
        }
        elseif ($helpText[$i] -match $optionPattern) {
            $i++
            while($helpText[$i] -ne "" -and $i -lt $helpText.Count) {
                if ($helpText[$i] -match $parmPattern) {
                    #wait-debugger
                    $originalName = "--" + $matches['pname']
                    $pHelp = $matches['phelp']
                    $pName = $originalName -replace "[- ]"
                    $p = [cParameter]::new($pName, $originalName, $pHelp)
                    $p.OriginalText = $helpText[$i]
                    if ( $matches['ptype'] ) {
                        $pType = $matches['ptype']
                        if ( $pType -match "list|strings|stringarray" ) { $pType = "string[]" }
                        $p.ParameterType = $pType
                    }
                    else {
                        $p.ParameterType = "switch"
                    }
                    $parameters += $p
                }
                $i++
            }
        }
        elseif ($helpText[$i] -match $argumentPattern) {
            $i++
            while($helpText[$i] -ne "" -and $i -lt $helpText.Count) {
                if ($helpText[$i] -match $parmPattern) {
                    $originalName = "--" + $matches['pname']
                    $pHelp = $matches['phelp']
                    $pName = $originalName -replace "[- ]"
                    $p = [cParameter]::new($pName, $originalName, $pHelp)
                    $parameters += $p
                }
                $i++
            }
        }
        elseif ($helpText[$i] -match $commandPattern) {
            $i++
            while($helpText[$i] -ne "" -and $i -lt $helpText.Count) {
                $t = $helpText[$i].Trim().Replace('*','') # specific for docker
                $subCommand, $subHelp = $t.split(" ",2, [System.StringSplitOptions]::RemoveEmptyEntries)
                $helpi = 0;$morehelp=$false
                $helpbegin = $t.indexof($subHelp)
                while($helpText[$i + $helpi +1] -match " {$helpbegin}\S") {
                    $subHelp += " " + $helpText[$i+ ++$helpi]
                    $morehelp=$true
                }
                if($morehelp) {
                    $i= $i+$helpi
                }
                #write-host ">>> $subCommand"
                if ( $subCommand -eq "help" ) {
                    $i++
                    continue
                }
                $cPro = $commandProlog
                $cPro += $subCommand
                # we have a sub-command, so we should resolve its components
                # by calling the parseHelp function recursively.
                # There is a small risk of stack overflow here, but PowerShell's
                # stack should be deep enough
                parseHelp -exe $exe -commandProlog $cPro
                $i++
            }
        }
    }
    # construct our interim object
    # this allows us to organize the help before converting it
    # to a crescendo command
    $c = [parsedhelpcommand]::new()
    $c.exe = $exe
    $c.commandElements = $commandProlog
    $c.Verb = "Invoke"
    $c.Noun = $c.GetNoun()
    $c.Parameters = $parameters
    $c.Usage = $usage
    $c.Help = $cmdhelp
    $c.Link = $link
    $c.OriginalHelptext = $helpText
    $c
}

$commands = parseHelp -exe $exe -commandProlog @() -helpChar help | ForEach-Object { $_.GetCrescendoCommand()}
$dockerConfig = $commands.Where({$_.OriginalCommandElements.Count -eq 0})
$exeParms = $dockerConfig.Parameters.ForEach({$_.ApplyToExecutable = $true;$_})
# docker only shows the global options for `docker --help`
# here we add them to all the other commands
$commands.Where({$_.OriginalCommandElements.Count -ne 0}).ForEach({
    $c = $_
    $exeParms.Foreach({$c.Parameters.Add($_)})
})

# we can create the complete configuration file this way
$h = [ordered]@{
    '$schema' = 'https://aka.ms/PowerShell/Crescendo/Schemas/2021-11'
    'Commands' = $commands
}

if ( ! $Generate ) {
    $h
    return
}

$sOptions = [System.Text.Json.JsonSerializerOptions]::new()
$sOptions.WriteIndented = $true
$sOptions.MaxDepth = 20
$sOptions.IgnoreNullValues = $true

$parsedConfig = [System.Text.Json.JsonSerializer]::Serialize($h, $sOptions)

if ( $file ) {
    if (test-path $file) {
        if ($force) {
            $parsedConfig > $file
        }
        else {
            Write-Error "'$file' exists, use '-force' to overwrite"
        }
    }
    else {
        $parsedConfig > $file
    }
}
else {
    $parsedConfig
}
