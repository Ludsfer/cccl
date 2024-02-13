function New-CCCLDevcontainerLaunchConfig {
    [CmdletBinding()] param (
        [Parameter(Mandatory)]
        $ContainerInfo,
        [Parameter(Mandatory)]
        $LaunchParams
    )

    $config = @{
        Container = $ContainerInfo.Container
        ImageInfo = $ContainerInfo.ImageInfo
        LaunchParams = $LaunchParams
    }

    Write-Verbose "Returning packaged config"
    Write-Verbose $config

    Write-Output $config
}
