# Принудительно выставляем кодировку UTF-8.
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# Массив для истории вычислений
$history = @()
$maxHistory = 100  # Ограничение истории. Можно менять.

# Команды для очистки консоли - cls и clear. Можно вводить в обоих строках.
function Check-ClearCommand($userInput) {
    $cmd = $userInput.ToString().Trim().ToLower()
    if ($cmd -in @("cls","clear")) {
        Clear-Host
        return $true
    }
    return $false
}

# Команды для выхода из цикла - exit и quit. Можно вводить в обоих строках.
function Check-ExitCommand($userInput) {
    $cmd = $userInput.ToString().Trim().ToLower()
    if ($cmd -in @("exit","quit")) {
        return $true
    }
    return $false
}

# Команда для просмотра истории - history.
function Check-HistoryCommand($userInput) {
    $cmd = $userInput.ToString().Trim().ToLower()
    if ($cmd -eq "history") {
        if ($history.Count -eq 0) {
            Write-Host "История пуста." -ForegroundColor Yellow
        } else {
            Write-Host "=== История вычислений ===" -ForegroundColor Cyan
            $i = 1
            foreach ($item in $history) {
                Write-Host "$i) $item"
                $i++
            }
            Write-Host "==========================" -ForegroundColor Cyan
        }
        return $true
    }
    return $false
}

while ($true) {
    Write-Host ""
    Write-Host "=== Возведение в степень ===" # Заголовок.

    # Ввод числа
    $number = Read-Host "Введите число"

    if (Check-ExitCommand $number) { break }
    if (Check-ClearCommand $number) { continue }
    if (Check-HistoryCommand $number) { continue }

    # Ввод степени
    $power = Read-Host "Введите степень"

    if (Check-ExitCommand $power) { break }
    if (Check-ClearCommand $power) { continue }
    if (Check-HistoryCommand $power) { continue }

    # Преобразование в числа
    try {
        $num = [double]$number
        $pow = [double]$power
    } catch {
        Write-Host "Ошибка: введите корректные числовые значения." -ForegroundColor Red
        continue
    }

    # Вычисление
    $result = [math]::Pow($num, $pow)

    # Сохранение в историю с ограничением в 100 элементов
    $history += "$num ^ $pow = $result"
    if ($history.Count -gt $maxHistory) {
        $history = $history[-$maxHistory..-1]  # сохраняем последние 100 элементов
    }

    # Вывод результата
    Write-Host "Результат: $result" -ForegroundColor Green
}

Write-Host "Вы вышли в PowerShell." -ForegroundColor Yellow