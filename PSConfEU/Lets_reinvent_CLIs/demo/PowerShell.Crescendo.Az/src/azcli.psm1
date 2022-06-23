# Module created by Microsoft.PowerShell.Crescendo
class PowerShellCustomFunctionAttribute : System.Attribute { 
    [bool]$RequiresElevation
    [string]$Source
    PowerShellCustomFunctionAttribute() { $this.RequiresElevation = $false; $this.Source = "Microsoft.PowerShell.Crescendo" }
    PowerShellCustomFunctionAttribute([bool]$rElevation) {
        $this.RequiresElevation = $rElevation
        $this.Source = "Microsoft.PowerShell.Crescendo"
    }
}



function get-AzCliAccount
{
[PowerShellCustomFunctionAttribute(RequiresElevation=$False)]
[CmdletBinding()]

param(
[Parameter()]
[string]$all,
[Parameter()]
[string]$refresh,
[Parameter()]
[string]$onlyshowerror,
[Parameter()]
[string]$output,
[Parameter()]
[string]$query
    )

BEGIN {
    $__PARAMETERMAP = @{
         all = @{
               OriginalName = '--all'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         refresh = @{
               OriginalName = '--refresh'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         onlyshowerror = @{
               OriginalName = '--only-show-error'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         output = @{
               OriginalName = '--output'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
         query = @{
               OriginalName = '--query'
               OriginalPosition = '0'
               Position = '2147483647'
               ParameterType = 'string'
               ApplyToExecutable = $False
               NoGap = $False
               }
    }

    $__outputHandlers = @{
        Default = @{ StreamOutput = $False; Handler = { $args[0] | out-string | ConvertFrom-Json } }
    }
}

PROCESS {
    $__boundParameters = $PSBoundParameters
    $__defaultValueParameters = $PSCmdlet.MyInvocation.MyCommand.Parameters.Values.Where({$_.Attributes.Where({$_.TypeId.Name -eq "PSDefaultValueAttribute"})}).Name
    $__defaultValueParameters.Where({ !$__boundParameters["$_"] }).ForEach({$__boundParameters["$_"] = get-variable -value $_})
    $__commandArgs = @()
    $MyInvocation.MyCommand.Parameters.Values.Where({$_.SwitchParameter -and $_.Name -notmatch "Debug|Whatif|Confirm|Verbose" -and ! $__boundParameters[$_.Name]}).ForEach({$__boundParameters[$_.Name] = [switch]::new($false)})
    if ($__boundParameters["Debug"]){wait-debugger}
    $__commandArgs += 'account'
    $__commandArgs += 'list'
    foreach ($paramName in $__boundParameters.Keys|
            Where-Object {!$__PARAMETERMAP[$_].ApplyToExecutable}|
            Sort-Object {$__PARAMETERMAP[$_].OriginalPosition}) {
        $value = $__boundParameters[$paramName]
        $param = $__PARAMETERMAP[$paramName]
        if ($param) {
            if ($value -is [switch]) {
                 if ($value.IsPresent) {
                     if ($param.OriginalName) { $__commandArgs += $param.OriginalName }
                 }
                 elseif ($param.DefaultMissingValue) { $__commandArgs += $param.DefaultMissingValue }
            }
            elseif ( $param.NoGap ) {
                $pFmt = "{0}{1}"
                if($value -match "\s") { $pFmt = "{0}""{1}""" }
                $__commandArgs += $pFmt -f $param.OriginalName, $value
            }
            else {
                if($param.OriginalName) { $__commandArgs += $param.OriginalName }
                $__commandArgs += $value | Foreach-Object {$_}
            }
        }
    }
    $__commandArgs = $__commandArgs | Where-Object {$_ -ne $null}
    if ($__boundParameters["Debug"]){wait-debugger}
    if ( $__boundParameters["Verbose"]) {
         Write-Verbose -Verbose -Message az
         $__commandArgs | Write-Verbose -Verbose
    }
    $__handlerInfo = $__outputHandlers[$PSCmdlet.ParameterSetName]
    if (! $__handlerInfo ) {
        $__handlerInfo = $__outputHandlers["Default"] # Guaranteed to be present
    }
    $__handler = $__handlerInfo.Handler
    if ( $PSCmdlet.ShouldProcess("az $__commandArgs")) {
    # check for the application and throw if it cannot be found
        if ( -not (Get-Command -ErrorAction Ignore "az")) {
          throw "Cannot find executable 'az'"
        }
        if ( $__handlerInfo.StreamOutput ) {
            & "az" $__commandArgs | & $__handler
        }
        else {
            $result = & "az" $__commandArgs
            & $__handler $result
        }
    }
  } # end PROCESS

<#


.DESCRIPTION
Get a list of subscriptions for the logged in account. By default, only

.PARAMETER all
List all subscriptions from all clouds, rather than just 'Enabled' ones.


.PARAMETER refresh
Retrieve up-to-date subscriptions from server.


.PARAMETER onlyshowerror
Only show errors, suppressing warnings.


.PARAMETER output
Output format.  Allowed values: json, jsonc, none, table, tsv, yaml, yamlc.Default: json.


.PARAMETER query
JMESPath query string. See http://jmespath.org/ for more information andexamples.



#>
}


