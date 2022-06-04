Add-Type -AssemblyName "System.Web"

function Write-Response([System.Net.HttpListenerResponse]$response, [string] $content, [int] $StatusCode = 200){
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Close()
    $response.StatusCode = $StatusCode
    $response.AddHeader('Cache-Control', 'no-cache')
    $response.AddHeader('Cache-Control', 'no-store')
    $response.Close()
}

class State
{
    [ValidateNotNullOrEmpty()][byte]$opentabs
}

function Respond([System.Net.HttpListenerContext]$context, [State] $state){
     #print path to console
     $context.Request.RawUrl

     # Cleanup of the path
     $segments = $context.Request.RawUrl.Split("/")
     $segments = $segments.where({$_ -ne ""})
     $path = $segments -join "/"
 
     # Close tab
     # GET /bye
     if ($context.Request.HttpMethod -eq 'GET' -and $segments[0] -eq 'bye') {
         $state.opentabs = $state.opentabs - 1
 
         Write-Host "bye; $($state.opentabs) tabs"
         Write-Response $context.Response "bye" 200
         return
     }
 
     # Register new tab
     # GET /hello
     if ($context.Request.HttpMethod -eq 'GET' -and $segments[0] -eq 'hello') {
         $state.opentabs = $state.opentabs + 1
 
         Write-Host "Hello; $($state.opentabs) tabs"
 
         Write-Response $context.Response "hello" 200
         return
     }
 
     # Serve static files 
     # GET /static/*
     if ($context.Request.HttpMethod -eq 'GET' -and $segments[0] -eq 'static') {
        $staticDirectory = $PSScriptRoot + '\static'
        if(-not $(Resolve-Path $path.replace('/',"\")).ToString().StartsWith($staticDirectory,'CurrentCultureIgnoreCase')) {
            Write-Response $context.Response "not found!" 404
            return
        }
         
        $filepath = "./$($path)"
        if($(Test-Path -Path $filepath -PathType Leaf) -eq $false){
            Write-Response $context.Response "not found!" 404
            return
        }
 
        [string]$content = Get-Content "$($filepath)" -Raw
        $context.Response.ContentType = [System.Web.MimeMapping]::GetMimeMapping($filepath)
        Write-Response $context.Response $content
        return
    }
 
    Write-Response $context.Response "not found!" 404
}


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

    $state = [State]@{
        opentabs = 0
    }
    
    # run webserver loop
    while ($http.IsListening) {
        $task = $http.GetContextAsync()

        $end = $false
        $timeout = 10
        while (-not $task.AsyncWaitHandle.WaitOne(50)) {
            if($state.opentabs -lt 1){
                if($timeout -lt 1){
                    $end = $true
                    break
                }
                $timeout = $timeout -1
            }
        }

        if($end){
            break
        }

        $context = $task.GetAwaiter().GetResult()
        Respond $context $state
    }
}