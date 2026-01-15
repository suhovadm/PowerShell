Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | Select-Object `
    @{Name="Диск"; Expression={$_.DeviceID}},
    @{Name="Метка"; Expression={$_.VolumeName}},
    @{Name="Размер(ГБ)"; Expression={[math]::Round($_.Size/1GB, 2)}},
    @{Name="Свободно(ГБ)"; Expression={[math]::Round($_.FreeSpace/1GB, 2)}},
    @{Name="Свободно(%)"; Expression={[math]::Round(($_.FreeSpace/$_.Size)*100, 1)}} |
Format-Table -AutoSize