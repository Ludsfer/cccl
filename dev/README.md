# How to use Windows devcontainers for testing

Containerization on Windows allows users to avoid typical VS IDE bloat and improves testability by isolating the environment. CCCL can provide a way to for developers to access these resources via a simple powershell module. This module helps circumnavigate common pitfalls when getting CUDA to work in WCoW (Windows Containers on Windows.)

Eventually this could extend to launching containers in WSL and not just Windows to help provide a complete development environment from one machine.

## Getting started

Ensure that Docker Engine is installed on your system. If you can execute `docker info` and know that you are using Windows Containers and not Linux Containers through the WSL shim, then you are good to go and no futher preparation should be required.

## Simple start

```powershell
# Import-Module cccl
> . cccl.ps1

# Fetch a 24.02 Windows 2022 container with MSVC 14.36 and latest CUDA 12.
> $container = Get-CCCLDevcontainer -Require 24.02,windows2022,cl14.36,cuda12 | Select-Object -First 1
# Interactive session with Process isolation and GPU attached
> $options = Get-CCCLDevcontainerOptions -Process -EnableGPU -Interactive
# Validate launch settings, will test if platform and container are capable of doing the requested actions
> $launchconfig = New-CCCLDevcontainerLaunchConfig -ContainerInfo $container -LaunchParams $options
# Launch with the validated parameters
> Start-CCCLDevcontainer @launchconfig
```

You should expect to see the following terminal appear with the environment already prepared.

```
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows

Loading VC from: C:\msbuild\17\VC\Auxiliary\Build

Visual Studio Command Prompt variables set.
Use 'cl' or $CC_FP as shortcut for Cmake: C:/msbuild/17/VC/Tools/MSVC/14.36.32532/bin/HostX64/x64/cl.exe
Loading personal and system profiles took 1984ms.
PS C:\cccl>
```

## Functional details

All cmdlets support `-Verbose` for obtaining more detailed information about what is happening.

### Get-CCCLDevcontainer

This function performs a search over all rapidsai/devcontainers tags and will fuzzy match for the requested features. You can also ignore features with `-Ignore 'feature'` for example.

| Parame     | Description |
| ---------- | ----------- |
| `-Require` | Match terms to container features |
| `-Ignore`  | Do not match terms to container features |

Example:

```powershell
> $containers = Get-CCCLDevcontainer -Require windows2022,cl14.36,cuda12
```

`$containers` is an array of containers and their information. It can be inspected to see what was returned, additional information about the image (OS edition, architecture, etc) is also available if needed. This information can be used to determine whether or not a desired run configuration will be valid on Windows.

```powershell
> $container = $containers | Select-Object -First 1
> $container
Name                           Value
----                           -----
Container                      rapidsai/devcontainers:23.10-cuda12.2-cl14.36-windows2022
ImageInfo                      {@{architecture=amd64; features=; variant=; digest=sha256:c8d3e78b6e2eba18a7bbf4ea2c86b…
```

### Get-CCCLDevcontainerOptions

`Get-CCCLDevcontainerOptions` provides an interface to managing docker params that are not well understood or undocumented. Process isolation and GPU attachment on Windows are notably different from Linux containers. It also can do and attach a number of helpful files and folders to the container if needed.

| Parameter      | Description |
| -------------- | ----------- |
| `-Process`     | Enables process isolation improving performance. |
| `-EnableGPU`   | Enables passing the GPU into the container (requires `-Process`) |
| `-DisableAV`   | Disables AV scanning for the container and relevant build resources |
| `-Interactive` | Enables an interactive shell |
| `-History`     | Attaches the current user's PS history to the shell for backsearch/recall |
| `-BuildVolume` | Attaches a build volume for automatic cleanup when done with the container |
| `-CTK`         | Attaches a custom CTK to the container overriding the default |
| `-CCCL`        | Override the default mount point for the CCCL repo |

Parameter examples:

```powershell
> $options = Get-CCCLDevcontainerOptions -Process -EnableGPU -DisableAV -Interactive -History -CTK "C:\...\cuda-12.0"
> $options

Name                           Value
----                           -----
disableAV                      True
dockerParams                   {--cpu-percent, 100, --workdir, C:\cccl…}
buildVolume
```

### New-CCCLDevcontainerLaunchConfig

With an applicable `$options` and `$container` you can create a launch config that validates all of the parameters and launch into a container for doing your build. This can help provide diagnostics for why certain combinations of Host OS and Container OS, flags, and other bits will be incompatible.

```powershell
# Validate launch settings, will test if platform and container are capable of doing the requested actions
> $launchconfig = New-CCCLDevcontainerLaunchConfig -ContainerInfo $container -LaunchParams $options
# Launch with the validated parameters
# if setting AV exceptions, they will be removed when the container exits.
> Start-CCCLDevcontainer @launchconfig
```

In container shell:

```
WARNING: AV Exceptions are settable only with administrative rights. Elevating.
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows

Loading VC from: C:\msbuild\17\VC\Auxiliary\Build

Visual Studio Command Prompt variables set.
Use 'cl' or $CC_FP as shortcut for Cmake: C:/msbuild/17/VC/Tools/MSVC/14.36.32532/bin/HostX64/x64/cl.exe
Loading personal and system profiles took 1984ms.

PS C:\cccl> cmake --preset thrust-cpp14 # Build Thrust with NVCC 12.2 and CL 14.36
Preset CMake variables:
....
-- The CXX compiler identification is MSVC 19.36.32541.0
-- The CUDA compiler identification is NVIDIA 12.2.91
-- Configuring done (19.0s)
-- Generating done (1.0s)
-- Build files have been written to: C:/cccl/build/thrust-cpp14
PS C:\cccl> exit
```
