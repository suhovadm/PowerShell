# Получаем всех локальных пользователей
$users = Get-LocalUser

# Получаем SID встроенной группы Administrators (S-1-5-32-544)
$adminGroupSID = "S-1-5-32-544"

# Получаем участников группы администраторов ОДИН раз
$adminMembers = Get-LocalGroupMember -SID $adminGroupSID -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty SID

$result = foreach ($user in $users) {

    # Проверяем по SID, входит ли пользователь в Administrators
    $isAdmin = $adminMembers -contains $user.SID

    if ($isAdmin) {
        $groups = "Administrators"
        $role = "Администратор"
    } else {
        $groups = ""
        $role = "Обычный пользователь"
    }

    # Понятные статусы пароля
    if (-not $user.PasswordRequired) {
        $passwordInfo = "Не установлен"
    }
    elseif ($user.PasswordNeverExpires) {
        $passwordInfo = "Установлен и не истекает"
    }
    else {
        $passwordInfo = "Установлен и истекает"
    }

    [PSCustomObject]@{
        Пользователь     = $user.Name
        Включён          = $user.Enabled
        "Последний вход" = $user.LastLogon
        Пароль           = $passwordInfo
        Группы           = $groups
        Права            = $role
    }
}

# Цветной вывод таблицы, не меняя структуру
$columns = $result | Format-Table -AutoSize | Out-String -Width 4096
foreach ($line in $columns -split "`n") {
    if ($line -match "Администратор") {
        Write-Host $line -ForegroundColor Green
    } else {
        Write-Host $line
    }
}