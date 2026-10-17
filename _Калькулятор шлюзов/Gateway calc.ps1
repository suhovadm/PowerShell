# Принудительно включаем кодировку UTF-8!
$Utf8 = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = $Utf8

try {
    [Console]::InputEncoding = $Utf8
    [Console]::OutputEncoding = $Utf8
} catch {}

# История последних 100 введённых команд по команде history.
$historyList = [System.Collections.Generic.List[string]]::new()

function Add-HistoryEntry([string]$command) {
    $script:historyList.Add($command)

    if ($script:historyList.Count -gt 100) {
        $script:historyList.RemoveAt(0)
    }
}

function Read-InputCommand([string]$prompt) {
    while ($true) {
        $value = Read-Host $prompt
        Add-HistoryEntry $value

        switch ($value.Trim().ToLower()) {
            { $_ -in @("cls", "clear") } {
                Clear-Host
                continue
            }
            "history" {
                Write-Host ""
                if ($script:historyList.Count -eq 0) {
                    Write-Host "История пуста."
                }
                else {
                    $start = [Math]::Max(0, $script:historyList.Count - 100)
                    for ($i = $start; $i -lt $script:historyList.Count; $i++) {
                        Write-Host ("{0,3}. {1}" -f ($i + 1), $script:historyList[$i])
                    }
                }
                Write-Host ""
                continue
            }
            default {
                return $value
            }
        }
    }
}

# Основной цикл программы, крутится в while ($true)
while ($true) {
    $ip = Read-InputCommand "Введите IP-адрес"
    $maskInput = Read-InputCommand "Введите маску подсети (например, 28 или 255.255.255.240)"

    try {
        $ipObj = [System.Net.IPAddress]::Parse($ip)

        if ($ipObj.AddressFamily -ne
            [System.Net.Sockets.AddressFamily]::InterNetwork) {
            throw "Invalid IP"
        }

        if ($maskInput -match '^\d+$') {
            $prefix = [int]$maskInput

            if ($prefix -lt 1 -or $prefix -gt 30) {
                throw "Invalid mask"
            }

            $maskBits = ('1' * $prefix).PadRight(32, '0')
            $maskBytes = @(
                for ($i = 0; $i -lt 4; $i++) {
                    [Convert]::ToInt32($maskBits.Substring($i * 8, 8), 2)
                }
            )
        }
        else {
            $maskObj = [System.Net.IPAddress]::Parse($maskInput)

            if ($maskObj.AddressFamily -ne
                [System.Net.Sockets.AddressFamily]::InterNetwork) {
                throw "Invalid mask"
            }

            $maskBytes = $maskObj.GetAddressBytes()
            $bits = ($maskBytes | ForEach-Object {
                [Convert]::ToString($_, 2).PadLeft(8, '0')
            }) -join ''

            if ($bits -notmatch '^1*0*$') {
                throw "Invalid mask"
            }

            $prefix = $bits.TrimEnd('0').Length

            if ($prefix -lt 1 -or $prefix -gt 30) {
                throw "Invalid mask"
            }
        }

        $ipBytes = $ipObj.GetAddressBytes()
        $network = [byte[]]::new(4)
        $broadcast = [byte[]]::new(4)

        for ($i = 0; $i -lt 4; $i++) {
            $network[$i] = $ipBytes[$i] -band $maskBytes[$i]
            $broadcast[$i] = $network[$i] -bor (255 - $maskBytes[$i])
        }

        $netIP = [System.Net.IPAddress]::new($network).ToString()
        $maskText = [System.Net.IPAddress]::new([byte[]]$maskBytes).ToString()

        $firstBytes = [byte[]]$network.Clone()
        $firstBytes[3]++

        $lastBytes = [byte[]]$broadcast.Clone()
        $lastBytes[3]--

        $firstIP = [System.Net.IPAddress]::new($firstBytes).ToString()
        $lastIP = [System.Net.IPAddress]::new($lastBytes).ToString()

        Write-Host ""
        Write-Host "IP:                  	         $ip"
        Write-Host "Маска:               	         $maskText"
        Write-Host "Сеть:                	         $netIP"
        Write-Host "Первый доступный адрес шлюза:    $firstIP"
        Write-Host "Последний доступный адрес шлюза: $lastIP"
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "Некорректный IP-адрес или маска."
        Write-Host ""
    }
}
