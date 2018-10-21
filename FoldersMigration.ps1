## Folder migrations
## 1- Copy 'SourcePath' to 'DestinationPath' and output log file result
## 2- Rename the 'SourcePath' using the 'RenamedPattern'
## 3- Create a shortcut of 'DestinationPath' in original 'SourcePath'
## WARNING: Works only with folders, and do not give a trailing slash in folder param (eg. ./TOTO/ will failed but ./TOTO will work)
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
Write-Host "   Copying item (Recurse + Force) $SourcePath to $DestinationPath ..."
$copyResult = Copy-Item $SourcePath -Destination $DestinationPath -Recurse -Force -ErrorAction silentlyContinue -passthru | ?{$_ -is [system.io.fileinfo]}

Write-Host "   Creating $CopyLogPath..."
$stream = [System.IO.StreamWriter] $CopyLogPath
foreach($line in $copyResult) {
	$stream.WriteLine($line)
}
$stream.close()


## Rename the copied foler using the $RenamedPattern
Write-Host "   Renaming item moved ($SourcePath) with suffix pattern : $SourceNameSuffixed ..."
Rename-Item -Path $SourcePath -NewName $SourceNameSuffixed


## Create a shortcut to ease the redirection to the new location
Write-Host "   Creating associated shortcut $ShortcutPath to point to $DestinationPath ... "
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $ShortcutTargetPath ## WARNING: only full absolute path is ok
$Shortcut.Save()

Write-Host "   Done."