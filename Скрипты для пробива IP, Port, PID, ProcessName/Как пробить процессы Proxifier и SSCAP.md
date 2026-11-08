```  
Get-Process |  
Where-Object {$_.ProcessName -match 'proxifier|sscap'} |  
Select-Object ProcessName,Id,Path  
```  
