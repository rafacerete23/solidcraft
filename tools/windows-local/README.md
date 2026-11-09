# Local Windows build and smoke tests

This folder is for the local Windows branch. It does not change the application or its defaults.

## Build

With Visual Studio Build Tools and the C++ workload, run these commands from an x64 Developer PowerShell in the repository root:

```powershell
cargo build --locked -p solidcraft -p solidcraft-cli
.\target\debug\solidcraft.exe --sample
```

The optional build wrapper uses a portable SDK and LLVM when Visual Studio is not available.
Install Rust for `x86_64-pc-windows-msvc`. Extract the official LLVM 23.1.5 x64 Windows
tar.xz under a toolchain directory. Use xwin to extract the Microsoft SDK and CRT under
the same directory as `sdk` (the SDK and CRT are subject to Microsoft's license).
The wrapper expects the resulting `sdk\crt\lib\x86_64`, `sdk\sdk\lib\um\x86_64`,
`sdk\sdk\lib\ucrt\x86_64` and associated include directories.

```powershell
.\tools\windows-local\Build-PortableToolchain.ps1 -Toolchain D:\solidcraft_work\toolchain
```

The [official portable Windows release](https://github.com/tangency-labs/solidcraft/releases)
is a fallback for using the app while a source build runs. Verify the archive against
the published SHA256 file and extract it to a separate directory.

## Verify

Use an absolute output path and a separate directory for each version:

```powershell
.\tools\windows-local\Smoke-Test.ps1 -Cli (Resolve-Path .\target\debug\solidcraft-cli.exe).Path -Repo (Get-Location).Path -Out D:\solidcraft_work\smoke-main
```

The script checks one bracket from sketch through extrusion, fillet and cut. It edits the
saved parameter from 60 mm to 75 mm, exports STEP/STL/3MF, and checks that the STEP reopens
as one closed body with a volume error under 0.01%. It compares the native volumes with
the volumes calculated from the bracket dimensions. It also checks a sensor enclosure, a
moving assembly, a sheet-metal part and its flat pattern DXF, and a PNG render. Artifacts
are written to the output directory.

On official 0.30.1, the smoke test passed with a relative STEP volume difference of
2.77e-7. The separate `examples/clean-up/three-round-corner.json` case was refused at
`surface.patch` because the fitted surface did not meet the tolerance. The smoke tests
do not establish support for every geometric case.

The workspace-wide `cargo xtask ci` stopped in the format stage with Windows error
206 (command line too long). The Windows smoke test runs independently.

## Integration notes

- Render improvements are already in upstream main via [#12546](https://github.com/tangency-labs/solidcraft/pull/12546).
  Do not merge the old feature branch a second time.
- Keep the topology-first STEP branch separate while [#14038](https://github.com/tangency-labs/solidcraft/pull/14038)
  has an application regression. Local tests of its STEP crate passed (43 tests, 2 external
  corpus tests skipped); that result does not replace the application checks.
- The mesh and drawings branches had conflicts in their integration trial. Reassess the
  upstream changes separately before replacing the viewport or drawing code.

## What remains compared with Autodesk Fusion

SolidCraft can already cover the tested parametric part and fabrication handoff. It has
some sheet-metal and assembly workflows. Its drawings and advanced surfacing remain
limited. It lacks the integrated CNC, structural simulation, electronics and cloud data
management offered by [Autodesk Fusion](https://www.autodesk.com/products/fusion-360/features).
Use STEP to exchange geometry; the native parametric timeline does not travel with it.
See the [SolidCraft roadmap](https://github.com/tangency-labs/solidcraft/blob/main/ROADMAP.md).

## External projects

- [SolidCraftCam](https://github.com/HansFel/SolidCraftCam) is a fork with 2.5D
  pocketing, facing and contours for LinuxCNC. Evaluate its toolpaths in simulation before
  any machine use. It is not a replacement for Fusion's full manufacturing workspace.
- [solidcraft-perf](https://github.com/sahenjp/solidcraft-perf) supplies a benchmark
  harness. Compare the same designs and geometry on the same machine before taking patches.
- [solidcraft-library](https://github.com/tangency-labs/solidcraft-library) has materials and
  render resources. It has no installable pack yet. Check the license of each asset.
- [OrcaSlicer](https://github.com/OrcaSlicer/OrcaSlicer) can be used as a separate process
  with STL or 3MF. Keep it outside the application; its license is AGPL-3.0.
- [solidcraft-rover](https://github.com/0xlillith/solidcraft-rover) supplies an editable
  design and a workload for larger assemblies without a code merge. The 0.30.1 CLI
  opened and measured 1,395 bodies in `Rover-v7.solidcraft`.
