# Script for incident response : Remove all artifacts related with PUA Media Arena Softwares :
## Pdfpower 
## Pdfhub 
## Ziprararchiver 
## Searcharchiver 
## Pdfmagic 
## Searchpoweronline
## Script to be executed on admin server

## Put the logfile path here

$Log = "C:\Users\$USER\Documents\MDE_Custom Script_$(Get-Date -Format 'yyyyMMddhhmmss').log"



Start-Transcript -path $Log -append -Force -NoClobber

# The files with all the hostname/files
# hostnameList.csv as following : 
# computername1,username1
# filelist.csv as following :
# OneDriveName\Desktop\pdfpower.lnk
# OneDriveName\Desktop\pdfhub.lnk
# OneDriveName\Desktop\pdfmagic.lnk
# OneDriveName\Desktop\searchpoweronline.lnk
# OneDriveName\Desktop\searcharchiver.lnk
# OneDriveName\Desktop\zipraraarchiver.lnk
# Downloads\pdfpower.exe
# Downloads\pdfhub.exe
# Downloads\pdfmagic.exe
# Downloads\searchpoweronline.exe
# Downloads\searcharchiver.exe
# Downloads\zipraraarchiver.exe
# AppData\Local\Temp\PdfPowerB2C\favicon.ico
# AppData\Local\Temp\PdfPowerB2C\installing.gif
# AppData\Local\Temp\PdfPowerB2C\installer_loader.gif


$hostnameList = Import-csv "C:\Users\$USER\ToBeReplace\Documents\SecOps\Incident Response\hostnameList.csv" -Delimiter "," -Header hostname, user
$filelist = Get-Content "C:\Users\$USER\ToBeReplace\Documents\SecOps\Incident Response\filelist.csv"

#In case of debug needed
#echo $hostnameList

# ForEach from csv files :

foreach ($file in $filelist) {
    foreach ($hostname in $hostnameList) {

                                            Write-Host $hostnameList.user

                                            $user = $hostnameList.user

                                            #Put the filepath

                                           # $newfilepath = Join-Path "\\$computer\c$\Users\$user\" "$file"

                                            # $newfilepath = Join-Path "C:\$hostnameList.user\" "$file"

                                            $newfilepath = Join-Path "C:\Users\$user\" "$file"

                                            if (Test-path $newfilepath){

                                                Write-Host "$newfilepath file exists"

                                                Remove-Item $newfilepath -force -Confirm -WhatIf
                                                                       }
            
                                         }
                            }

Stop-Transcript
