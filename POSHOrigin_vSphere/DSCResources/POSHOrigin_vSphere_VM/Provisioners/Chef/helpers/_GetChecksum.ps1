<#
    .SYNOPSIS
    Return the checksum of the specified file
#>
param (
    [Parameter(ParameterSetName="file")]
    [string]
    # Path to the file to get the checksum for
    $path,

    [Parameter(ParameterSetName="string")]
    [string]
    # The string to get the checksum for
    $string,

    [ValidateSet("sha1", "md5", "sha256")]
    [string]
    # Algorithm to use when generating the checksum
    $algorithm = "md5",

    [string]
    # The encoding method to use
    $encoding = "ASCII",

    [switch]
    # If trim is specified then the system will trim whitespace from the begining and end of input
    $trim,

    [switch]
    # Disable the Base64 encoding
    $nobase64
)

# $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
# $hash = [System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($path)))

$encoder = "{0}Encoding" -f $encoding

$algo = "{0}CryptoServiceProvider" -f $algorithm
$provider = New-Object -TypeName System.Security.Cryptography.$algo
$engine = New-Object -TypeName System.Text.$encoder

# Use the ParameterSetName to determine if a string or a path has been specified
# If it is a path then get the contents
switch ($PScmdlet.ParameterSetName) {
    "file" {
        $string = Get-Content -Path $path -Raw -Encoding UTF8
    }
}

# Strip characters from the string
# This is the the UNIX to Windows line ending problem
# Ruby is UNIX based and will strip LF from files when they are read in
#$string = $string -replace "`r", ""

# work out the checksum of the file
$hash = ([System.BitConverter]::ToString($provider.ComputeHash($engine.GetBytes($string)))).replace("-", "").tolower()

if ($nobase64) {
    $checksum = $hash
} else {
    # So that the hash is the same as that is generated by chef-client, it needs to be packed
    # and then base64 encoded
    $packed = for($i = 0; $i -lt $hash.length; $i += 2) {
        [char][int]::Parse($hash.substring($i,2), 'HexNumber')
    }

    # Now build up the checksum that is base64 encoded
    $checksum = & "$PSScriptRoot\_GetBase64.ps1" -data $packed
}

# Return the hash to the calling function
return $checksum