function Get-CCCLAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    return $isAdmin
}

function Invoke-CCCLAdmin {
    [CmdletBinding()]
    param(
        $ScriptBlock
    )
    $shell=[Diagnostics.Process]::GetCurrentProcess().Path

    if (! (Get-CCCLAdmin)) {
        Write-Warning "Requesting administrator access for the following script block"
        Write-Warning "$ScriptBlock"

        return Start-Process -Wait -Verb runAs -FilePath $shell -ArgumentList "-NoProfile","-Command",$ScriptBlock
    }
    else {
        return Invoke-Command $ScriptBlock
    }
}
