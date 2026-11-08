Как пробить открытые TCP и UDP порты в системе Windows ?  
Таким образом, мы увидим все TCP и UDP порты, которые открыты на машине.  

// Прогнать все TCP-порты компьютера, которые находятся в состоянии LISTEN.  

Get-NetTCPConnection -State Listen |  
Select-Object LocalAddress, LocalPort, OwningProcess, State  

// Показывает все локальные UDP-порты, которые используются приложениями и службами Windows.  

Get-NetUDPEndpoint |  
Select-Object LocalAddress, LocalPort, OwningProcess,  
    @{Name='State'; Expression={'UDP Endpoint'}}  
