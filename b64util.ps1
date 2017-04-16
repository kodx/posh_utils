<#
.SYNOPSIS

This script create base64 files according to options.
Compression section from https://github.com/PowerShellMafia/PowerSploit/blob/master/ScriptModification/Out-CompressedDll.ps1
and other PowerSploit scripts https://github.com/PowerShellMafia/PowerSploit

Author: Yegor Bayev (kodxpub@gmail.com)

.DESCRIPTION

Convert file to base64 representation.

.PARAMETER SrcPath

Path to file to convert.

.PARAMETER decode

Decode string from file, ingore other options.
Creates output file near source, with '.dec' extension.

.PARAMETER pack

Create packed base64 text with deflate algorithm.

.PARAMETER script

Create example script instead of file with base64 string.

.PARAMETER clipboard

Copy generated base64 string or script to clipboard.
Suppress output file creation.

.EXAMPLE

Create text file with one base64 string named .\myfile.exe.b64 next to original file:
> b64util.ps1 .\myfile.exe

.EXAMPLE

Create packed string example script named .\myfile.exe.b64.pack.ps1:
> b64util.ps1 .\myfile.exe -pack -script

.EXAMPLE

Decode base64 string from file .\b64_str.b64 to .\b64_str.b64.dec:
> b64util.ps1 .\b64_str.b64 -decode

.EXAMPLE

Copy encoded base64 string to clipboard:
> b64util.ps1 .\myfilex.exe -clipboard

#>

Param (
    [Parameter(Mandatory = $True)]
    [String]
    $SrcPath,
    [switch] $pack,
    [switch] $script,
    [switch] $decode,
    [switch] $clipboard
)

function GenBasicScript {
    param(
        $b64Str
    )
    $Output = @"
`$EncodedString = @'
$EncodedString
'@
`$DecodedBytes = [System.Convert]::FromBase64String(`$EncodedString)
"@
    return $Output
}

function PackData {
    param(
        $FileData
    )
    $Length = $FileData.Length
    $CompressedStream = New-Object IO.MemoryStream
    $DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
    $DeflateStream.Write($FileData, 0, $FileData.Length)
    $DeflateStream.Dispose()
    $CompressedFileBytes = $CompressedStream.ToArray()
    $CompressedStream.Dispose()
    return [Convert]::ToBase64String($CompressedFileBytes), $Length
}

function GenPackScript {
    param(
        $PackedB64Str,
        $PackedDataLength
    )
    $RetStr = @"
`$EncodedCompressedFile = @'
$PackedB64Str
'@
`$DeflatedStream = New-Object IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(`$EncodedCompressedFile),[IO.Compression.CompressionMode]::Decompress)
`$UncompressedFileBytes = New-Object Byte[]($PackedDataLength)
`$DeflatedStream.Read(`$UncompressedFileBytes, 0, $PackedDataLength) | Out-Null
# `$UncompressedFileBytes is a byte array
# to eval commands from `$UncompressedFileBytes as powershell script, use
# ([Text.Encoding]::UTF8.GetString(`$UncompressedFileBytes)) | IEX
"@
    return $RetStr
}

$Path = Resolve-Path $SrcPath

if (! [IO.File]::Exists($Path)) {
    Throw "$Path does not exist."
}

new-alias Out-Clipboard $env:SystemRoot\system32\clip.exe

$FileBytes = [IO.File]::ReadAllBytes($Path)

if ($decode) {
    $DecodeStr = [Text.Encoding]::UTF8.GetString($FileBytes)
    [System.Convert]::FromBase64String($DecodeStr) | Set-Content -Encoding 'Byte' "$Path.dec"
} else {
    if ($pack) {
        $EncodedCompressedFile, $Length = PackData $FileBytes
        if ($script) {
            $Output = GenPackScript $EncodedCompressedFile $Length
            if ($clipboard) {
                $Output | Out-Clipboard
                exit
            }
            $Output | Set-Content -Encoding 'ASCII' "$Path.b64.pack.ps1"
        } else {
            if ($clipboard) {
                $EncodedCompressedFile | Out-Clipboard
                exit
            }
            $EncodedCompressedFile | Set-Content -Encoding 'ASCII' "$Path.b64.pack"
        }
    } else {
        $EncodedString = [System.Convert]::ToBase64String($FileBytes)
        if ($script) {
            $Output = GenBasicScript $EncodedString
            if ($clipboard) {
                $Output | Out-Clipboard
                exit
            }
            $Output | Set-Content -Encoding 'ASCII' "$Path.b64.ps1"
        } else {
            if ($clipboard) {
                $EncodedString | Out-Clipboard
                exit
            }
            $EncodedString | Set-Content -Encoding 'ASCII' "$Path.b64"
        }
    }
}

