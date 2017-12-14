param ([switch]$verbose)

Set-Location $PSScriptRoot
$WixPath = Join-Path $PSScriptRoot '..\..\packages\WiX.3.10.1\tools'
if (-not (Test-Path $WixPath))
{
	throw "WiX not found in [$WixPath]. Make sure NuGet package installed."
}

if ( ! (get-command candle.exe -ea silentlycontinue))
{
	Write-Host 'Updating wixpath'
    $env:path += ";$WixPath"
}

$candle = Join-Path $WixPath 'Candle.exe'
$light = Join-Path $WixPath 'Light.exe'

$outputPrefix = "SMLets"

function new-smletsmsi
{
    param ( $NAME, $ARCH )
    if ( $ARCH -eq "x86" )
    {
        $MSINAME = "${NAME}.X86.msi"
        $WIXNAME = "${NAME}.X86.wixobj"
        $PDBNAME = "${NAME}.X86.wixpdb"
    }
    else
    {
        $MSINAME = "${NAME}.msi"
        $WIXNAME = "${NAME}.wixobj"
        $PDBNAME = "${NAME}.wixpdb"
    }

	$wsx = Get-Content smlets.wsx -Raw
	$wsx = $wsx.Replace("{BUILDVERSION}", $env:APPVEYOR_BUILD_VERSION)
	Set-Content -Value $wsx -path smlets.wsx -Force

    if ( test-path $MSINAME ) { rm $MSINAME }
    # the WSX file doesn't change
    $c = candle -arch $ARCH smlets.wsx -out $WIXNAME
    if ( $verbose ) { $c | write-verbose -verbose }
    $l = light -ext WixUIExtension $WIXNAME -out $MSINAME
    if ( $verbose ) { $l | write-verbose -verbose }
    # cleanup
    if ( test-path fogfile.txt ) { rm fogfile.txt }
    if ( test-path $WIXNAME ) { rm $WIXNAME }
    if ( test-path $PDBNAME ) { rm $PDBNAME }
}

Write-Progress -Activity "Building MSI" -status "Creating '$outputPrefix' x64 version"
$env:SMLETS64=1
new-smletsmsi -name $outputPrefix -arch x64

Write-Progress -Activity "Building MSI" -status "Creating '$outputPrefix' x86 version"
$env:SMLETS64=0
new-smletsmsi -name $outputPrefix -arch x86

if ( test-path env:SMLETS64 ) { rm env:SMLETS64 }



