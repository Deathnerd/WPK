function Register-PowerShellCommand {
    <#
    .Synopsis
        Registers a PowerShell scriptblock command for use within a window
    .Description
        Registers a PowerShell scriptblock for use within a window.
        The command can be run registered for one time use,
        it can register anonymously, and it can register for use
        at a regular interval.
    .Parameter Name
        The name of the PowerShell command
    .Parameter ScriptBlock
        The script block to run
    .Parameter In
        The repeat interval of the command.
    .Parameter Run
        If set, will start running the command as
        soon as it is registered
    .Parameter Once
        If set, will only run the command once
    .Example
New-Label "$($d = Get-Date ;$d.ToLongDateString() + ' ' + $d.ToLongTimeString())" `
    -FontSize 24 -SizeToContent WidthAndHeight `
    -On_Loaded {
        Register-PowerShellCommand -scriptBlock {
            $d = Get-Date
            $content = $d.ToLongDateString() + " " + $d.ToLongTimeString()
            $window.Content.Content = $content
        } -run -in "0:0:0.5"
    } -AsJob
    #>
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Name = ((New-Guid).ToString()),
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Definition')]
        [ScriptBlock]$ScriptBlock,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Timespan]$In = ([Timespan]0),
        [switch]$Run,
        [switch]$Once
    )
    process {
        $visual = $this
        if ($window) {
            if ($once) {
                $window.Resources.Scripts.$Name = [ScriptBlock]::Create(
                    "$scriptBlock`n" + { Unregister-PowerShellCommand } + " '$Name'"
                )
            }
            else {
                $window.Resources.Scripts.$Name = $scriptBlock
            }
            if ($run) {
                Start-PowerShellCommand $Name -interval $in
            }
        }
    }
}