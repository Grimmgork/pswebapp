$url = "http://localhost:8080/"
$http = [System.Net.HttpListener]::new() 

$http.Prefixes.Add($url)
$http.Start()

if($http.IsListening){
    Write-Host "Running" -BackgroundColor Green -ForegroundColor White
    Start-Process "$($url)/static/index.html"
}

function Write-Response([System.Net.HttpListenerContext]$context, [string] $response, [int] $StatusCode = 200){
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($response)
    $context.Response.ContentLength64 = $buffer.Length
    $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $context.Response.OutputStream.Close()
    $context.Response.StatusCode = $StatusCode
}

while ($http.IsListening) {

    $context = $http.GetContext()
    $segments = $context.Request.RawUrl.Split("/")
    $segments = $segments.where({$_ -ne ""})
    $segments = $segments.where({$_ -ne ".."})
    $segments = $segments.where({$_ -ne "."})
    $path = $segments -join "/"

    if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/bye') {
        Write-Response $context "Bye!"
        break
    }

    if ($context.Request.HttpMethod -eq 'GET' -and $segments[0] -eq 'static') {
        [string]$html = Get-Content "./$($path)" -Raw
        Write-Response $context $html
        continue
    }

    Write-Response $context "not found!" 404
}