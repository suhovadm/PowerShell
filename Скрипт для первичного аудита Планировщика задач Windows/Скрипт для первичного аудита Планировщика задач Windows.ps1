Get-ScheduledTask |
Where-Object {
    $_.Actions.Execute -and
    (
        $_.TaskPath -notlike '\Microsoft\*' -or
        $_.Actions.Execute -match 'cmd|powershell|pwsh|wscript|cscript|mshta|rundll32|regsvr32|\.bat|\.cmd|\.vbs|\.js|\.exe'
    )
} |
Select-Object TaskPath, TaskName,
    @{N='Execute';E={$_.Actions.Execute}},
    @{N='Arguments';E={$_.Actions.Arguments}},
    @{N='User';E={$_.Principal.UserId}},
    @{N='RunLevel';E={$_.Principal.RunLevel}} |
Format-List
