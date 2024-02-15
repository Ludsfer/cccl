function Get-CCCLDevcontainerOptions {
    [CmdletBinding()] param (
        [switch]$Process,
        [switch]$EnableGPU,
        [switch]$DisableAV,
        [switch]$Interactive,
        [switch]$History,
        [switch]$BuildVolume,
        [string]$CTK,
        [string]$CCCL="$((Get-Item $PSScriptRoot).Parent.Parent.FullName)"
    )

    $containerConfig = @{
        dockerParams = @()
        buildVolume = $nul
        disableAV = $false
    }

    $containerConfig.dockerParams += @('--cpu-percent', '100')
    $containerConfig.dockerParams += @('--workdir', "C:\cccl")
    $containerConfig.dockerParams += @("--rm")

    if ($DisableAV) {
        Write-Warning "Disabling AV will require admin permissions when launching container"
        $containerConfig.disableAV = $true
    }

    if ($Process) {
        $containerConfig.dockerParams += @('--isolation=process')
    }

    if ($History) {
        # Mount user history into container
        $containerConfig.dockerParams += @("--mount", "type=bind,src=$ENV:APPDATA\Microsoft\Windows\Powershell\PSReadLine,dst=C:\Users\ContainerAdministrator\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine")
    }

    if ($CTK) {
        $nvccDir = (Get-ChildItem -Filter "nvcc.exe" -Recurse "$CTK").DirectoryName
        $containerConfig.dockerParams += @("--mount", "type=bind,src=$CTK,dst=$CTK")
        $containerConfig.prependedCommands += @('$ENV:PATH='+"$nvccDir"+'$ENV:PATH;')
    }

    if ($EnableGPU) {
        # null if GPU is undefined
        $containerConfig.dockerParams += @('--device','class/5B45201D-F2F2-4F3B-85BB-30FF1F953599')
    }

    if ($Interactive) {
        $containerConfig.dockerParams += @('-it')
    }

    Write-Verbose "Mounting $CCCL to C:\cccl"
    $containerConfig.dockerParams += @("--mount", "type=bind,src=$CCCL,dst=C:\cccl")

    if ($BuildVolume) {
        $containerConfig.buildVolume = "cccl-build"
    }
    $containerConfig.dockerParams += @("--volume", "cccl-build:C:\cccl\build:rw")

    Write-Verbose "Docker container arguments:"
    Write-Verbose "$($containerConfig.dockerParams)"
    Write-Verbose "Windows AV exceptions enabled:"
    Write-Verbose "$($containerConfig.disableAV)"

    Write-Output $containerConfig
}
