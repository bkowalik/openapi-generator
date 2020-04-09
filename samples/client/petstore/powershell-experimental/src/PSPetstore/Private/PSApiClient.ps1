#
# OpenAPI Petstore
# This is a sample server Petstore server. For this sample, you can use the api key `special-key` to test the authorization filters.
# Version: 1.0.0
# Generated by OpenAPI Generator: https://openapi-generator.tech
#

function Invoke-PSApiClient {
    [OutputType('System.Collections.Hashtable')]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$Uri,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$Accepts,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$ContentTypes,
        [Parameter(Mandatory)]
        [hashtable]$HeaderParameters,
        [Parameter(Mandatory)]
        [hashtable]$FormParameters,
        [Parameter(Mandatory)]
        [hashtable]$QueryParameters,
        [Parameter(Mandatory)]
        [hashtable]$CookieParameters,
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Body,
        [Parameter(Mandatory)]
        [string]$Method,
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$ReturnType
    )

    'Calling method: Invoke-PSApiClient' | Write-Debug
    $PSBoundParameters | Out-DebugParameter | Write-Debug

    $Configuration = Get-PSConfiguration
    $RequestUri = $Configuration["BaseUrl"] + $Uri
    $SkipCertificateCheck = $Configuration["SkipCertificateCheck"]

    # cookie parameters
    foreach ($Parameter in $CookieParameters.GetEnumerator()) {
        if ($Parameter.Name -eq "cookieAuth") {
            $HeaderParameters["Cookie"] = $Parameter.Value
        } else {
            $HeaderParameters[$Parameter.Name] = $Parameter.Value
        }
    }
    if ($CookieParameters -and $CookieParameters.Count -gt 1) {
        Write-Warning "Multipe cookie parameters found. Curently only the first one is supported/used"
    }

    # accept, content-type headers
    $Accept = SelectAcceptHeaders -Accepts $Accepts
    if ($Accept) {
        $HeaderParameters['Accept'] = $Accept
    }

    $ContentType= SelectContentTypeHeaders -ContentTypes $ContentTypes
    if ($ContentType) {
        $HeaderParameters['Content-Type'] = $ContentType
    }

    # add default headers if any
    foreach ($header in $Configuration["DefaultHeaders"].GetEnumerator()) {
        $HeaderParameters[$header.Name] = $header.Value
    }


    # constrcut URL query string
    $HttpValues = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
    foreach ($Parameter in $QueryParameters.GetEnumerator()) {
        if ($Parameter.Value.Count -gt 1) { // array
            foreach ($Value in $Parameter.Value) {
                $HttpValues.Add($Parameter.Key + '[]', $Value)
            }
        } else {
            $HttpValues.Add($Parameter.Key,$Parameter.Value)
        }
    }
    # Build the request and load it with the query string.
    $UriBuilder = [System.UriBuilder]($RequestUri)
    $UriBuilder.Query = $HttpValues.ToString()

    # include form parameters in the request body
    if ($FormParameters -and $FormParameters.Count -gt 0) {
        $RequestBody = $FormParameters
    }

    if ($Body) {
        $RequestBody = $Body
    }

    if ($SkipCertificateCheck -eq $true) {
        $Response = Invoke-WebRequest -Uri $UriBuilder.Uri `
                                  -Method $Method `
                                  -Headers $HeaderParameters `
                                  -Body $RequestBody `
                                  -ErrorAction Stop `
                                  -UseBasicParsing `
                                  -SkipCertificateCheck

    } else {
        $Response = Invoke-WebRequest -Uri $UriBuilder.Uri `
                                  -Method $Method `
                                  -Headers $HeaderParameters `
                                  -Body $RequestBody `
                                  -ErrorAction Stop `
                                  -UseBasicParsing
    }

    return @{
        Response = DeserializeResponse -Response $Response -ReturnType $ReturnType -ContentTypes $Response.Headers["Content-Type"]
        StatusCode = $Response.StatusCode
        Headers = $Response.Headers
    }
}

function SelectAcceptHeaders {
    Param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [String[]]$Accepts
    )

    foreach ($Accept in $Accepts) {
        if (IsJsonMIME -MIME $Accept) {
            return $Accept
        }
    }

    if (!($Accepts) -or $Accepts.Count -eq 0) {
        return $null
    } else {
        return $Accepts[0] # return the first one
    }
}

function SelectContentTypeHeaders {
    Param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [String[]]$ContentTypes
    )

    foreach ($ContentType in $ContentTypes) {
        if (IsJsonMIME -MIME $ContentType) {
            return $ContentType
        }
    }

    if (!($ContentTypes) -or $ContentTypes.Count -eq 0) {
        return $null
    } else {
        return $ContentTypes[0] # return the first one
    }
}

function IsJsonMIME {
    Param(
        [Parameter(Mandatory)]
        [string]$MIME
    )

    if ($MIME -match "(?i)^(application/json|[^;/ \t]+/[^;/ \t]+[+]json)[ \t]*(;.*)?$") {
        return $true
    } else {
        return $false
    }
}

function DeserializeResponse {
    Param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$ReturnType,
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Response,
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$ContentTypes
    )

    If ([string]::IsNullOrEmpty($ReturnType)) { # void response
        return $Response
    } Elseif ($ReturnType -match '\[\]$') { # array
        return ConvertFrom-Json $Response
    } Elseif (@("String", "Boolean", "System.DateTime") -contains $ReturnType) { # string, boolean ,datetime
        return $Response
    } Else { # others (e.g. model, file)
        if ($ContentTypes) {
            $ContentType = $null
            if ($ContentTypes.Count > 1) {
                $ContentType = SelectContentTypeHeaders -ContentTypes $ContentTypes
            } else {
                $ContentType = $ContentTypes[0]
            }

            if (IsJsonMIME -MIME $ContentType) {  # JSON
                return ConvertFrom-Json $Response
            } else { # XML, file, etc
                return $Response
            }
        } else { # no content type in response header, returning raw response
            return $Response
        }

    }
}
