function Install-CCCLDocker {
    [CmdletBinding()] param (
        [string]$DockerPath="C:\docker"
    )

    $ProgressPreference = 'SilentlyContinue'
    $ErrorActionPreference = 'Stop'

    Invoke-CCCLAdmin -ScriptBlock "& {Stop-Service docker -ErrorAction Ignore}"

    Write-Verbose "Finding latest docker release"
    $dockerReleases = "https://download.docker.com/win/static/stable/x86_64/"
    $resp = Invoke-WebRequest -UseBasicParsing -Uri $dockerReleases
    # Match input strings for binary downloads, files are ordered so just set the latest each time a match is encountered
    $latest = $resp.Content.Split() | Select-String -Pattern "(docker-[0-9\.]+\.zip)" | %{ $_.Matches.Value } | Select-Object -Last 1

    Write-Verbose "Latest docker release: ${latest}"
    $dockerLatest = "${dockerReleases}${latest}"

    Write-Verbose "Fetching from ${dockerLatest}"
    Invoke-WebRequest -UseBasicParsing -OutFile docker.zip -Uri "${dockerLatest}"

    # Remove existing docker engine if present
    Write-Verbose "Removing existing installation at ${dockerLatest}"
    Remove-Item -ErrorAction Ignore -Recurse $DockerPath | Out-Null

    Write-Verbose "Creating new installation at ${dockerLatest}"
    New-Item -ItemType Directory -Path $DockerPath | Out-Null
    tar -C $DockerPath --strip-components=1 -xf docker.zip
    Remove-Item docker.zip

    & "$DockerPath\dockerd.exe" --validate
    if ($LastExitCode -ne 0) {
        Write-Error "Failed to validate configuration"
    }
    Invoke-CCCLAdmin -ScriptBlock "& { & '$DockerPath\dockerd.exe' --register-service; Start-Sleep 2s }"
    if ($LastExitCode -ne 0) {
        Write-Error "Failed to register dockerd as a service, try executing 'dockerd --register-service' manually"
    }
}
