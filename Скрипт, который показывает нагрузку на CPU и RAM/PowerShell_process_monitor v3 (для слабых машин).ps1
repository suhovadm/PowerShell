# Минималистичная версия, для слабых машин.

# Включаем UTF-8, чтобы корректно отображались русские символы
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Интервал обновления (в секундах)
$interval = 10

# Основной бесконечный цикл мониторинга
while ($true) {

    # Очистка экрана перед обновлением
    Clear-Host

    # Установка курсора в верхний левый угол консоли
    [console]::SetCursorPosition(0, 0)
    
    # Получаем список процессов и формируем удобные поля
    # Select-Object создаёт новые вычисляемые свойства
    $processes = Get-Process | Select-Object Name, Id, 
        
        # CPU время процесса (округляем до 2 знаков)
        @{N='CPU';E={[math]::Round($_.CPU, 2)}}, 
        
        # Используемая память в мегабайтах
        @{N='RAM(MB)';E={[math]::Round($_.WorkingSet64/1MB, 2)}},
        
        # Количество потоков процесса
        @{N='Threads';E={$_.Threads.Count}}
    
    # -----------------------------
    # TOP процессов по CPU
    # -----------------------------
    
    Write-Host "`n=== TOP 10 CPU ===" -ForegroundColor Cyan
    
    # Сортируем процессы по CPU и выводим первые 10
    $processes |
        Sort-Object CPU -Descending |
        Select-Object -First 10 |
        Format-Table -AutoSize
    
    # -----------------------------
    # TOP процессов по RAM
    # -----------------------------
    
    Write-Host "`n=== TOP 10 RAM ===" -ForegroundColor Cyan
    
    # Сортируем процессы по использованию памяти
    $processes |
        Sort-Object 'RAM(MB)' -Descending |
        Select-Object -First 10 |
        Format-Table -AutoSize
    
    # Пауза перед следующим обновлением
    Start-Sleep -Seconds $interval
}