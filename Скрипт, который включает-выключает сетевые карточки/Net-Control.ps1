function Get-VirtualAdapters {
    # Только виртуальные адаптеры (VirtualBox, VMware, Hyper-V, VPN, TAP)
    Get-NetAdapter | Where-Object {
        $_.InterfaceDescription -match "Virtual|VMware|Hyper-V|VBox|VPN|TAP"
    }
}

function Get-PhysicalAdapters {
    # Только реальные физические адаптеры
    Get-NetAdapter | Where-Object {
        ($_.InterfaceDescription -notmatch "Virtual|VMware|Hyper-V|VBox|VPN|TAP|WAN Miniport|Bluetooth|Teredo|6to4|IP-HTTPS")
    }
}

while ($true) {
    Clear-Host

    # Физические адаптеры
    Write-Host "=== Физические адаптеры ==="
    Get-PhysicalAdapters | 
        Select-Object Name, InterfaceDescription, Status, MacAddress, LinkSpeed |
        Format-Table -AutoSize

    Write-Host ""
    # Виртуальные адаптеры с полным MAC и статусом
    Write-Host "=== Виртуальные адаптеры ==="
    Get-VirtualAdapters | ForEach-Object {
        [PSCustomObject]@{
            Name                 = $_.Name
            InterfaceDescription = $_.InterfaceDescription
            Status               = $_.Status
            MacAddress           = $_.MacAddress
            LinkSpeed            = $_.LinkSpeed
        }
    } | Format-Table -AutoSize

    Write-Host ""
    Write-Host "Выберите действие:"
    Write-Host "1 - Отключить все адаптеры"
    Write-Host "2 - Включить все адаптеры"
    Write-Host "------------------------------------"
    Write-Host "3 - Отключить виртуальные адаптеры"
    Write-Host "4 - Включить виртуальные адаптеры"
    Write-Host "------------------------------------"
    Write-Host "5 - Отключить все физические адаптеры"
    Write-Host "6 - Включить все физические адаптеры"
    Write-Host "------------------------------------"
    Write-Host "0 - Выход"
    Write-Host "------------------------------------"

    $choice = Read-Host "Ввод"

    switch ($choice) {
        "1" {
            Get-NetAdapter | Where-Object {$_.Status -ne "Disabled"} | ForEach-Object {
                Disable-NetAdapter -Name $_.Name -Confirm:$false
            }
            Write-Host "Все адаптеры отключены"
        }
        "2" {
            Get-NetAdapter | Where-Object {$_.Status -eq "Disabled"} | ForEach-Object {
                Enable-NetAdapter -Name $_.Name -Confirm:$false
            }
            Write-Host "Все адаптеры включены"
        }
        "3" {
            Get-VirtualAdapters | Where-Object {$_.Status -ne "Disabled"} | ForEach-Object {
                Disable-NetAdapter -Name $_.Name -Confirm:$false
            }
            Write-Host "Виртуальные адаптеры отключены"
        }
        "4" {
            Get-VirtualAdapters | Where-Object {$_.Status -eq "Disabled"} | ForEach-Object {
                Enable-NetAdapter -Name $_.Name -Confirm:$false
            }
            Write-Host "Виртуальные адаптеры включены"
        }
        "5" {
            Get-PhysicalAdapters | Where-Object {$_.Status -ne "Disabled"} | ForEach-Object {
                Disable-NetAdapter -Name $_.Name -Confirm:$false
            }
            Write-Host "Физические адаптеры отключены"
        }
        "6" {
            Get-PhysicalAdapters | Where-Object {$_.Status -eq "Disabled"} | ForEach-Object {
                Enable-NetAdapter -Name $_.Name -Confirm:$false
            }
            Write-Host "Физические адаптеры включены"
        }
        "0" {
            Write-Host "Выход из скрипта..."
            return  # Завершает скрипт полностью
        }
        default {
            Write-Host "Неверный ввод"
        }
    }

    Start-Sleep -Seconds 2
}