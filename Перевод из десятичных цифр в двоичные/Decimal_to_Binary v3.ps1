# Скрипт для перевода чисел в двоичную систему.
# Выход из цикла — Ctrl + C.
# cls и clear для очистки консоли.
# Можно вводить сразу несколько чисел через пробел.
# Можно вводить отрицательные и дробные числа через точку и через запятую.

# Количество знаков после запятой (можно менять).
$precision = 10

while ($true) {
    $input = Read-Host "Введите одно или несколько целых чисел через пробел для перевода в двоичное.`n[ Ctrl + C для выхода / cls или clear для очистки консоли ]"

    # Пропуск пустого ввода.
    if ([string]::IsNullOrWhiteSpace($input)) {
        continue
    }

    # Очистка консоли через cls и через clear.
    if ($input.Trim().ToLower() -in @("cls", "clear")) {
        Clear-Host
        continue
    }

    # Разбиваем ввод.
    $numbers = $input -split "\s+"

    foreach ($num in $numbers) {
        [decimal]$parsed = 0

        # Замена запятой на точку.
        $normalized = $num -replace ",", "."

        # Проверка, что введено именно число, а не что-то другое.
        try {
            $parsed = [decimal]::Parse($normalized, [System.Globalization.CultureInfo]::InvariantCulture)
        } catch {
            Write-Host "'$num' — Что-то не то! Попробуйте ещё разок." -ForegroundColor Yellow
            continue
        }

        $isNegative = $parsed -lt 0
        $absValue = [math]::Abs($parsed)

        $integerPart = [math]::Floor($absValue)
        $fractionPart = $absValue - $integerPart

        # Перевод целой части (было!) 
        # Этот метод работает только с обычными целыми типами - int, long,
        # но не умеет работать с большими числами типа decimal и BigInteger.
        # $intBinary = [Convert]::ToString([long]$integerPart, 2)
        
        # Стало: перевод целой части (поддержка очень больших чисел!)
        # Не зависит от int64, остаётся тот же decimal и логика по сути та же - деление на 2.
        $tempInt = [decimal]$integerPart
        $intBinary = ""

        if ($tempInt -eq 0) {
            $intBinary = "0"
        } else {
            while ($tempInt -gt 0) {
                $remainder = [int]($tempInt % 2)
                $intBinary = "$remainder$intBinary"
                $tempInt = [math]::Floor($tempInt / 2)
            }
        }

        # Перевод дробной части.
        $fracBinary = ""
        $count = 0

        while ($fractionPart -gt 0 -and $count -lt $precision) {
            $fractionPart *= 2

            if ($fractionPart -ge 1) {
                $fracBinary += "1"
                $fractionPart -= 1
            } else {
                $fracBinary += "0"
            }

            $count++
        }

        if ($fracBinary.Length -gt 0) {
            $binary = "$intBinary.$fracBinary"
        } else {
            $binary = $intBinary
        }

        if ($isNegative) {
            $binary = "-$binary"
        }

        # Вывод.
        Write-Host ("{0,15} (десятичное) = {1,30} (двоичное)" -f $parsed, $binary) -ForegroundColor Cyan
    }

    # Разделитель между итерациями.
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}