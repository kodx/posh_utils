<#
    .SYNOPSIS
    Create self signed certificate
  
    .DESCRIPTION
    This script generate self signed certificate with private key and write all of it to files. User can set desired certificate name and private key password.
  
    .EXAMPLE
    create-self-signed-cert.ps1 -Name MyCert -Password mypass
  
    Create .pem, .cert and .pfx files in script folder
  
    .NOTES
    Version:  1.0
    Author:   Yegor Bayev <kodx.org>
#>

param(
    [Parameter(
        HelpMessage = "Enter desried certificate name"
    )]
    [String]$Name = 'MyCertificate',
    [Parameter(
        HelpMessage = "Enter private key password"
    )]
    [String]$Password = 'pass123',
    [Parameter(
        HelpMessage = "Quick run. Use 'MyCertificate' as certficate name and 'pass123' as private key password"
    )]
    [switch]$s
)

if ($psboundparameters.count -eq 0) {
    write-host 'Set -Name and/or -Password parameters, or run with -s key to use default'
    Exit
}

"Creating certificate `"$($Name)`" and private key with password `"$Password`"" | write-host

$cerpath = "$PSScriptRoot\$Name.cer"
$pfxpath = "$PSScriptRoot\$Name.pfx"
$pempath = "$PSScriptRoot\$Name.pem"
$pemcertpath = "$PSScriptRoot\$Name-cert.pem"
$pemkeypath = "$PSScriptRoot\$Name-key.pem"

# Install PSPKI Module
if (!(Get-Module -ListAvailable -Name PSPKI)) {
	Install-Module -Repository PSGallery PSPKI
}

Import-Module PSPKI

$cert = New-SelfSignedCertificate -Subject "CN=$Name" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256

Export-Certificate -Cert $cert -FilePath "$cerpath"

$mypwd = ConvertTo-SecureString -String "$Password" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "$pfxpath" -Password $mypwd

Convert-PfxToPem -InputFile "$pfxpath" -Password $mypwd -OutputFile "$pempath"

# Remove cert from storage
Get-ChildItem "Cert:\CurrentUser\My" | where Subject -eq "CN=$Name" | Remove-Item

# Get base64 strings from pem file and write them to files
(Get-Content $pempath -Raw) -match "(?ms)(\s*((?<privatekey>-----BEGIN PRIVATE KEY-----.*?-----END PRIVATE KEY-----)|(?<certificate>-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----))\s*){2}"

$Matches["privatekey"] | Set-Content $pemkeypath
$Matches["certificate"] | Set-Content $pemcertpath

# Remove temporary file
Get-ChildItem $pempath | Remove-Item
