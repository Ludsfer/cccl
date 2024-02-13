[CmdletBinding()] param (
    [switch]
    $ClearExceptions
)

$ErrorActionPreference = 'Stop'

$extensionList=".cpp,.h,.hpp,.c,.cu,.cuh,.i,.ii,.o,.obj,.cubin,.ptx,.py"
$processList="cmake.exe,ninja.exe,python.exe,lit.exe,nvcc.exe,ptxas.exe,cicc.exe,cudafe++.exe,cl.exe,link.exe,lib.exe,sccache.exe"
$pathList="$ENV:ProgramData\docker"
$shell=[Diagnostics.Process]::GetCurrentProcess().Path

function Get-AdminPrompt {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    return $isAdmin
}

function Set-DefenderExceptions {
    Write-Verbose "Setting up AV exceptions - Do not forget to clear with Clear-DefenderExceptions"

    Write-Verbose "Excluding extensions: $extensionList"
    Add-MpPreference -ExclusionExtension $extensionList
    Write-Verbose "Excluding processes: $processList"
    Add-MpPreference -ExclusionProcess $processList
    Write-Verbose "Excluding paths: $pathList"
    Add-MpPreference -ExclusionPath $pathList
}

function Clear-DefenderExceptions {
    Write-Output "Tearing down AV exceptions"

    Write-Verbose "Removing extension exclusions: $extensionList"
    Remove-MpPreference -ExclusionExtension $extensionList
    Write-Verbose "Removing process exclusions: $processList"
    Remove-MpPreference -ExclusionProcess $processList
    Write-Verbose "Removing path exclusions: $pathList"
    Remove-MpPreference -ExclusionPath $pathList
}

if (! (Get-AdminPrompt)) {
    Write-Warning "AV Exceptions are settable only with administrative rights. Elevating."
    $elevatedCommand = @"
& {
    $PSCommandPath -ClearExceptions:`$$ClearExceptions -Verbose
    Start-Sleep -Seconds 1
    exit 0
}
"@
    Start-Process -Wait -Verb runAs -FilePath $shell -ArgumentList "-NoProfile","-Command",$elevatedCommand

    return
}

if ($ClearExceptions) {
    Clear-DefenderExceptions
    return
}
else {
    Set-DefenderExceptions
    return
}
