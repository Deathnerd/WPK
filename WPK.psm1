try {
    $Assemblies = [Reflection.Assembly]::LoadWithPartialName("WindowsBase"),
        [Reflection.Assembly]::LoadWithPartialName("PresentationFramework"),
        [Reflection.Assembly]::LoadWithPartialName("PresentationCore"),
        [Reflection.Assembly]::Load("WindowsFormsIntegration, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35")
} catch {
    throw $_
}

$script:Functions = Get-ChildItem -File (Join-Path $PSScriptRoot "Functions") -Filter "*.ps1" | ForEach-Object {
    . $_.FullPath
    $_.BaseName
}

$script:GeneratedControlsDir = Join-Path $PSscriptRoot "GeneratedControls"
$script:RulesDir = Join-Path $PSScriptRoot "Rules"

# Import the individual rules
Join-Path $script:RulesDir "*.ps1" -Resolve | ForEach-Object {
    . $_.FullName
}

$Scripts = Get-ChildItem $script:GeneratedControlsDir -ErrorAction SilentlyContinue -Filter *.ps1

if (-not $Scripts) {
    # Create the controls directory
    New-Item -Path $script:GeneratedControlsDir -Type Directory -ErrorAction SilentlyContinue | Out-Null

    $Assemblies | Where-Object { $_ } | ForEach-Object {
        $path = Join-Path $script:GeneratedControlsDir "$($_.GetName().Name).ps1"
        $TypesToConvert = $_.GetTypes() | Where-Object { $_.IsPublic -and -not $_.IsGenericType -and $_.FullName -notlike "*Internal*" }
        $Results = $TypesToConvert | ConvertFrom-TypeToScriptCmdlet -ErrorAction SilentlyContinue
        [IO.File]::WriteAllText($Path, $Results)
    }

    $Scripts = Get-ChildItem $script:GeneratedControlsDir -ErrorAction SilentlyContinue -Filter *.ps1
}

# Import the scritpts directory
foreach ($s in $scripts) {
    . $s.FullName
}

foreach ($s in Get-ChildItem $psScriptRoot\Controls -Filter *.ps1 `
    -ErrorAction SilentlyContinue) {
    if (-not $s) { continue }
    . $s.FullName
}

Export-ModuleMember -Function $script:Functions