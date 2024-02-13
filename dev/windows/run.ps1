function Start-CCCLDevcontainer {
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $Container,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $ImageInfo,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        $LaunchParams,
        [string]
        $Shell="powershell"
    )

    $dockerParams = $LaunchParams.dockerParams

    if ($LaunchParams.buildVolume) {
        docker volume create $LaunchParams.buildVolume
    }

    if ($LaunchParams.disableAV) {
        & "$PSScriptRoot\av_exceptions.ps1" -Verbose
    }

    docker run @dockerParams $Container "$Shell"

    if ($LaunchParams.buildVolume) {
        docker volume rm -f $LaunchParams.buildVolume
    }

    if ($LaunchParams.disableAV) {
        & "$PSScriptRoot\av_exceptions.ps1" -ClearExceptions -Verbose
    }
}
