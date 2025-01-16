# Script for incident response : Remove all artifcats related with Media Arena Softwares :
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

$hostnameList = Import-csv "C:\Users\$USER\ToBeReplace\Documents\SecOps\Incident Response\hostnameList.csv" -Delimiter "," -Header hostname, user
$filelist = Get-Content "C:\Users\$USER\ToBeReplace\Documents\SecOps\Incident Response\filelist.csv"

#Debug
#echo $hostnameList

# ForEach from a csv file :


foreach ($file in $filelist) {
    foreach ($hostname in $hostnameList) {

                                            Write-Host $hostnameList.user

                                            $user = $hostnameList.user

                                            #Mettre le path du file

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
