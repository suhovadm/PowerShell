@echo off

:: Проверка прав администратора.
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Запуск с правами администратора...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb runAs -WindowStyle Minimized"
    exit
)

:: Сворачиваем текущее окно
powershell -Command "(Get-Process -Id $PID).MainWindowHandle | ForEach-Object {Add-Type '[DllImport(\"user32.dll\")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);' -Name Win32ShowWindowAsync -Namespace Win32Functions; [Win32Functions.Win32ShowWindowAsync]::ShowWindowAsync($_, 2)}"

:: Запуск.
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Get-RAID-Temperature_v6_utf-8_+enter.ps1"

exit
