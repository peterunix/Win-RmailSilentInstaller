Function _StopOutlookEXE{
    # Get's the process ID of Outlook, kills it, then waits for it to terminate
                $ids=(Get-Process -Name outlook*).id
    foreach ($id in $ids){
                        Stop-Process -Force $id 2>&1 | out-null
                        Wait-Process -Id $id 2>&1 | out-null
    }
}

Function _DetectOfficeVersion{
                # That registry exists for newer versions of office. It'll try and pull the OS archicecture from it.
                # It'll explicitly set the officeIs64Bit to true or false respectivley
    $office=Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' 2> $null
    if ($? -eq $true){
        if ($office.Platform -match "x64"){Write-Host "64Bit detected."; $Global:officeIs64Bit=$true}
        if ($office.Platform -match "x86"){Write-Host "32Bit detected."; $Global:officeIs64Bit=$false}
    } else{
        Write-Host "Couldn't detect office version. Assuming 32bit. Tell Peter to fix this!"
        $Global:officeIs64Bit = $false
    }
}

Function _Uninstallrmail{
    # Uninstalls rmail if it's installed. It fishes the registry to find the uninstall string.
                # It takes a little bit of data manipulation to get working, but it passes it to msiexec for the uninstall
    try{
        (($Global:progs | Where {$_.displayname -match "RMail"}).uninstallstring) -match "{.*.}"
        Write-Host "Uninstalling Rmail"
        Start-Process "msiexec.exe" -ArgumentList "/X $($matches[0]) /qn" -Wait
        Write-Host "UNINSTALLED!"
    } catch {
        Write-Host "A previous Rmail installation was not detected"
    }

                # Removing the local user config files for RMail
    Write-Host "Removing the local user Rmail configuration file"
    Remove-Item -Recurse -Force -Path C:\Users\*\Appdata\Roaming\RMail\
    Write-Host "REMOVED!"
}

Function _InstallRmail{
    # Downloads and installs either the 32bit or 64bit version of Rmail
    if ($officeIs64Bit -eq $true){
        Write-Host "Downloading Rmail 64Bit"
        Invoke-WebRequest -Uri "https://rpost.com/applications/rmail-for-outlook-desktop-64-bit.msi" -OutFile "$env:temp/rmail.msi" -UseBasicParsing
        Write-Host "DOWNLOADED!"
    } else{
        Write-Host "Downloading Rmail 32Bit"
        Invoke-WebRequest -Uri "https://rpost.com/applications/rmail-for-outlook-desktop-32-bit.msi" -OutFile "$env:temp/rmail.msi" -UseBasicParsing
        Write-Host "DOWNLOADED!"
    }

    Write-Host "Installing Rmail"
    Start-Process "$env:temp\rmail.msi" -ArgumentList "/qn" -Wait
    Write-Host "INSTALLED!"
}

Function _Main{
    $ProgressPreference="SilentlyContinue"
                # These two keys contain all of the information for the installed system programs.
                # It includes uninstall strings, install paths, versions, display names, etc.
    $Global:progs=Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty
    _StopOutlookEXE
    _DetectOfficeVersion
    _UninstallRmail
    _InstallRmail
}
