param ( [switch]$clean )

# to build please run under PSv2
# PowerShell.exe -Version 2
Set-Location $PSScriptRoot
$PackagesDir = Join-Path $PSScriptRoot '..\packages\SMDlls\7.5.3079.0'

if ( $clean )
{
    remove-item SMLets.Module.dll -ea silentlycontinue
    remove-item SMLets.Module.dll-Help.xml -ea silentlycontinue
    remove-item SMLets.Module.pdb -ea silentlycontinue
    exit
}

# this function creates the Get-SMLetsVersion cmdlet file
function New-SMLetsVersionFile
{
    $rs = ""; 
    $rs += " -replace '_SMCOREVERSION_','" + $COREDLLVERSION.FileVersion + "'"
    $foundMatches = $null
    $pstring = " -replace '_PRIVATE_','true'"
    $cstring = " -replace '_CHANGES_',''"
    if ( get-command -ea silentlycontinue svn )
    {
        $changedFiles = (svn stat) -match "^[AM]"
        if ( $changedFiles )
        { 
            $pstring = " -replace '_PRIVATE_','true'"
            $cstring = " -replace '_CHANGES_','" + ($changedFiles -join '","') + "'"
        }
        else
        {
            $pstring = " -replace '_PRIVATE_','false'"
        }
        $l1 = "Working Copy Root Path: (?<_WORKINGCOPYROOTPATH_>.*)"
        $l2 = "URL: (?<_URL_>.*)"
        $l3 = "Repository Root: (?<_REPOSITORYROOT_>.*)"
        $l4 = "Repository UUID: (?<_REPOSITORYUUID_>.*)"
        $l5 = "Revision: (?<_REVISION_>.*)"
        $l6 = "Node Kind: (?<j1_>.*)"
        $l7 = "Schedule: (?<j2_>.*)"
        $l8 = "Last Changed Author: (?<_LASTCHANGEDAUTHOR_>.*)"
        $l9 = "Last Changed Rev: (?<_LASTCHANGEDREV_>.*)"
        $la = "Last Changed Date: (?<_LASTCHANGEDDATE_>.*)"
        $pattern = "$l1 $l2 $l3 $l4 $l5 $l6 $l7 $l8 $l9 $la" 
        if ( ([string](svn info) -match $pattern))
        {
            $foundMatches = $matches
        }
    }
    if ( $foundMatches -eq $null )
    {
        $foundMatches = @{ 
        _WORKINGCOPYROOTPATH_ = "$PWD"
        _URL_ = "https://smlets.svn.codeplex.com/svn/Main/Source/SMLets/SMLets"
        _REPOSITORYROOT_ = "https://smlets.svn.codeplex.com/svn"
        _REPOSITORYUUID_ = "e17a0e51-4ae3-4d35-97c3-1a29b211df97"
        _REVISION_ = "unknown"
        _LASTCHANGEDAUTHOR_ = $env:username
        _LASTCHANGEDREV_ = "unknown"
        _LASTCHANGEDDATE_ = get-date
        }
    }
    $foundMatches['_TARGETPRODUCT_'] = (get-itemproperty 'hklm:/software/microsoft/system center/2010/Service Manager/Setup' product).product

    foreach($k in $foundMatches.keys)
    {
        if ( $k -match "^_" )
        {
            $rs += " -replace '$k','" + $foundMatches.$k + "'"
        }
    }

    $rs += " $pstring"
    $rs += " $cstring"
    $rs += " -replace '\\','/'"
    $sv = '${' + "$pwd\SMLETSVERSION.cs}"
    $executionContext.InvokeCommand.NewScriptBlock("$sv $rs").Invoke()
}

function ConvertTo-RegularPath {
	param($UriPath)

	$UriBuilder = new-object System.UriBuilder $UriPath
    [Uri]::UnescapeDataString($uriBuilder.Path)
}

# Find the compiler - pick the latest
$INSTALLDIR =  (gp 'hklm:/software/microsoft/system center\2010\Service Manager\Setup').InstallDirectory

if ([String]::IsNullOrEmpty($InstallDir) -and -not (Test-Path $PackagesDir))
{
	Write-Warning "Service Manager install now found. Searching GAC for SM DLLs."

	$CoreAssembly = [Reflection.Assembly]::LoadWithPartialName('Microsoft.EnterpriseManagement.Core')
	if ($CoreAssembly -eq $null)
	{
		throw "Failed to locate Microsoft.EnterpriseManagement.Core.dll"
	}

	$SmAssembly = [Reflection.Assembly]::LoadWithPartialName('Microsoft.EnterpriseManagement.ServiceManager')
	if ($SmAssembly -eq $null)
	{
		throw "Failed to locate Microsoft.EnterpriseManagement.ServiceManager.dll"
	}

	$PkgAssembly = [Reflection.Assembly]::LoadWithPartialName('Microsoft.EnterpriseManagement.Packaging')
	if ($PkgAssembly -eq $null)
	{
		throw "Failed to locate Microsoft.EnterpriseManagement.Packaging.dll"
	}

	$CoreDLL =  ConvertTo-RegularPath $CoreAssembly.CodeBase
	$SmDll =  ConvertTo-RegularPath $SmAssembly.CodeBase
	$PkgDll =  ConvertTo-RegularPath $PkgAssembly.CodeBase
}
elseif (Test-Path $PackagesDir)
{
	$COREDLL = "$PackagesDir\Microsoft.EnterpriseManagement.Core.dll"
	$SMDLL = "$PackagesDir\Microsoft.EnterpriseManagement.ServiceManager.dll"
	$PKGDLL = "$PackagesDir\Microsoft.EnterpriseManagement.Packaging.dll"
}
else
{
	$COREDLL = "${INSTALLDIR}\SDK Binaries\Microsoft.EnterpriseManagement.Core.dll"
	$SMDLL = "${INSTALLDIR}\SDK Binaries\Microsoft.EnterpriseManagement.ServiceManager.dll"
	$PKGDLL = "${INSTALLDIR}\SDK Binaries\Microsoft.EnterpriseManagement.Packaging.dll"
}

$COREDLLVERSION = [system.diagnostics.fileversioninfo]::GetVersionInfo($COREDLL)

$SMADLL = ([appdomain]::CurrentDomain.getassemblies()|?{$_.location -match "System.Management.Automation.dll"}).location
foreach ( $version in  "v4.0.30319", "v3.5","v3.0","v2.0.50727" )
{
    $fmwk64 = "${env:windir}\Microsoft.Net\Framework64\$version"
    $fmwk32 = "${env:windir}\Microsoft.Net\Framework\$version"
    if ( test-path $fmwk64 )
    {
        set-alias csc "$fmwk64\csc.exe"
        break
    }
    elseif ( test-path $fmwk32 )
    {
        set-alias csc "$fmwk32\csc.exe"
        break
    }
}

$files = "Identifiers.cs", "Incident.cs", "Helper.cs", "Session.cs", "EntityTypes.cs", "DataWarehouse.cs", "EntityObjects.cs", "Subscription.cs", "Announcement.cs", "ManagementPack.cs", "Security.cs", "Templates.cs", "Presentation.cs", "Monitoring.cs", "Categories.cs", "Resources.cs", "Offering.cs", "Properties\AssemblyInfo.cs", "MPBMaker\FileInformation.cs"

$CurrentVersionFile = "SMLETSCURRENTVERSION.CS"
New-SMLetsVersionFile > $CurrentVersionFile
$files += $CurrentVersionFile

$output = "SMLets.Module.dll"
$reference = "/r:$SMADLL","/r:$COREDLL","/r:$PKGDLL","/r:$SMDLL"
$R2Version = new-object System.Version 7.5.0.0

Write-Host "Core Version: $($COREDLLVERSION.ProductVersion)"

if ( $COREDLLVERSION.ProductVersion -ge $R2Version )
{
    $CFLAGS = "/d:_SERVICEMANAGER_R2_"
}
else
{
    $CFLAGS = ""
}
csc /target:library /debug $CFLAGS /out:$output $files $reference 

# we've named the Module assembly something different
# so we'll copy that help to the appropriate name for the Module assembly
$SNAPINHELP = "SMLets.dll-Help.xml"
$MODULEHELP = "SMLets.Module.dll-Help.xml"
Copy-Item $SNAPINHELP $MODULEHELP

# remove the SMLETSCURRENTVERSION file
if ( test-path $CurrentVersionFile ) { remove-item  $CurrentVersionFile }


