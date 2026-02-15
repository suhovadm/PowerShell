# Включаем UTF-8.
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Получаем список процессов один раз (быстрее чем Get-Process в цикле).
$processMap = @{ }
Get-Process | ForEach-Object {
    $processMap[$_.Id] = $_.ProcessName
}

# Получаем Established соединения.
$connections = Get-NetTCPConnection -State Established

# Быстро формируем объекты.
$result = foreach ($conn in $connections) {

    # Берём имя процесса из карты, если нет — получаем напрямую.
    $processName = if ($processMap[$conn.OwningProcess]) {
        $processMap[$conn.OwningProcess]
    } else {
        (Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue).ProcessName
    }

    # Подсказка - какие сервисы на каких портах висят.
    $hint = switch ($conn.LocalPort) {
        1080  {"SOCKS5 прокси (V2Ray / Xray / Shadowsocks / Clash / SSH -D)"}
        8388  {"Shadowsocks сервер"}
        7890  {"Clash HTTP proxy"}
        7891  {"Clash SOCKS proxy"}
        443   {"HTTPS (VPN / прокси поверх TLS)"}
        1194  {"OpenVPN"}
        51820 {"WireGuard"}
        default {"Обычное TCP соединение"}
    }

    [PSCustomObject]@{
        LocalAddress  = $conn.LocalAddress
        LocalPort     = $conn.LocalPort
        RemoteAddress = $conn.RemoteAddress
        RemotePort    = $conn.RemotePort
        Process       = $processName
        Hint          = $hint
    }
}

# Группировка и вывод.
# Жёлтый - это подсветка надписи "Узел: такой-то".
# Тёмно-серый - это строчки типа "равно" над и под выводом узла.
$result | Group-Object LocalAddress | ForEach-Object {

    Write-Host "`n==============================" -ForegroundColor DarkGray
    Write-Host "Узел: $($_.Name)" -ForegroundColor Yellow
    Write-Host "==============================" -ForegroundColor DarkGray

    $_.Group | Format-Table -AutoSize
}