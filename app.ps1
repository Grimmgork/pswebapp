Add-Type -AssemblyName "System.Web"

$port = 8080

$url = "http://localhost:$($port)/"
$http = [System.Net.HttpListener]::new() 

$http.Prefixes.Add($url)
$http.Start()

$PSScriptRoot

if($http.IsListening){
    Write-Host "Running" -BackgroundColor Green -ForegroundColor White

    # navigate to main page ...
    Start-Process "$($url)static/index.html"
}

function Write-Response([System.Net.HttpListenerContext]$context, [string] $response, [int] $StatusCode = 200){
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($response)
    $context.Response.ContentLength64 = $buffer.Length
    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $context.Response.OutputStream.Close()
    $context.Response.StatusCode = $StatusCode
}

while ($http.IsListening) {
    
    # Cleanup of the path
    $context = $http.GetContext()
    $segments = $context.Request.RawUrl.Split("/")
    $segments = $segments.where({$_ -ne ""})
    $path = $segments -join "/"

    # Exit application
    # GET /mgzcli
    if ($context.Request.HttpMethod -eq 'GET' -and $segments[0] -eq 'mgzcli') {
        Write-Response $context "running mgzcli"
        break
    }

    # Exit application
    # GET /bye
    if ($context.Request.HttpMethod -eq 'GET' -and $segments[0] -eq 'bye') {
        Write-Response $context "Bye!"
        break
    }

    # Serve static files 
    # GET /static/*
    if ($context.Request.HttpMethod -eq 'GET' -and $segments[0] -eq 'static') {
        
        $path
        if(-not $(Evaluate-Path $path.replace('/',"\")).StartsWith($PSScriptRoot + '\static','CurrentCultureIgnoreCase')) {
            Write-Response $context "not found!" 404
            continue
        }
        
        $filepath = "./$($path)"
        if($(Test-Path -Path $filepath) -eq $false){
            Write-Response $context "not found!" 404
            continue
        }

        [string]$content = Get-Content "$($filepath)" -Raw
        Write-Response $context $content
        $context.Response.ContentType = [System.Web.MimeMapping]::GetMimeMapping($filepath)
        $context.Response.ContentType
        continue
    }

    Write-Response $context "not found!" 404
}
