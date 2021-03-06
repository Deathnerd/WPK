function ConvertFrom-TypeToScriptCmdlet {
    <#
    .Synopsis
        Converts .NET Types into Windows PowerShell Script Cmdlets
        according to a number of rules. that have been added with Add-CodeGeneration rule
    .Description
        Converts .NET Types into Windows PowerShell Script Cmdlets
        according to a number of rules.

        Rules are added with Add-CodeGenerationRule

    .Example
        An example of using the command
    #>
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Type[]]$Type,

        [Hashtable]$Rules
    )

    begin {
        $LinkedListType = "Collections.Generic.LinkedList"
        Set-StrictMode -Off
    }

    process {
        if (-not $rules) {
            $Rules = $Script:CodeGenerationCustomizations
        }

        foreach ($t in $type) {
            $Parameters = New-Object "$LinkedListType[Management.Automation.ParameterMetaData]"
            $BeginBlocks = New-Object "$LinkedListType[ScriptBlock]"
            $ProcessBlocks = New-Object "$LinkedListType[ScriptBlock]"
            $EndBlocks = New-Object "$LinkedListType[ScriptBlock]"
            # if ($PSVersionTable.BuildVersion.Build -lt 7100) {
            $CmdletBinding = "[CmdletBinding()]"
            # }
            # else {
                # $CmdletBinding = ""
            # }
            $Verb = ""
            $Noun = ""
            $Help = @{
                Parameter = @{}
            }
            $BaseType = $t
            try {
                foreach ($rule in $CodeGenerationRuleOrder) {
                    if (-not $rule) { continue }
                    if ($rule -is [Type] -and
                        (($t -eq $rule) -or ($t.IsSubclassOf($rule)))) {
                        $null = . $rules.$rule
                    }
                    else {
                        if ($rule -is [ScriptBlock] -and
                            ($t | Where-Object -FilterScript $rule)) {
                            $null = . $rules.$rule
                        }
                    }
                }
            }
            catch {
                Write-Error "Problem building $t"
                Write-Error $_
            }

            if ((-not $Noun) -or (-not $Verb)) {
                continue
            }
            $cmd = New-Object Management.Automation.CommandMetaData ([PSObject])
            foreach ($p in $parameters) {
                $null = $cmd.Parameters.Add($p.Name, $p)
            }
            $parameterBlock = [Management.Automation.ProxyCommand]::GetParamBlock($cmd)
            $oldOfs = $ofs
            $ofs = ""
            $helpBlock = New-Object Text.StringBuilder
            $parameterNames = "Parameter",
            "ForwardHelpTargetName",
            "ForwardHelpCategory",
            "RemoteHelpRunspace",
            "ExternalHelp",
            "Synopsis",
            "Description",
            "Notes",
            "Link",
            "Example",
            "Inputs",
            "Outputs",
            "Component",
            "Role",
            "Functionality"
            if ($help.Synopsis -and $help.Description) {
                foreach ($key in $help.Keys) {
                    if ($parameterNames -notcontains $key) {
                        Write-Error "Could not generate help for $t.  The Help dictionary contained a key ($key) that is not a valid help section"
                        break
                    }
                }
                foreach ($kv in $help.GetEnumerator()) {
                    switch ($kv.Key) {
                        Parameter {
                            foreach ($p in $kv.Value.GetEnumerator()) {
                                if (-not $p) { continue }
                                $null = $helpBlock.Append(
                                    "
    .Parameter $($p.Key)
        $($p.Value)")
                            }
                        }
                        Example {
                            foreach ($ex in $kv.Value) {
                                $null = $helpBlock.Append(
                                    "
    .Example
        $ex")

                            }
                        }
                        default {
                            $null = $helpBlock.Append(
                                "
    .$($kv.Key)
        $($kv.Value)")
                        }
                    }
                }
            }
            $helpBlock = "$helpBlock"
            if ($helpBlock) {
                $helpBlock = "
    <#
    $HelpBlock
    #>
"
            }
            @"
function $Verb-$Noun {
    $HelpBlock

    $CmdletBinding
    param(
        $parameterBlock
    )
    begin {
        $BeginBlocks
    }
    process {
        $ProcessBlocks
    }
    end {
        $EndBlocks
    }
}
"@
        }
    }
}