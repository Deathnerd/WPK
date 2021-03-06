function Get-ReferencedCommand {
    <#
    .Synopsis
        Gets the commands referred to from within a function or external script
    .Description
        Uses the Tokenizer to get the commands referred to from within a function or external script
    .Example
        Get-Command New-Button | Get-ReferencedCommand
    #>
    param(
        # The script block to search for command references
        [Parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $true)]
        [ScriptBlock] $ScriptBlock
    )

    begin {
        if (-not ('WPK.GetReferencedCommand' -as [Type])) {
            Add-Type -IgnoreWarnings -TypeDefinition ((Get-Content (Join-Path $PSScriptRoot "GetReferencedCommand.cs")) -join "`n") -Language CSharp
        }
        $commandsEncountered = @{}
    }
    process {
        [WPK.GetReferencedCommand]::GetReferencedCommands($ScriptBlock, $PSCmdlet)
    }
}