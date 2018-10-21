## Migrate-Folder
## 1- Copy 'SourcePath' to 'DestinationPath' and output log file result
## 2- Rename the 'SourcePath' using the 'RenamedPattern'
## 3- Create a shortcut of 'DestinationPath' in original 'SourcePath'
## WARNING: Works only with folders, and do not give a trailing slash in folder param (eg. ./TOTO/ will failed but ./TOTO will work)
function Migrate-Folder {
param ( [string]$SourcePath, [string]$DestinationPath, [string] $RenamedPattern)

	## needed variables
	$SourceDirName = (Get-Item $SourcePath).Name
	$SourceParentFullPath = (get-item $SourcePath ).parent.FullName
	$SourceNameSuffixed = $SourceDirName + $RenamedPattern

	$CopyLogName = $SourceNameSuffixed + ".log"
	$CopyLogPath = Join-Path -Path $SourceParentFullPath -ChildPath $CopyLogName

	$ShortcutName = $SourceDirName + ".lnk"
	$ShortcutPath = Join-Path -Path $SourceParentFullPath -ChildPath $ShortcutName
	$ShortcutTargetPath = $DestinationPath
	if( -not [System.IO.Path]::IsPathRooted($DestinationPath) ) { 
		$ShortcutTargetPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
	}


	## Copy operation with output log file
	Write-Host "   Copying item $SourcePath to $DestinationPath"
	$copyResult = Copy-Item $SourcePath -Destination $DestinationPath -Recurse -Force -ErrorAction silentlyContinue -passthru | ?{$_ -is [system.io.fileinfo]}

	Write-Host "   Creating $CopyLogPath"
	$stream = [System.IO.StreamWriter] $CopyLogPath
	foreach($line in $copyResult) {
		$stream.WriteLine($line)
	}
	$stream.close()


	## Rename the copied foler using the $RenamedPattern
	Write-Host "   Renaming source item : $SourceNameSuffixed"
	Rename-Item -Path $SourcePath -NewName $SourceNameSuffixed


	## Create a shortcut to ease the redirection to the new location
	Write-Host "   Creating associated shortcut $ShortcutPath to point to $DestinationPath"
	$WshShell = New-Object -comObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
	$Shortcut.TargetPath = $ShortcutTargetPath ## WARNING: only full absolute path is ok
	$Shortcut.Save()
}



## Migrate-Folders-FromCSV
## 1- Read the given CSV : should look like this:
##   #Version1.0 Source,Destination
##   ./folderSourcePath1,./folderDestinationPath1
##   c:/folderSourcePath2,./folderDestinationPath2
##   c:/folderSourcePath3,c:/folderDestinationPath3
## 2- Foreach entry, call Migrate-Folder powershell function
function Migrate-FoldersFromCSV {
param ( [string]$CsvPath)

	Import-Csv $CsvPath -Header Source,Destination | Foreach-Object { 
		Write-Host "Migrating" $_.Source " to "  $_.Destination		
		Migrate-Folder $_.Source $_.Destination "_moved"
		Write-Host " "
	}
	
}