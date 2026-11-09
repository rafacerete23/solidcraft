param(
 [Parameter(Mandatory)][string]$Cli,
 [Parameter(Mandatory)][string]$Repo,
 [Parameter(Mandatory)][string]$Out
)
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Force $Out | Out-Null
function Invoke-Cad {
 param([string[]]$CliArgs)
 & $Cli @CliArgs
 if($LASTEXITCODE -ne 0){throw "SolidCraft exit ${LASTEXITCODE}: $($CliArgs -join ' ')"}
}
function Read-Result($Name) { Get-Content (Join-Path $Out $Name) -Raw | ConvertFrom-Json }
$step=Join-Path $Out 'bracket.step'
$part=Join-Path $Out 'bracket.sc'
$edit=Join-Path $Out 'bracket-edit.json'
$dxf=Join-Path $Out 'sheet.dxf'
Invoke-Cad @('run',"$Repo\examples\bracket.json",'--out',$part,'--out',$step,'--out',"$Out\bracket.stl",'--out',"$Out\bracket.3mf",'--json-out',"$Out\bracket-native.json")
Invoke-Cad @('eval',$step,'--json-out',"$Out\bracket-roundtrip.json")
@{commands=@(@{command='parameters.change';params=@{name='width';expression='75 mm'}})} | ConvertTo-Json -Depth 5 | Set-Content $edit
Invoke-Cad @('eval',$edit,'--in',$part,'--json-out',"$Out\bracket-edit-result.json")
$n=Read-Result 'bracket-native.json'
$s=Read-Result 'bracket-roundtrip.json'
$e=Read-Result 'bracket-edit-result.json'
$profileArea=40*6 + (30-6)*6
$filletArea=2*2 - [Math]::PI
$holesVolume=2*[Math]::PI*4*4*6
$expected=($profileArea - $filletArea)*60 - $holesVolume
if([Math]::Abs($n.total.volume_mm3 - $expected)/$expected -gt 1e-4){throw "Bracket volume differs from analytic value $expected"}
$rel=[Math]::Abs($s.total.volume_mm3 - $n.total.volume_mm3)/$n.total.volume_mm3
if($n.body_count -ne 1 -or $s.body_count -ne 1 -or !$s.bodies[0].closed -or $rel -gt 1e-4){throw "STEP roundtrip failed: rel=$rel"}
$editedExpected=($profileArea - $filletArea)*75 - $holesVolume
if([Math]::Abs($e.bodies[0].bbox.min[1] + 75) -gt 1e-6 -or [Math]::Abs($e.total.volume_mm3 - $editedExpected)/$editedExpected -gt 1e-4){throw 'Parametric rebuild failed'}
foreach($ext in 'stl','3mf'){
 if((Get-Item -LiteralPath "$Out\bracket.$ext").Length -eq 0){throw "Empty bracket.$ext"}
}
foreach($case in 'acceptance/sensor_enclosure','chebyshev-motion-trace','regressions/sheet-side-flange-corner','regressions/step_export_screw_hole_enclosure'){
 $name=Split-Path $case -Leaf
 Invoke-Cad @('eval',"$Repo\examples\$case.json",'--json-out',"$Out\$name.json")
 $r=Read-Result "$name.json"
 if($r.body_count -lt 1 -or $r.total.open_bodies_skipped -ne 0){throw "Invalid geometry: $case"}
}
$sheet=Get-Content "$Repo\examples\regressions\sheet-side-flange-corner.json" -Raw | ConvertFrom-Json
$sheet.commands+=@(@{command='sheet.flat_pattern';params=@{}},@{command='sheet.export_dxf';params=@{path=$dxf}})
$sheet | ConvertTo-Json -Depth 20 | Set-Content "$Out\sheet-export.json"
Invoke-Cad @('run',"$Out\sheet-export.json",'--results','--json-out',"$Out\sheet-export-results.json")
if(!(Test-Path $dxf) -or !(Select-String -Path $dxf -Pattern '^BEND_(UP|DOWN)$' -Quiet)){throw 'DXF does not contain bend lines'}
Invoke-Cad @('render',"$Repo\examples\render-studio.json",'--width','640','--height','400','--timeout','90','--overwrite','--out',"$Out\render.png")
"PASS. STEP volume relative difference: $rel. Parametric width: $(-$n.bodies[0].bbox.min[1]) -> $(-$e.bodies[0].bbox.min[1]) mm."
