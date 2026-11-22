# ZenCube 3D 4.0.5 - local Windows signing with the EXISTING Google Play upload key only.
[CmdletBinding()]
param(
  [string]$Bundle = (Join-Path $PSScriptRoot 'ZenCube-3D-4.0.5-unsigned.aab'),
  [string]$Keystore,
  [string]$Alias,
  [string]$Bundletool = (Join-Path $PSScriptRoot 'bundletool-all-1.18.3.jar'),
  [Parameter(Mandatory=$true)][string]$ExpectedPackageId,
  [Parameter(Mandatory=$true)][string]$ExpectedUploadSha256,
  [Parameter(Mandatory=$true)][int]$LastPlayVersionCode
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-JdkTool([string]$Name) {
  if ($env:JAVA_HOME) {
    $candidate=Join-Path $env:JAVA_HOME ('bin\' + $Name + '.exe')
    if (Test-Path -LiteralPath $candidate) { return $candidate }
  }
  $command=Get-Command ($Name+'.exe') -ErrorAction SilentlyContinue
  if ($command) { return $command.Source }
  throw "Missing ${Name}: install Java JDK 17+ and configure JAVA_HOME."
}
if (-not $Keystore) { $Keystore=Read-Host 'Existing upload keystore path' }
if (-not $Alias) { $Alias=Read-Host 'Existing upload key alias' }
if (-not $Keystore -or -not $Alias -or $Alias.StartsWith('-')) { throw 'Valid keystore path and alias required.' }
$fingerprint=($ExpectedUploadSha256 -replace '[^0-9A-Fa-f]','').ToUpperInvariant()
if ($fingerprint -notmatch '^[0-9A-F]{64}$') { throw 'Invalid Play upload certificate SHA256.' }
$source=(Resolve-Path -LiteralPath $Bundle).ProviderPath
$store=(Resolve-Path -LiteralPath $Keystore).ProviderPath
$jar=(Resolve-Path -LiteralPath $Bundletool).ProviderPath
if ([IO.Path]::GetFileName($source) -cne 'ZenCube-3D-4.0.5-unsigned.aab') { throw 'Wrong bundle file.' }
$dest=Join-Path (Split-Path -Parent $source) 'ZenCube-3D-4.0.5-signed.aab'
if (Test-Path -LiteralPath $dest) { throw 'Signed destination already exists. Refusing overwrite.' }
$java=Find-JdkTool 'java'
$jarsigner=Find-JdkTool 'jarsigner'
$keytool=Find-JdkTool 'keytool'
& $java -jar $jar validate "--bundle=$source"
if ($LASTEXITCODE -ne 0) { throw 'Bundletool validation failed.' }
$manifestText=& $java -jar $jar dump manifest "--bundle=$source"
if ($LASTEXITCODE -ne 0) { throw 'Failed to inspect AAB manifest.' }
[xml]$manifest=$manifestText -join [Environment]::NewLine
$android='http://schemas.android.com/apk/res/android'
$root=$manifest.DocumentElement
$package=$root.GetAttribute('package')
$name=$root.GetAttribute('versionName',$android)
$code=[int]$root.GetAttribute('versionCode',$android)
$sdk=[int]$manifest.SelectSingleNode('/manifest/uses-sdk').GetAttribute('targetSdkVersion',$android)
$debuggable=$manifest.SelectSingleNode('/manifest/application').GetAttribute('debuggable',$android)
if ($package -cne $ExpectedPackageId) { throw "STOP: AAB package $package does not equal Play Console $ExpectedPackageId." }
if ($name -ne '4.0.5' -or $code -le $LastPlayVersionCode) { throw "STOP: invalid version $name ($code), prior Play code $LastPlayVersionCode." }
if ($sdk -lt 36 -or $debuggable -eq 'true') { throw 'STOP: not a non-debug API 36 release.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[System.IO.Compression.ZipFile]::OpenRead($source)
try {
  if (@($zip.Entries | Where-Object { $_.FullName -match '^META-INF/[^/]+\.(SF|RSA|DSA|EC)$' }).Count -gt 0) {
    throw 'Input AAB already signed.'
  }
} finally { $zip.Dispose() }
$tmp=Join-Path (Split-Path -Parent $source) ('.signing-' + [guid]::NewGuid().ToString('N') + '.aab')
try {
  # jarsigner prompts locally: no password arguments, saved files, or new keys.
  & $jarsigner -keystore $store -signedjar $tmp $source $Alias
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $tmp)) { throw 'Signing failed.' }
  $verify=& $jarsigner '-J-Duser.language=en' -verify $tmp
  if ($LASTEXITCODE -ne 0 -or (($verify -join [Environment]::NewLine) -notmatch '(?m)^jar verified\.\s*$')) {
    throw 'jarsigner verification failed.'
  }
  $cert=& $keytool '-J-Duser.language=en' -printcert -jarfile $tmp
  if ($LASTEXITCODE -ne 0) { throw 'Signing certificate read failed.' }
  $match=[regex]::Match(($cert -join [Environment]::NewLine),'(?im)^\s*SHA256:\s*([A-F0-9:]{95})\s*$')
  if (-not $match.Success -or (($match.Groups[1].Value -replace ':','').ToUpperInvariant() -ne $fingerprint)) {
    throw 'STOP: certificate does not match the EXISTING Play upload certificate.'
  }
  [IO.File]::Move($tmp,$dest)
  Write-Host 'ERFOLG: ZenCube 3D 4.0.5 lokal signiert und überprüft.' -ForegroundColor Green
  Write-Host "Paket $package | Version $name ($code) | targetSdk $sdk"
  Write-Host "Datei: $dest"
  Write-Host ("SHA-256: " + (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash)
  Write-Host 'Kein Upload, keine Veröffentlichung, kein neuer Uploadschlüssel.'
} finally { if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force } }
