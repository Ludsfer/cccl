[CmdletBinding()] param (
    [switch]
    $ClearExceptions
)

. $PSScriptRoot\admin.ps1

$ErrorActionPreference = 'Stop'

$extensionList=".cpp,.h,.hpp,.c,.cu,.cuh,.i,.ii,.o,.obj,.cubin,.ptx,.py"
$processList="cmake.exe,ninja.exe,python.exe,lit.exe,nvcc.exe,ptxas.exe,cicc.exe,cudafe++.exe,cl.exe,link.exe,lib.exe,sccache.exe"
$pathList="$ENV:ProgramData\docker"

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

if (Get-CCCLAdmin) {
    if ($ClearExceptions) {
        Clear-DefenderExceptions
        return
    }
    else {
        Set-DefenderExceptions
        return
    }
}
else {
    $command = @"
    & {
        $PSCommandPath -ClearExceptions:`$$ClearExceptions -Verbose
        Start-Sleep -Seconds 1
        exit 0
    }
"@
    Invoke-CCCLAdmin -ScriptBlock $command
}
