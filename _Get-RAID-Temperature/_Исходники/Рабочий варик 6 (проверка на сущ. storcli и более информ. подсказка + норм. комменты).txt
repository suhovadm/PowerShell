# Версия 6. Более информативная подсказка и проверка на существование storcli как таковой.

# Принудительное включение UTF-8 для PowerShell.
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Иконка в трее. Показывает температуру!
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Путь, откуда цепляется утилита для управления RAID-контроллером - storcli64.exe
$StorCliPath = "C:\storcli64.exe"

# Проверка существования storcli64.exe как таковой.
if (-not (Test-Path $StorCliPath)) {
    [System.Windows.Forms.MessageBox]::Show("storcli64.exe не найден по пути:`n$StorCliPath`n`nСкрипт будет завершен.", "Ошибка", "OK", "Error")
    exit
}

# ВАЖНО:
# Все данные получаются через storcli (CLI), который вызывается через cmd.exe.
# Далее вывод парсится через regex — формат может отличаться в разных версиях storcli!

# Функция получения температуры через PowerShell из cmd-шки.
function Get-RAIDTemperature {
    try {
        # Получаем вывод storcli и фильтруем строки с температурой через findstr
        $output = & cmd.exe /c "`"$StorCliPath`" /c0 show all | findstr /i temp" 2>$null
        if ($output) {
            # Извлекаем первое число из строки (температура)
            $tempValue = [regex]::Match($output, '\d+').Value
            if ($tempValue) { return $tempValue }
        }
        return $null
    }
    catch { return $null }
}

# Функция получения количества дисков.
function Get-DriveCount {
    try {
        # Получаем список всех физических дисков (enclosure/slot)
        $output = & cmd.exe /c "`"$StorCliPath`" /c0/eall/sall show" 2>$null
        if ($output) {
            # Парсим строки вида:
            # E:S DID State ... Size (TB/GB/MB)
            $driveLines = $output | Select-String -Pattern "^\s*\d+:\d+\s+\d+\s+\w+\s+[-]?\s+[\d\.]+\s+(?:TB|GB|MB)" -AllMatches
            if ($driveLines) {
                # Количество найденных строк = количество дисков
                return $driveLines.Count
            }
        }
        return $null
    }
    catch { return $null }
}

# Функция получения статуса физических дисков (Online, Degraded, Offline и т.д.).
function Get-DriveStatus {
    try {
        # Получаем тот же список дисков
        $output = & cmd.exe /c "`"$StorCliPath`" /c0/eall/sall show" 2>$null
        if ($output) {
            # Извлекаем поле статуса (Onln, Dgrd, Offln и т.д.)
            $driveLines = $output | Select-String -Pattern "^\s*\d+:\d+\s+\d+\s+(\w+)\s+" -AllMatches
            if ($driveLines) {
                $statuses = @()
                
                foreach ($line in $driveLines) {
                    $match = [regex]::Match($line.Line, "^\s*\d+:\d+\s+\d+\s+(\w+)\s+")
                    if ($match.Success -and $match.Groups.Count -ge 2) {
                        $rawStatus = $match.Groups[1].Value

                        # Маппинг внутренних кодов storcli -> человекочитаемые статусы
                        # storcli использует сокращения (Onln, Dgrd, Offln и т.д.)
                        switch ($rawStatus) {
                            "JBOD"   { $status = "Online" }
                            "Onln"   { $status = "Online" }
                            "Dgrd"   { $status = "Degraded" }
                            "Offln"  { $status = "Offline" }
                            "Rbld"   { $status = "Rebuilding" }
                            "UBad"   { $status = "Bad" }
                            default  { $status = $rawStatus }
                        }
                        $statuses += $status
                    }
                }
                
                if ($statuses.Count -gt 0) {
                    # Подсчет различных состояний
                    $onlineCount = ($statuses | Where-Object { $_ -eq "Online" }).Count
                    $degradedCount = ($statuses | Where-Object { $_ -eq "Degraded" }).Count
                    $offlineCount = ($statuses | Where-Object { $_ -eq "Offline" }).Count
                    $rebuildingCount = ($statuses | Where-Object { $_ -eq "Rebuilding" }).Count
                    $totalCount = $statuses.Count

                    # Приоритет отображения статусов:
                    # Degraded > Offline > Rebuilding > OK
                    if ($degradedCount -gt 0) {
                        return "[WARN] $onlineCount/$totalCount Online, $degradedCount Degraded"
                    } elseif ($offlineCount -gt 0) {
                        return "[ERROR] $onlineCount/$totalCount Online, $offlineCount Offline"
                    } elseif ($rebuildingCount -gt 0) {
                        return "[INFO] $onlineCount/$totalCount Online, $rebuildingCount Rebuilding"
                    } else {
                        return "[OK] $onlineCount/$totalCount Online"
                    }
                }
            }
        }
        return $null
    }
    catch { return $null }
}

# Функция получения режима RAID (JBOD, RAID0, RAID1, RAID5, RAID6 и т.д.).
function Get-RAIDMode {
    try {
        # Проверяем, есть ли вообще виртуальные диски (VD)
        $vdCheck = & cmd.exe /c "`"$StorCliPath`" /c0/vall show" 2>$null
        if ($vdCheck -match "No VDs have been configured") {
            return "JBOD"
        }
        
        $output = & cmd.exe /c "`"$StorCliPath`" /c0 show all" 2>$null
        if ($output) {
            # Пытаемся найти RAID уровни в строках с VD (Virtual Drives)
            # Используем несколько шаблонов, так как формат вывода storcli нестабилен
            $raidMatch = $output | Select-String -Pattern "(VD\d+.*?RAID[01256]|RAID[01256].*?VD\d+)" -AllMatches
            if ($raidMatch) {
                $modes = @()
                foreach ($line in $raidMatch) {
                    $matches = [regex]::Matches($line.Line, "RAID[01256]")
                    foreach ($match in $matches) {
                        $mode = $match.Value
                        if ($mode -and ($modes -notcontains $mode)) {
                            $modes += $mode
                        }
                    }
                }
                if ($modes.Count -gt 0) {
                    $modesString = $modes -join ", "

                    # Ограничиваем длину строки, чтобы влезло в tooltip
                    if ($modesString.Length -gt 25) {
                        $modesString = $modesString.Substring(0, 22) + "..."
                    }
                    return $modesString
                }
            }
            
            # Fallback: ищем RAID через более общий шаблон (если верхний не сработал)
            $typeMatch = $output | Select-String -Pattern "(?i)(TYPE|RAID Level|RAID)\s*:?\s*(RAID[01256]|JBOD)" -AllMatches
            if ($typeMatch) {
                foreach ($match in $typeMatch) {
                    if ($match.Matches.Groups.Count -ge 3) {
                        $mode = $match.Matches.Groups[2].Value
                        if ($mode) { return $mode }
                    }
                }
            }
        }
        return $null
    }
    catch { return $null }
}

# Функция создания иконки с текстом температуры.
function Create-TemperatureIcon {
    param([string]$tempText)
    
    # Создаем изображение 16x16 с прозрачным фоном.
    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)

    # Прозрачный фон (без белого цвета и рамки).
    $graphics.Clear([System.Drawing.Color]::Transparent)
    
    # Выбираем цвет текста в зависимости от температуры.
    if ($tempText -match '\d+') {
        $tempNum = [int]$matches[0]
        if ($tempNum -ge 80) { 
            $textColor = [System.Drawing.Color]::Red # Больше 80 градусов Цельсия - красный.
        } elseif ($tempNum -ge 70) { 
            $textColor = [System.Drawing.Color]::Orange # Больше 70 градусов Цельсия - оранж.
        } else { 
            $textColor = [System.Drawing.Color]::White # По дефолту - белый.
        }
    } else {
        $textColor = [System.Drawing.Color]::Gray # Если какая-то ошибка или отсутствие данных - серый.
    }
    
    # Максимально возможный размер шрифта для 16x16 - Arial, 12, жирный.
    $font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush($textColor)

    # Центрируем текст.
    $stringFormat = New-Object System.Drawing.StringFormat
    $stringFormat.Alignment = [System.Drawing.StringAlignment]::Center
    $stringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
    
    # Рисуем текст на маленьком изображении - 16x16 пикселей, которое потом превращается в иконку для трея.
    $graphics.DrawString($tempText, $font, $brush, 8, 8, $stringFormat)
    
    # Освобождаем ресурсы.
    $font.Dispose()
    $brush.Dispose()
    $stringFormat.Dispose()
    $graphics.Dispose()
    
    # Конвертируем bitmap в иконку (через handle)
    $handle = $bmp.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($handle)
    $bmp.Dispose()
    
    # Освобождаем handle, чтобы не было утечки ресурсов.
    $null = [System.Runtime.InteropServices.Marshal]::Release($handle)
    
    return $icon
}

# Создаем иконку в трее.
$icon = New-Object System.Windows.Forms.NotifyIcon
$icon.Visible = $true
$icon.Text = "RAID Controller Temperature"

# Функция обновления иконки и подсказки.
function Update-RAIDIcon {
    $temp = Get-RAIDTemperature
    $driveCount = Get-DriveCount
    $driveStatus = Get-DriveStatus
    $raidMode = Get-RAIDMode

    # Создаем новую иконку с температурой
    if ($temp) {
        $newIcon = Create-TemperatureIcon -tempText "$temp"
        $oldIcon = $icon.Icon
        $icon.Icon = $newIcon
        if ($oldIcon) { $oldIcon.Dispose() }

        # Формируем tooltip (подсказку)
        $tooltipText = "RAID: $temp°C"
        if ($driveCount) {
            $tooltipText += "`nДисков: $driveCount"
        }
        if ($driveStatus) {
            $tooltipText += "`nСтатус: $driveStatus"
        }
        if ($raidMode) {
            $tooltipText += "`nРежим: $raidMode"
        }
        
        # Ограничение NotifyIcon.Text — примерно 63 символа
        if ($tooltipText.Length -gt 63) {
            $tooltipText = $tooltipText.Substring(0, 60) + "..."
        }
        $icon.Text = $tooltipText
    } else {
        # Если ошибка, показываем "ERR"
        $newIcon = Create-TemperatureIcon -tempText "ERR"
        $oldIcon = $icon.Icon
        $icon.Icon = $newIcon
        if ($oldIcon) { $oldIcon.Dispose() }
        
        $tooltipText = "RAID: Ошибка"
        if ($driveCount) {
            $tooltipText += "`nДисков: $driveCount"
        }
        if ($driveStatus) {
            $tooltipText += "`nСтатус: $driveStatus"
        }
        if ($raidMode) {
            $tooltipText += "`nРежим: $raidMode"
        }
        
        # Ограничение длины tooltip
        if ($tooltipText.Length -gt 63) {
            $tooltipText = $tooltipText.Substring(0, 60) + "..."
        }
        $icon.Text = $tooltipText
    }
}

# [ Меню при правом клике. ]

# Выход.
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem.Text = "Выход"
$exitMenuItem.Add_Click({ 
    $icon.Visible = $false
    $icon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})
$menu.Items.Add($exitMenuItem)

# Обновить.
$refreshMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$refreshMenuItem.Text = "Обновить сейчас"
$refreshMenuItem.Add_Click({ Update-RAIDIcon })
$menu.Items.Add($refreshMenuItem)

$icon.ContextMenuStrip = $menu

# Таймер обновления иконки.
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 30000 # Обновляем температуру каждые 30 сек.
$timer.Add_Tick({ Update-RAIDIcon })
$timer.Start()

# Запускаем первое обновление.
Update-RAIDIcon

# Запускаем цикл приложения (обработчик событий WinForms).
[System.Windows.Forms.Application]::Run()

# После завершения скрипта автоматически нажимаем Enter и переходим на новую строку.
[System.Console]::WriteLine()
