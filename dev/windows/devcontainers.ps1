function Get-CCCLCachedDevcontainers {
    Write-Verbose "Checking if devcontainers are available in shell cache"
    $var = Get-Variable -ErrorAction SilentlyContinue -Scope Global -Name "Devcontainers"
    if ($var) {
        Write-Verbose "Devcontainer shell cache hit"
        Write-Output $var.Value
    }
}

function Set-CCCLCachedDevcontainers($Value) {
    Write-Verbose "Setting devcontainer cache"
    Set-Variable -Scope Global -Name "Devcontainers" -Value $Value
}

function Get-CCCLDevcontainer {
    [CmdletBinding()] param (
        [string[]]
        $Require,
        [string[]]
        $Ignore
    )

    $ProgressPreference = 'SilentlyContinue'

    $rapidsaiUrl = "https://hub.docker.com/v2/namespaces/rapidsai/repositories/devcontainers/tags?page=1&page_size=100"

    $filter = ".*"
    foreach ($i in $Require) {
        $filter += "(?=.*$i)"
    }
    foreach ($i in $Ignore) {
        $filter += "(?!.*$i)"
    }

    Write-Verbose "Using $filter to filter results"
    $results = Get-CCCLCachedDevcontainers
    if ($results -eq $nul) {
        $results = @()
        do {
            $reqParams = @{
                UseBasicParsing = $true
                Uri = ($rapidsaiUrl -f "$page","$pagesize")
            }

            $resp = Invoke-WebRequest @reqParams
            $jsonResp = $resp.Content | ConvertFrom-Json

            if ($jsonResp.next) {
                $rapidsaiUrl = $jsonResp.next
            }
            $results += $jsonResp.results
        } while ($jsonResp.next)
        Set-CCCLCachedDevcontainers -Value $results
    }
    Write-Verbose "Discovered $($results.Count) devcontainers"

    $containers = $results `
                    | Where-Object { $_.name -imatch $filter } `
                    | Select-Object -Property name,images `
                    | %{ @{Container = "rapidsai/devcontainers:$($_.name)"; ImageInfo = $_.images } } `
                    | Sort-Object -Property Container

    Write-Verbose "Returning $($containers.Count) matching devcontainers"

    Write-Output $containers
}
