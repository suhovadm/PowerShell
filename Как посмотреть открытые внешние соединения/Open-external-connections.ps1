Get-NetTCPConnection | 
Where-Object {$_.State -eq "Established"} |
Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State |
Group-Object LocalAddress | ForEach-Object {
    Write-Host "`nУзел: $($_.Name)" -ForegroundColor Yellow
    $_.Group | Format-Table -AutoSize
}
