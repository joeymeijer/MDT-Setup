<#PSScriptInfo

.VERSION YY.MM.DD

.GUID

.AUTHOR Mike Galvin Contact: mike@gal.vin / twitter.com/mikegalvin_ / discord.gg/5ZsnJ5k

.COMPANYNAME Mike Galvin

.COPYRIGHT (C) Mike Galvin. All rights reserved.

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#
    .SYNOPSIS
    Install and configure MDT

    .DESCRIPTION
    Installs and configures MDT on a new domain joined server with an internet connection.
#>

## Set up command line switches.
[CmdletBinding()]
Param(
    [switch]$Help)

    Write-Host -ForegroundColor Yellow -BackgroundColor Black -Object "
     __   __  ______   _______         _______  _______  _______  __   __  _______     
    |  |_|  ||      | |       |       |       ||       ||       ||  | |  ||       |    
    |       ||  _    ||_     _| ____  |  _____||    ___||_     _||  | |  ||    _  |    
    |       || | |   |  |   |  |____| | |_____ |   |___   |   |  |  |_|  ||   |_| |    
    |       || |_|   |  |   |         |_____  ||    ___|  |   |  |       ||    ___|    
    | ||_|| ||       |  |   |          _____| ||   |___   |   |  |       ||   |        
    |_|   |_||______|   |___|         |_______||_______|  |___|  |_______||___|        
                                                                                       
            Mike Galvin   https://gal.vin                  Version XX.XX.XX            
      Donate: https://www.paypal.me/digressive            See -help for usage          
"

If ($Help)
{
    Write-Host -Object "Usage:
    From a terminal run: [path\]MDT-Setup.ps1
    Answer the questions, the default option is capatilized. eg. y/N - no is the default."
}

else {
    $Begin = Read-Host -Prompt "Would you like to begin the MDT installation process? (y/N)"
    If ($Begin -eq '')
    {
        $Begin = "n"
    }

    If ($Begin -eq "y")
    {
        ## User Preferences
        $WinCode = Read-Host -Prompt "Enter Windows version and update that you will be deploying (default: W10-21H2)"
        If ($WinCode -eq '')
        {
            $WinCode = "W10-21H2" ## Windows version and update)
        }

        ## Windows Download Preferences
        ## If you already have your own Windows source files then you should import that to the Build share as an OS
        $ConvertESD = Read-Host -Prompt "Do you want to download and convert the Windows 10 ESD to a WIM? (y/N)"
        If ($ConvertESD -eq '')
        {
            $ConvertESD = "n" ## Set this to "y" to have the script download Windows and convert the ESD to a WIM for MDT
        }

        If ($ConvertESD -eq "y")
        {
            $LangCode = Read-Host -Prompt "Enter the language code of the Windows download (default: en-gb)"
            If ($LangCode -eq '')
            {
                $LangCode = "en-gb" ## The language of the Windows to download. Example: en-US
            }

            $Edition = Read-Host -Prompt "Enter the edition to download (default: enterprise)"
            If ($Edition -eq '')
            {
                $Edition = "Enterprise" ## The edition to download
            }

            $DemoKey = Read-Host -Prompt "Enter the key for the Windows download (default: NPPR9-FWDCX-D2C8J-H872K-2YT43)"
            If ($DemoKey -eq '')
            {
                $DemoKey = "NPPR9-FWDCX-D2C8J-H872K-2YT43" ## This key is an evaluation key from the Microsoft website and is public
            }
        }

        ## Share names and paths
        $MdtBuildShare = Read-Host -Prompt "Enter the local path of the Build share (default: C:\BuildShare)"
        If ($MdtBuildShare -eq '')
        {
            $MdtBuildShare = "C:\BuildShare" ## Local path of the Build share
        }

        $MdtBuildShareName = Read-Host -Prompt "Enter the share name of the Build share (default: BuildShare$)"
        If ($MdtBuildShareName -eq '')
        {
            $MdtBuildShareName = "BuildShare$" ## Share name of the Build share
        }

        $MdtDepShare = Read-Host -Prompt "Enter the local path of the Deployment share (default: C:\DeployShare)"
        If ($MdtDepShare -eq '')
        {
            $MdtDepShare = "C:\DeployShare" ## Local path of the Deployment share
        }

        $MdtDepShareName = Read-Host -Prompt "Enter the share name of the Deployment share (default: DeployShare$)"
        If ($MdtDepShareName -eq '')
        {
            $MdtDepShareName = "DeployShare$" ## Share name of the Deployment share
        }

        ## Preferences for Deployment share CustomSettings.ini
        $TZName = Read-Host -Prompt "Enter the time zone name (default: GMT Standard Time)"
        If ($TZName -eq '')
        {
            $TZName = "GMT Standard Time"## The time zone for Windows
        }

        $KbLocaleCode = Read-Host -Prompt "Enter the keyboard locale code for Windows (default: 0809:00000809)"
        If ($KbLocaleCode -eq '')
        {
            $KbLocaleCode = "0809:00000809" ## The keyboard locale for Windows
        }

        $UILang = Read-Host -Prompt "Enter the UI locale for Windows (default: en-GB)"
        If ($UILang -eq '')
        {
            $UILang = "en-GB" ## The UI locale for Windows
        }

        $UsrLocale = Read-Host -Prompt "Enter the user locale for Windows (default: en-GB)"
        If ($UsrLocale -eq '')
        {
            $UsrLocale = "en-GB" ## The user locale for Windows
        }

        $KbLocaleName = Read-Host -Prompt "Enter the keyboard locale name for Windows (default: en-GB)"
        If ($KbLocaleName -eq '')
        {
            $KbLocaleName = "en-GB" ## The keyboard locale name for Windows
        }

        $DomainUsr = Read-Host -Prompt "Enter the domain user to be used to add a PC to the domain (eg. mdt_admin)"
        $DomainPwrd = Read-Host -Prompt "Enter the password of the user above (eg. p@ssw0rD)"
        $DomainName = Read-Host -Prompt "Enter the domain of the user above (eg. contoso.com)"
        $OU = Read-Host -Prompt "Enter the full AD path for newly imaged PCs (eg. OU=PCs,DC=contoso,DC=com)"

        $UseWSUS = Read-Host -Prompt "Do you want to use a WSUS server? (y/N)"
        If ($UseWSUS -eq '')
        {
            $UseWSUS = "n"
        }

        If ($UseWSUS -eq "y")
        {
            $WSUSServer = Read-Host -Prompt "Enter the name and port of the WSUS server to use (eg. Wsus-Server:8530)"
        }

        Write-Host -Object ""
        Write-Host -Object "Configuration Summary:
        Windows version and update code: $WinCode
        Download and convert Windows ESD: $ConvertESD"
        If ($ConvertESD -eq "y")
        {
            Write-Host -Object "        Windows language to download : $LangCode"
            Write-Host -Object "        Windows edition to download: $Edition"
            Write-Host -Object "        Windows key for download: $DemoKey"
        }

        Write-Host -Object "        Build share path: $MdtBuildShare
        Build share name: $MdtBuildShareName
        Deploy share path: $MdtDepShare
        Deploy share name: $MdtDepShareName
        Time zone name: $TZName
        Keyboard locale code: $KbLocaleCode
        Keyboard locale name: $KbLocaleName
        Windows UI language: $UILang
        Windows user language: $UsrLocale
        Domain user for domain join: $DomainUsr
        Domain password for above user: $DomainPwrd
        Domain name: $DomainName
        OU for new PC account: $OU
        Use WSUS server: $UseWSUS"
        If ($UseWSUS -eq "y")
        {
            Write-Host -Object "        WSUS server name and port: $WSUSServer"
        }

        $Ready = Read-Host -Prompt "Are you ready to begin the process? (eg. y/N)"
        If ($Ready -eq '')
        {
            $Ready = "n"
        }

        ## URLs - shouldn't have to change these until MSFT release new versions
        $MdtSrc = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi" ## MDT main package
        $AdkSrc = "https://go.microsoft.com/fwlink/?linkid=2120254" ## ADK 2004
        $AdkPeSrc = "https://go.microsoft.com/fwlink/?linkid=2120253" ## ADK 2004 Win PE
        $MdtPatchSrc = "https://download.microsoft.com/download/3/0/6/306AC1B2-59BE-43B8-8C65-E141EF287A5E/KB4564442/MDT_KB4564442.exe" ## MDT Patch
        $MctW10 = "https://go.microsoft.com/fwlink/?LinkId=691209" ## Media Creation Tool for Windows 10

        If ($Ready -eq "y")
        {
            ##
            ## Start Process
            ##
            ## Downloads
            Write-Host "Downloading Installers"
            Invoke-WebRequest -uri $MdtSrc -Outfile "$PSScriptRoot\MicrosoftDeploymentToolkit_x64.msi"
            Invoke-WebRequest -uri $AdkSrc -Outfile "$PSScriptRoot\adksetup.exe"
            Invoke-WebRequest -uri $AdkPeSrc -Outfile "$PSScriptRoot\adkwinpesetup.exe"
            Invoke-WebRequest -uri $MdtPatchSrc -Outfile "$PSScriptRoot\MDT_KB4564442.exe"

            ## Installs
            Write-Host "Installing ADK"
            Start-Process $PSScriptRoot\adksetup.exe -ArgumentList "/features OptionId.DeploymentTools OptionId.ICDConfigurationDesigner OptionId.ImagingAndConfigurationDesigner OptionId.UserStateMigrationTool /q" -Wait

            Write-Host "Installing ADK-WinPE"
            Start-Process $PSScriptRoot\adkwinpesetup.exe -ArgumentList "/features + /q" -Wait

            Write-Host "Installing MDT"
            Start-Process msiexec -ArgumentList "/i $PSScriptRoot\MicrosoftDeploymentToolkit_x64.msi /qn" -Wait

            Write-Host "Installing MDT Patch KB4564442"
            Start-Process $PSScriptRoot\MDT_KB4564442.exe -ArgumentList "-q -extract:$PSScriptRoot\MDT_KB4564442" -Wait
            Copy-Item -Path "$PSScriptRoot\MDT_KB4564442\x64\*" -Destination "$env:ProgramFiles\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64"
            Copy-Item -Path "$PSScriptRoot\MDT_KB4564442\x86\*" -Destination "$env:ProgramFiles\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x86"

            ## Import MDT PowerShell
            Import-Module "$env:ProgramFiles\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

            ## Build Share
            ## Create Build Share
            Write-Host "Creating Build Share"
            New-Item -Path "$MdtBuildShare" -ItemType Directory
            New-SmbShare -Name "$MdtBuildShareName" -Path "$MdtBuildShare" -FullAccess Administrators
            New-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root "$MdtBuildShare" -Description "MDT Build Share" -NetworkPath "\\$env:ComputerName\$MdtBuildShareName" | Add-MDTPersistentDrive

            If ($ConvertESD -eq "y")
            {
                ## Download OS
                Write-Host "Downloading Windows iso"
                Invoke-WebRequest -uri $MctW10 -Outfile "$PSScriptRoot\MediaCreationTool21H2.exe"
                Write-Host "The Media Creation tool requires user interaction."
                Write-Host "Use this key to download your Windows iso: $DemoKey"
                Write-Host "Choose 'Create installation media' and then the 'ISO file' option to download an iso file."
                Write-Host "Please save the Windows iso file to the same folder that contains this script, otherwise things will fail"
                Start-Process $PSScriptRoot\MediaCreationTool21H2.exe -ArgumentList "/Eula Accept /Retail /MediaArch x64 /MediaLangCode $LangCode /MediaEdition $Edition" -Wait

                If ($ConvertESD -eq "y")
                {
                    $WinFileName = Read-Host -Prompt "Enter the name of the Windows iso file that you downloaded (default: windows.iso)"
                    If ($WinFileName -eq '')
                    {
                        $WinFileName = "Windows.iso" ## The name of the Windows 10 iso that will be downloaded via Media Creation Tool
                    }
                }

                ## Copy Source Files
                Write-Host "Copying Windows source files"
                Mount-DiskImage -ImagePath "$PSScriptRoot\$WinFileName" -NoDriveLetter
                Copy-Item -Path \\.\CDROM1\ -Destination $PSScriptRoot\$WinCode -Recurse
                Dismount-DiskImage -ImagePath "$PSScriptRoot\Windows.iso"

                ## Convert ESD to WIM
                Write-Host "Converting ESD to WIM"
                DISM /export-image /SourceImageFile:$PSScriptRoot\$WinCode\sources\install.esd /SourceIndex:3 /DestinationImageFile:$PSScriptRoot\$WinCode\sources\install.wim /Compress:max /CheckIntegrity
                Remove-Item -Path $PSScriptRoot\$WinCode\sources\install.esd -Force
            }

            ## Add to MDT
            Write-Host "Importing Windows to MDT"
            New-Item -Path "DS001:\Operating Systems\$WinCode" -ItemType Directory
            Import-MDTOperatingSystem -Path "DS001:\Operating Systems\$WinCode" -SourcePath $PSScriptRoot\$WinCode -DestinationFolder "$WinCode"

            ## Packages and Selection Profiles
            Write-Host "Creating selection profile"
            New-Item -Path "DS001:\Packages\$WinCode" -ItemType Directory
            New-Item -Path "DS001:\Selection Profiles" -enable "True" -Name "$WinCode" -Comments "" -Definition "<SelectionProfile><Include path=`"Packages\$WinCode`" /></SelectionProfile>" -ReadOnly "False"

            ## New TS From Template
            Write-Host "Downloading Build Task Sequence template"
            Invoke-WebRequest -uri "https://raw.githubusercontent.com/Digressive/MDT-Files/master/MDT-Templates/Client-Build-Template.xml" -Outfile "$MdtBuildShare\Templates\Client-Build-Template.xml"

            If ($ConvertESD -eq "y")
            {
                Write-Host "Creating Build Task Sequence"
                Import-MdtTaskSequence -Path "DS001:\Task Sequences" -Name "Build $WinCode" -Template "Client-Build-Template.xml" -Comments "" -ID "$WinCode" -Version "1.0" -OperatingSystemPath "DS001:\Operating Systems\$WinCode\Windows 10 Enterprise in $WinCode install.wim" -FullName "user" -OrgName "org" -HomePage "about:blank"
            }

            ## MDT configuration
            ## Build share CS.ini
            Write-Host "Backing up original cs.ini"
            Rename-Item -Path $MdtBuildShare\Control\CustomSettings.ini -NewName CustomSettings-OgBackup.ini
            Write-Host "Creating custom cs.ini"
            Add-Content -Path $MdtBuildShare\Control\CustomSettings.ini -Value "[Settings]
            Priority=Default
            Properties=MyCustomProperty

            [Default]
            OSInstall=Y
            SkipCapture=YES
            SkipAdminPassword=YES
            SkipProductKey=YES
            SkipComputerBackup=YES
            SkipBitLocker=YES
            SkipLocaleSelection=YES
            SkipTimeZone=YES
            SkipDomainMembership=YES
            SkipSummary=YES
            SkipFinalSummary=YES
            SkipComputerName=YES
            SkipUserData=YES

            _SMSTSORGNAME=Build Share
            _SMSTSPackageName=%TaskSequenceName%
            DoCapture=YES
            ComputerBackupLocation=\\$env:ComputerName\$MdtBuildShareName\Captures"
            Add-Content -Path $MdtBuildShare\Control\CustomSettings.ini -Value 'BackupFile=%TaskSequenceID%_#year(date) & "-" & month(date) & "-" & day(date) & "-" & hour(time) & "-" & minute(time)#.wim'

            Add-Content -Path X:\Foo\test.log -Value "SLShare=\\$env:ComputerName\$MdtBuildShareName\Logs\#year(date) & `"-`" & month(date) & `"-`" & day(date) & `"_`" & hour(time) & `"-`" & minute(time)#"

            Add-Content -Path $MdtBuildShare\Control\CustomSettings.ini -Value "SLShare=\\$env:ComputerName\$MdtBuildShareName\Logs\#year(date) & `"-`" & month(date) & `"-`" & day(date) & `"_`" & hour(time) & `"-`" & minute(time)#"
            Add-Content -Path $MdtBuildShare\Control\CustomSettings.ini -Value "SLShareDynamicLogging=\\$env:ComputerName\$MdtBuildShareName\DynamicLogs\#year(date) & `"-`" & month(date) & `"-`" & day(date) & `"_`" & hour(time) & `"-`" & minute(time)#"

            If ($UseWSUS -eq "y")
            {
                Add-Content -Path $MdtBuildShare\Control\CustomSettings.ini -Value "
                WSUSServer=http://$WsusServer"
            }

            Add-Content -Path $MdtBuildShare\Control\CustomSettings.ini -Value "
            FinishAction=SHUTDOWN
            SLShare=\\$env:ComputerName\$MdtBuildShareName\Logs"

            ## Change MDT config to disable x86 support for boot media
            Write-Host "Configuring MDT"
            $XMLContent = Get-Content "$MdtBuildShare\Control\Settings.xml"
            $XMLContent = $XMLContent -Replace '<SupportX86>True</SupportX86>','<SupportX86>False</SupportX86>'
            $XMLContent | Out-File "$MdtBuildShare\Control\Settings.xml"

            ## Update Build share to generate boot media
            Write-Host "Updating Build share and generating boot media"
            Update-MDTDeploymentShare -path "DS001:" -Force

            ## Deployment Share
            ## Create Deployment Share
            Write-Host "Creating Deployment Share"
            New-Item -Path "$MdtDepShare" -ItemType Directory
            New-SmbShare -Name "$MdtDepShareName" -Path "$MdtDepShare" -FullAccess Administrators
            New-PSDrive -Name "DS002" -PSProvider "MDTProvider" -Root "$MdtDepShare" -Description "MDT Deploy Share" -NetworkPath "\\$env:ComputerName\$MdtDepShareName" | Add-MDTPersistentDrive

            ## Packages, Drivers and Selection Profiles
            Write-Host "Creating selection profiles, package and driver folder structure"
            New-Item -Path "DS002:\Packages\$WinCode" -ItemType Directory
            New-Item -Path "DS002:\Selection Profiles" -enable "True" -Name "$WinCode" -Comments "" -Definition "<SelectionProfile><Include path=`"Packages\$WinCode`" /></SelectionProfile>" -ReadOnly "False"
            New-Item -Path "DS002:\Out-of-Box Drivers\Microsoft Corporation" -ItemType Directory
            New-Item -Path "DS002:\Out-of-Box Drivers\Microsoft Corporation\Virtual Machine" -ItemType Directory
            New-Item -Path "DS002:\Out-of-Box Drivers\VMware, Inc." -ItemType Directory
            New-Item -Path "DS002:\Out-of-Box Drivers\VMware, Inc.\VMwareVirtual Platform" -ItemType Directory
            New-Item -Path "DS002:\Out-of-Box Drivers\WinPE" -ItemType Directory
            New-Item -Path "DS002:\Selection Profiles" -enable "True" -Name "WinPE" -Comments "" -Definition "<SelectionProfile><Include path=`"Out-of-Box Drivers\WinPE`" /></SelectionProfile>" -ReadOnly "False"

            ## New TS From Template
            Write-Host "Downloading Deploy Task Sequence template"
            Invoke-WebRequest -uri "https://raw.githubusercontent.com/Digressive/MDT-Files/master/MDT-Templates/Client-Deploy-Template.xml" -Outfile "$MdtDepShare\Templates\Client-Deploy-Template.xml"

            ## Deploy share CS.ini
            Write-Host "Backing up original cs.ini"
            Rename-Item -Path $MdtDepShare\Control\CustomSettings.ini -NewName CustomSettings-OgBackup.ini
            Write-Host "Creating custom cs.ini"
            Add-Content -Path $MdtDepShare\Control\CustomSettings.ini -Value "[Settings]
            Priority=Model, Default, SetOSD
            Properties=OSDPrefix

            [Virtual Machine]
            OSDComputerName=%TaskSequenceID%

            [Default]
            _SMSTSORGNAME=Deploy
            _SMSTSPackageName=%TaskSequenceName%

            ; MDT deployment settings
            OSInstall=Y
            SkipCapture=YES
            SkipAdminPassword=YES
            SkipProductKey=YES
            SkipComputerBackup=YES
            SkipBitLocker=YES

            ; Locale and screen res
            TimeZoneName=$TZName
            KeyboardLocale=$KbLocaleCode
            UILanguage=$UILang
            UserLocale=$UsrLocale
            KeyboardLocale=$KbLocaleName
            BitsPerPel=32
            VRefresh=60
            XResolution=1
            YResolution=1
            HideShell=YES

            ; Join Domain
            JoinDomain=$DomainName
            DomainAdmin=$DomainUsr
            DomainAdminDomain=$DomainUsr
            DomainAdminPassword=$DomainPwrd
            MachineObjectOU=$OU

            ; Other Settings
            SkipUserData=YES
            SkipDomainMembership=YES
            SkipLocaleSelection=YES
            SkipTimeZone=YES
            SkipSummary=YES
            SkipFinalSummary=YES
            FinishAction=SHUTDOWN
            SLShare=\\$env:ComputerName\$MdtDepShareName\Logs
            "
            If ($UseWSUS -eq "y")
            {
                Add-Content -Path $MdtBuildShare\Control\CustomSettings.ini -Value "
                WSUSServer=http://$WsusServer"
            }

            Add-Content -Path $MdtBuildShare\Control\CustomSettings.ini -Value "
            ; this line intentionally left blank
            ; this line intentionally left blank
            "

            ## Change MDT config to disable x86 support for boot media
            ## And set the WinPE selection profile for the drivers
            Write-Host "Configuring MDT"
            $XMLContent = Get-Content "$MdtDepShare\Control\Settings.xml"
            $XMLContent = $XMLContent -Replace '<SupportX86>True</SupportX86>','<SupportX86>False</SupportX86>'
            $XMLContent = $XMLContent -Replace '<Boot.x64.SelectionProfile>All Drivers and Packages</Boot.x64.SelectionProfile>','<Boot.x64.SelectionProfile>WinPE</Boot.x64.SelectionProfile>'
            $XMLContent | Out-File "$MdtDepShare\Control\Settings.xml"

            ## Update Deploy share to generate boot media
            Write-Host "Updating Deploy share and generating boot media"
            Update-MDTDeploymentShare -path "DS002:" -Force

            Write-Host "Finished!"
        }
    }
}

## End