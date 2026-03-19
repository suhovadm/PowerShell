# Скрипт для перевода чисел в двоичную систему.
# Выход из цикла — Ctrl + C.
# cls и clear для очистки консоли.
# Можно вводить сразу несколько чисел через пробел.

while ($true) {
    $input = Read-Host "Введите одно или несколько целых чисел через пробел для перевода в двоичное.`n[ Ctrl + C для выхода / cls или clear для очистки консоли ]"

    # Пропуск пустого ввода
    if ([string]::IsNullOrWhiteSpace($input)) {
        continue
    }

    # Очистка консоли
    if ($input.Trim().ToLower() -in @("cls", "clear")) {
        Clear-Host
        continue
    }

    # Разбиваем ввод
    $numbers = $input -split "\s+"

    foreach ($num in $numbers) {
        [long]$parsed = 0

        # Проверка числа
        if (-not [long]::TryParse($num, [ref]$parsed)) {
            Write-Host "'$num' — Что-то не то! Попробуйте ещё разок." -ForegroundColor Yellow
            continue
        }

        # Перевод в двоичную систему (с нормальной обработкой отрицательных)
        if ($parsed -lt 0) {
            $binary = "-" + [Convert]::ToString([math]::Abs($parsed), 2)
        } else {
            $binary = [Convert]::ToString($parsed, 2)
        }

        # Вывод
        Write-Host ("{0,15} (десятичное) = {1,30} (двоичное)" -f $parsed, $binary) -ForegroundColor Cyan
    }

    # Разделитель между итерациями
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
}