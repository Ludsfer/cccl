<#
.SYNOPSIS
Handles launching devcontainers on Windows.

.DESCRIPTION
This script may be used to build and test CCCL projects on Windows. This script manages querying
system capability and automating away common pitfalls.
#>

. $PSScriptRoot\windows\config.ps1
. $PSScriptRoot\windows\devcontainers.ps1
. $PSScriptRoot\windows\options.ps1
. $PSScriptRoot\windows\run.ps1
