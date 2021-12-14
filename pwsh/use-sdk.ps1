function Use-Sdk {
	# .Synopsis
	# Changes versions of candidates managed by sdkman.
	[CmdletBinding()]
	param (
		# SDK to modify
		[string]$Candidate,
		# SDK version to use, use 'current' for the default.
		[string]$Version = "current",
		# If set, the default will also be changed.
		[switch]$SetDefault
	)

	if ($SetDefault -and ($version -eq "current")) {
		throw [System.ArgumentException] "Using 'current' to set a default doesn't make sense!"
	}

	$local:sdk = Join-Path -Path "~" -ChildPath ".sdkman" `
		-AdditionalChildPath "candidates", $candidate
	if (!(Test-Path -Path $local:sdk -PathType Container)) {
		throw [System.IO.FileNotFoundException] "$local:sdk does not exist!"
	}
	$local:sdk = Resolve-Path $local:sdk
	$local:target = Join-Path -Path $local:sdk -ChildPath $version
	if (!(Test-Path -Path $local:target)) {
		throw [System.IO.FileNotFoundException] "$local:target does not exist!"
	}

	if ($SetDefault) {
		$local:current = Join-Path -Path $local:sdk -ChildPath "current"
		if (Test-Path -Path $local:current) {
			Remove-Item $local:current
		}
		New-Item -Path $local:current -ItemType SymbolicLink -Value $local:target > $null
		$local:target = $local:current
	}

	$local:target = Join-Path -Path $local:target -ChildPath "bin"

	if ($env:PATH -cnotmatch $local:sdk) {
		# The SDK is not in scope at all. Just prepend it.
		$env:PATH = $local:target, $env:PATH -join [IO.Path]::PathSeparator
	} elseif ($env:PATH -cnotmatch $local:target) {
		$env:PATH = $env:PATH -creplace "$local:sdk[^$([IO.Path]::PathSeparator)]+", $local:target
	}
}

function List-Sdk {
	# .Synopsis
	# Lists possible versions for an SDK managed by sdkman or SDKs themselves.
	[CmdletBinding()]
	param (
		# Candidate for which to list possible versions. Skip to list SDKs themselves.
		[Parameter(Mandatory=$false)]
		[AllowEmptyString()]
		[string]$Candidate
	)
	$local:candidates = Join-Path -Path "~" -ChildPath ".sdkman" `
		-AdditionalChildPath "candidates"
	if (!(Test-Path -Path $local:candidates -PathType Container)) {
		throw [System.IO.FileNotFoundException] "$local:candidates does not exist!"
	}
	if (!$candidate) {
		Get-ChildItem $local:candidates
	} else {
		$local:sdk = Join-Path -Path $local:candidates -ChildPath $candidate
		if (!(Test-Path -Path $local:sdk -PathType Container)) {
			throw [System.IO.FileNotFoundException] "$local:sdk does not exist!"
		}
		Get-ChildItem $local:sdk
	}
}
