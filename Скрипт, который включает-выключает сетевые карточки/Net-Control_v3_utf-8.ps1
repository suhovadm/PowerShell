# =========================
# Проверка администратора
# =========================
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Запусти PowerShell от администратора!" -ForegroundColor Red
    exit
}

# =========================
# Включаем UTF-8
# =========================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# =========================
# Получить активный адаптер
# =========================
function Get-ActiveAdapter {
    try {
        Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
            Sort-Object RouteMetric |
            Select-Object -First 1 |
            Get-NetAdapter
    } catch {
        return $null
    }
}

# =========================
# Фильтры адаптеров
# =========================
function Get-VirtualAdapters {
    Get-NetAdapter | Where-Object {
        $_.HardwareInterface -eq $false -or
        $_.InterfaceDescription -match "Virtual|VMware|Hyper-V|VBox|VPN|TAP"
    }
}

function Get-PhysicalAdapters {
    Get-NetAdapter | Where-Object {
        $_.HardwareInterface -eq $true -and
        $_.Status -ne "Unknown"
    }
}

# =========================
# Универсальное управление
# =========================
function Set-AdaptersState($adapters, $enable) {
    $active = Get-ActiveAdapter

    foreach ($adapter in $adapters) {

        if ($active -and $adapter.Name -eq $active.Name -and -not $enable) {
            Write-Host "Пропущен активный адаптер: $($adapter.Name)" -ForegroundColor Yellow
            continue
        }

        try {
            if ($enable) {
                Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                Write-Host "Включен: $($adapter.Name)" -ForegroundColor Green
            } else {
                Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                Write-Host "Отключен: $($adapter.Name)" -ForegroundColor DarkYellow
            }
        } catch {
            Write-Host "Ошибка: $($adapter.Name)" -ForegroundColor Red
        }
    }
}

# =========================
# Отображение адаптеров
# =========================
function Show-Adapters($title, $adapters, $color) {
    Write-Host "=== $title ===" -ForegroundColor $color

    $adapters | ForEach-Object {
        $ip = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
              Where-Object {$_.IPAddress -ne "127.0.0.1"} |
              Select-Object -ExpandProperty IPAddress -First 1)

        [PSCustomObject]@{
            Name        = $_.Name
            Description = $_.InterfaceDescription
            Status      = $_.Status
            IP          = $ip
            MAC         = $_.MacAddress
            Speed       = $_.LinkSpeed
        }
    } | Format-Table -AutoSize
}

# =========================
# Главное меню
# =========================
do {
    Clear-Host

    $physical = Get-PhysicalAdapters
    $virtual  = Get-VirtualAdapters

    Show-Adapters "Физические адаптеры" $physical "Green"
    Write-Host ""
    Show-Adapters "Виртуальные адаптеры" $virtual "Cyan"

    Write-Host "------------------------------------"
    Write-Host "Выберите действие:" -ForegroundColor White
    Write-Host "------------------------------------"
    Write-Host "1 - Отключить все адаптеры."
    Write-Host "2 - Включить все адаптеры."
    Write-Host "------------------------------------"
    Write-Host "3 - Отключить виртуальные адаптеры."
    Write-Host "4 - Включить виртуальные адаптеры."
    Write-Host "------------------------------------"
    Write-Host "5 - Отключить физические адаптеры."
    Write-Host "6 - Включить физические адаптеры."
    Write-Host "------------------------------------"
    Write-Host "7 - Перезапустить все адаптеры."
    Write-Host "------------------------------------"
    Write-Host "0 - Выход."
    Write-Host "------------------------------------"

    $choice = Read-Host "Ввод"

    switch ($choice) {
        "1" {
            Set-AdaptersState (Get-NetAdapter | Where-Object {$_.Status -ne "Disabled"}) $false
        }
        "2" {
            Set-AdaptersState (Get-NetAdapter | Where-Object {$_.Status -eq "Disabled"}) $true
        }
        "3" {
            Set-AdaptersState ($virtual | Where-Object {$_.Status -ne "Disabled"}) $false
        }
        "4" {
            Set-AdaptersState ($virtual | Where-Object {$_.Status -eq "Disabled"}) $true
        }
        "5" {
            Set-AdaptersState ($physical | Where-Object {$_.Status -ne "Disabled"}) $false
        }
        "6" {
            Set-AdaptersState ($physical | Where-Object {$_.Status -eq "Disabled"}) $true
        }
        "7" {
            try {
                Get-NetAdapter | Restart-NetAdapter -Confirm:$false
                Write-Host "Адаптеры перезапущены" -ForegroundColor Cyan
            } catch {
                Write-Host "Ошибка при перезапуске" -ForegroundColor Red
            }
        }
        "0" {
            Write-Host "Выход..." -ForegroundColor Gray
        }
        default {
            Write-Host "Неверный ввод" -ForegroundColor Red
        }
    }

    Start-Sleep -Seconds 2

} while ($choice -ne "0")