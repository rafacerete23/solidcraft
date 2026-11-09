param([string]$Repo=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path, [string]$Target=(Join-Path $Repo 'target'), [Parameter(Mandatory)][string]$Toolchain, [string[]]$CargoArgs=@('build','--locked','-j','4','-p','solidcraft','-p','solidcraft-cli'))
$ErrorActionPreference='Stop'
$kit=(Resolve-Path -LiteralPath $Toolchain).Path
$sdk=Join-Path $kit 'sdk'
$llvm=Join-Path $kit 'clang+llvm-23.1.5-x86_64-pc-windows-msvc\bin'
$rustup=Join-Path $env:USERPROFILE '.cargo\bin'
$env:PATH="$llvm;$rustup;$env:PATH"
$env:LIB=@("$sdk\crt\lib\x86_64","$sdk\sdk\lib\um\x86_64","$sdk\sdk\lib\ucrt\x86_64") -join ';'
$env:INCLUDE=@("$sdk\crt\include","$sdk\sdk\include\ucrt","$sdk\sdk\include\shared","$sdk\sdk\include\um","$sdk\sdk\include\winrt","$sdk\sdk\include\cppwinrt") -join ';'
$env:CC_x86_64_pc_windows_msvc="$llvm\clang-cl.exe"
$env:CXX_x86_64_pc_windows_msvc="$llvm\clang-cl.exe"
$env:AR_x86_64_pc_windows_msvc="$llvm\llvm-lib.exe"
$env:RC_x86_64_pc_windows_msvc="$llvm\llvm-rc.exe"
$env:CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER="$llvm\lld-link.exe"
$env:CARGO_TARGET_DIR=$Target
$env:CARGO_PROFILE_DEV_DEBUG='0'
$env:CARGO_PROFILE_DEV_INCREMENTAL='false'
$env:CARGO_PROFILE_DEV_BUILD_OVERRIDE_DEBUG='false'
Push-Location -LiteralPath $Repo
try { & cargo @CargoArgs; exit $LASTEXITCODE } finally { Pop-Location }
