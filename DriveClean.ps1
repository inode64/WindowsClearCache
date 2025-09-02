[CmdletBinding()]
param(
    [switch]$DryRun
)

$Global:RemovedFiles = 0
$Global:FreedBytes = 0

#------------------------------------------------------------------#
#- Clear-GlobalWindowsCache                                        #
#------------------------------------------------------------------#
Function Clear-GlobalWindowsCache
{
	Write-Output "Clearing global Windows cache..."
    Remove-Dir "$env:windir\Temp"
    Remove-Dir "$env:SystemDrive:\Temp"
    Remove-Dir "$env:SystemDrive:\tmp"

	Write-Output "Clearing recycle bin..."
	Clear-RecycleBin -Force -ErrorAction Ignore

	Write-Output "Clearing prefetch cache..."
    Remove-Dir "$env:windir\Prefetch"

	Write-Output "Clearing printer cache..."
    if (StopService "spooler")
	{
		Remove-Dir "$env:windir\System32\spool\PRINTERS"
	}
	else
	{
		Write-Host "Failed to stop spooler service." -ForegroundColor Red
	}
    StartService "spooler"

	if (CheckService "wuauserv")
	{
	    Stop-Windows-update
	}
	else
	{
	    Clear-Windows-update-cache
	}

	Clear-WindowsDefenderBackups
}

#------------------------------------------------------------------#
#- Clear-WindowsDefenderBackups                                    #
#------------------------------------------------------------------#
Function Clear-WindowsDefenderBackups
{
	Write-Output "Clearing Windows Defender backups"

	Remove-Dir "$env:ProgramData\Microsoft\Windows Defender\Scans\History"
	Remove-Dir "$env:ProgramData\Microsoft\Windows Defender\Scans\mpcache*"
    Remove-Dir "$env:ProgramData\Microsoft\Windows Defender\Definition Updates\Backup"
    Remove-Dir "$env:ProgramData\Microsoft\Windows Defender\Definition Updates\NisBackup"
}

#------------------------------------------------------------------#
#- Clear-UserCacheFiles                                            #
#------------------------------------------------------------------#
Function Clear-UserCacheFiles
{
	# Use only real user directories
    $excludedUsers = @("All Users", "Default", "Default User", "Public")
	ForEach ($userDir in Get-ChildItem "C:\users" -Directory -Exclude $excludedUsers)
    {
		$localUser = $userDir.Name
		Write-Output "* Clearing cache for user $localUser" -ForegroundColor Green

		Clear-AcrobatCacheFiles $localUser
        Clear-AVGCacheFiles $localUser
        Clear-BattleNetCacheFiles $localUser
        Clear-ChromeCacheFiles $localUser
        Clear-DiscordCacheFiles $localUser
        Clear-EdgeCacheFiles $localUser
        Clear-EpicGamesCacheFiles $localUser
        Clear-FirefoxCacheFiles $localUser
        Clear-GoogleEarth $localUser
        Clear-iTunesCacheFiles $localUser
        Clear-LibreOfficeCacheFiles $localUser
        Clear-LolScreenSaverCacheFiles $localUser
        Clear-MicrosoftOfficeCacheFiles $localUser
        Clear-SlackCacheFiles $localUser
        Clear-SteamCacheFiles $localUser
        Clear-TeamsCacheFiles $localUser
        Clear-ThunderbirdCacheFiles $localUser
        Clear-WindowsUserCacheFiles $localUser
    }
}

#------------------------------------------------------------------#
#- Clear-WindowsUserCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-WindowsUserCacheFiles
{
    param([string]$user = $env:USERNAME)

	Write-Output "Clearing Windows user cache"

    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Internet Explorer\Cache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Internet Explorer\Recovery"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Internet Explorer\Tiles"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Terminal Server Client\Cache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\Caches"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\History\low"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\IECompatCache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\IECompatUaCache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\IEDownloadHistory"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\INetCache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\WebCache"
    Remove-Dir "C:\Users\$user\AppData\Local\Microsoft\Windows\WER"
    Remove-Dir "C:\Users\$user\AppData\Local\Temp"
}

#------------------------------------------------------------------#
#- Clear-WUS-Cache Group                                           #
#------------------------------------------------------------------#

function CheckService {
	param (
		[Parameter(Mandatory = $true)][string]$Name	
	)

	if ($DryRun)
	{
		return $true
	}

	if ((Get-Service -Name "$Name").Status -ne 'Stopped')
	{
		return $true
	}
	return $false
}

Function StopService {
	param (
		[Parameter(Mandatory = $true)][string]$Name
	)

	if ($DryRun)
	{
		return $true
	}
	Stop-Service -Name "$Name" -ErrorAction SilentlyContinue

	$count = 0

	while ((Get-Service -Name "$Name").Status -ne 'Stopped' -and $count -gt 0)
	{
		Stop-Service -Name "$Name" -Force -ErrorAction SilentlyContinue
		Write-Host "Waiting for service $Name to stop..." -ForegroundColor Yellow
		Start-Sleep -Seconds 2
		$count--	
	}

	return -not (CheckService "$Name")
}

function Start-Service
 {
	param (
		[Parameter(Mandatory = $true)][string]$Name
	)

	if ($DryRun)
	{
		return $true
	}

	$count = 5

	while ((Get-Service -Name "$Name").Status -ne 'Running' -and $count -gt 0)
	{
		Start-Service -Name "$Name" -Force -ErrorAction SilentlyContinue
		Write-Host "Waiting for service $Name to start..." -ForegroundColor Yellow
		Start-Sleep -Seconds 2
		$count--
	}

	return CheckService "$Name"
}

Function Stop-Windows-update
{
    # Stopping Windows Update Service and check again if it is stopped
    StopService "wuauserv"
    if (CheckService "wuauserv")
    {
        Clear-Windows-update-cache
    }
    else
    {
        Write-Host "Can't stop Windows Update Service..." -ForegroundColor Red
        exit 1
    }

	# Starting the Windows Update Service again
    StartService "wuauserv"
}

Function Clear-Windows-update-cache
{
	Write-Output "Cleaning Windows Update cache..."

	StopService "bits"
    Remove-dir "$env:windir\SoftwareDistribution\Download"
	StartService "bits"
}

Function FreeDiskSpace
{
    param(
        [string]$DiskLetter = 'C'
    )

    return ([math]::Round((Get-Volume -DriveLetter $DiskLetter | Select-Object @{ Name = "MB"; Expression = { $_.SizeRemaining/1MB } }).MB, 2))
}

#Region HelperFunctions

#------------------------------------------------------------------#
#- Get-StorageSize                                                 #
#------------------------------------------------------------------#
Function Get-StorageSize
{
    Get-WmiObject Win32_LogicalDisk |
            Where-Object { $_.DriveType -eq "3" } |
            Select-Object SystemName,
            @{ Name = "Drive"; Expression = { ( $_.DeviceID) } },
            @{ Name = "Size (GB)"; Expression = { "{0:N1}" -f ( $_.Size / 1gb) } },
            @{ Name = "FreeSpace (GB)"; Expression = { "{0:N1}" -f ( $_.Freespace / 1gb) } },
            @{ Name = "PercentFree"; Expression = { "{0:P1}" -f ( $_.FreeSpace / $_.Size) } } |
            Format-Table -AutoSize | Out-String
}

#------------------------------------------------------------------#
#- Remove-Dir                                               #
#------------------------------------------------------------------#
Function Remove-Dir
{
    param([Parameter(Mandatory = $true)][string]$path)

    if (Test-Path "$path")
    {
		$items = Get-ChildItem -Path "$path" -Force -Recurse -ErrorAction SilentlyContinue
		$files = $items | Where-Object { -not $_.PSIsContainer }
		$dirs  = $items | Where-Object { $_.PSIsContainer }
		$Global:RemovedFiles += $items.Count
		$Global:FreedBytes += ($files | Measure-Object -Property Length -Sum).Sum

		if ($DryRun) {
			$action = 'Would remove'
		} else {
			$action = 'Removing'
		}
        foreach ($item in $items) {
            Write-Verbose "$action $($item.FullName)"
        }

		if (-not $DryRun) {
			$files | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
			$dirs | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
		}
    }
}

#Endregion HelperFunctions

#Region Browsers

#Region ChromiumBrowsers

#------------------------------------------------------------------#
#- Clear-ChromeTemplate                                            #
#------------------------------------------------------------------#
Function Clear-ChromeTemplate
{
    param(
        [Parameter(Mandatory = $true)][string]$path,
        [Parameter(Mandatory = $true)][string]$name
    )

    if (Test-Path "$path")
    {
        Write-Output "Clear cache $name"

		$possibleCachePaths = @("Cache", "Cache2\entries", "ChromeDWriteFontCache", "Code Cache", "GPUCache", "JumpListIcons", "JumpListIconsOld", "Media Cache", "Service Worker", "Top Sites", "VisitedLinks", "Web Data")
        ForEach ($cachePath in $possibleCachePaths)
        {
            Remove-Dir "$path\$cachePath"
        }
    }
}

#------------------------------------------------------------------#
#- Clear-MozillaTemplate                                           #
#------------------------------------------------------------------#
Function Clear-MozillaTemplate
{
    param(
        [Parameter(Mandatory = $true)][string]$path,
        [Parameter(Mandatory = $true)][string]$name
    )

    if (Test-Path "$path")
    {
        Write-Output "Clear cache $name"

		$AppDataPath = (Get-ChildItem "$path" | Where-Object { $_.Name -match "Default" }[0]).FullName
        $possibleCachePaths = @("cache", "cache2\entries", "thumbnails", "webappsstore.sqlite*", "chromeappstore.sqlite")
        ForEach ($cachePath in $possibleCachePaths)
        {
            Remove-Dir "$AppDataPath\$cachePath"
        }
    }
}


#------------------------------------------------------------------#
#- Clear-ChromeCache                                               #
#------------------------------------------------------------------#
Function Clear-ChromeCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Google\Chrome\User Data\Default" "Browser Google Chrome"
    Remove-Dir "C:\users\$user\AppData\Local\Google\Chrome\User Data\SwReporter"
}

#------------------------------------------------------------------#
#- Clear-EdgeCache                                                 #
#------------------------------------------------------------------#
Function Clear-EdgeCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Microsoft\Edge\User Data\Default" "Browser Microsoft Edge"
    Remove-Dir "C:\users\$user\AppData\Local\Microsoft\Edge\User Data\Default\CacheStorage"
}

#Endregion ChromiumBrowsers

#Region FirefoxBrowsers

#------------------------------------------------------------------#
#- Clear-FirefoxCacheFiles                                         #
#------------------------------------------------------------------#
Function Clear-FirefoxCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-MozillaTemplate "C:\users\$user\AppData\Local\Mozilla\Firefox\Profiles" "Browser Mozilla Firefox"
}

#------------------------------------------------------------------#
#- Clear-WaterfoxCacheFiles                                        #
#------------------------------------------------------------------#
Function Clear-WaterfoxCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-MozillaTemplate "C:\users\$user\AppData\Local\Waterfox\Profiles" "Browser Waterfox"
}

#Endregion FirefoxBrowsers

#Endregion Browsers

#Region CommunicationPlatforms

#------------------------------------------------------------------#
#- Clear-TeamsCacheFiles                                           #
#------------------------------------------------------------------#
Function Clear-TeamsCacheFiles
{
    param([string]$user = $env:USERNAME)
    if (Test-Path "C:\users\$user\AppData\Roaming\Microsoft\Teams")
    {
		Write-Output "Clearing Teams cache"
		
        $possibleCachePaths = @("application cache\cache", "blob_storage", "Cache", "Code Cache", "GPUCache", "logs", "tmp", "Service Worker\CacheStorage", "Service Worker\ScriptCache")
        $teamsAppDataPath = "C:\users\$user\AppData\Roaming\Microsoft\Teams"
        ForEach ($cachePath in $possibleCachePaths)
        {
            Remove-Dir "$teamsAppDataPath\$cachePath"
        }
    }
}

#------------------------------------------------------------------#
#- Clear-SlackCacheFiles                                           #
#------------------------------------------------------------------#
Function Clear-SlackCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Roaming\Slack" "Slack"
}

#Endregion CommunicationPlatforms

#Region MiscApplications

#------------------------------------------------------------------#
#- Clear-ThunderbirdCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-ThunderbirdCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-MozillaTemplate "C:\users\$user\AppData\Local\Thunderbird\Profiles" "Mozilla Thunderbird"
}

#------------------------------------------------------------------#
#- Clear-EpicGamesCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-EpicGamesCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\EpicGamesLauncher\Saved\webcache" "Epic Games Launcher"
}

#------------------------------------------------------------------#
#- Clear-BattleNetCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-BattleNetCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Battle.net\BrowserCache" "BattleNet"
}

#------------------------------------------------------------------#
#- Clear-SteamCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-SteamCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Steam\htmlcache" "Steam"
}

#------------------------------------------------------------------#
#- Clear-LolScreenSaverCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-LolScreenSaverCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\LolScreenSaver\cefCache" "Lol screen saver"
}

#------------------------------------------------------------------#
#- Clear-DiscordCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-DiscordCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\Discord" "Discord"
}

#------------------------------------------------------------------#
#- Clear-AVGCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-AVGCacheFiles
{
    param([string]$user = $env:USERNAME)
    Clear-ChromeTemplate "C:\users\$user\AppData\Local\AVG\User Data\Default" "Antivirus AVG"
}

#------------------------------------------------------------------#
#- Clear-Google Earth                                              #
#------------------------------------------------------------------#
Function Clear-GoogleEarth
{
    param([string]$user = $env:USERNAME)
    if (Test-Path "C:\users\$user\AppData\LocalLow\Google\GoogleEarth")
    {
        Write-Output "Clearing Google Earth cache"

        Remove-Dir "C:\users\$user\AppData\LocalLow\Google\GoogleEarth\unified_cache_leveldb_leveldb2"
        Remove-Dir "C:\users\$user\AppData\LocalLow\Google\GoogleEarth\webdata"
    }
}

#------------------------------------------------------------------#
#- Clear-TunesCacheFiles                                           #
#------------------------------------------------------------------#
Function Clear-iTunesCacheFiles
{
    param([string]$user = $env:USERNAME)
    if (Test-Path "C:\users\$user\AppData\Local\Apple Computer\iTunes")
    {
		Write-Output "Clearing iTunes cache"

        $iTunesAppDataPath = "C:\users\$user\AppData\Local\Apple Computer\iTunes"
        $possibleCachePaths = @("SubscriptionPlayCache")
        ForEach ($cachePath in $possibleCachePaths)
        {
            Remove-Dir "$iTunesAppDataPath\$cachePath"
        }
    }
}

#------------------------------------------------------------------#
#- Clear-AcrobatCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-AcrobatCacheFiles
{
    param([string]$user = $env:USERNAME)
    $DirName = "C:\users\$user\AppData\LocalLow\Adobe\Acrobat"
    if (Test-Path "$DirName")
    {
		Write-Output "Clearing Acrobat cache"

        $possibleCachePaths = @("Cache", "ConnectorIcons")
        ForEach ($AcrobatAppDataPath in (Get-ChildItem "$DirName").Name)
        {
            ForEach ($cachePath in $possibleCachePaths)
            {
                Remove-Dir "$DirName\$AcrobatAppDataPath\$cachePath"
            }
        }
    }
}

#------------------------------------------------------------------#
#- Clear-MicrosoftOfficeCacheFiles                                 #
#------------------------------------------------------------------#
Function Clear-MicrosoftOfficeCacheFiles
{
    param([string]$user = $env:USERNAME)
    if (Test-Path "C:\users\$user\AppData\Local\Microsoft\Outlook")
    {
        Write-Output "Clearing Outlook cache"

        Remove-Dir "C:\users\$user\AppData\Local\Microsoft\Outlook\*.pst"
        Remove-Dir "C:\users\$user\AppData\Local\Microsoft\Outlook\*.ost"
        Remove-Dir "C:\users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.Outlook"
        Remove-Dir "C:\users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.MSO"
        Remove-Dir "C:\users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\Content.Word"
    }
}

#------------------------------------------------------------------#
#- Clear-LibreOfficeCacheFiles                                     #
#------------------------------------------------------------------#
Function Clear-LibreOfficeCacheFiles
{
    param([string]$user = $env:USERNAME)
    $DirName = "C:\users\$user\AppData\Roaming\LibreOffice"
    if (Test-Path "$DirName")
    {
		Write-Output "Clearing LibreOffice cache"

		$possibleCachePaths = @("cache", "crash", "user\backup", "user\temp")
        ForEach ($LibreOfficeAppDataPath in (Get-ChildItem "$DirName").Name)
        {
            ForEach ($cachePath in $possibleCachePaths)
            {
                Remove-Dir "$DirName\$LibreOfficeAppDataPath\$cachePath"
            }
        }
    }
}

#Endregion MiscApplications

#------------------------------------------------------------------#
#- MAIN                                                            #
#------------------------------------------------------------------#

$StartTime = (Get-Date)

if (-not $DryRun)
{
	Get-StorageSize
}

Clear-GlobalWindowsCache
Clear-UserCacheFiles

Get-StorageSize

$EndTime = (Get-Date)
$mbFreed = [Math]::Round($Global:FreedBytes / 1MB, 2)
if ($DryRun) {
    Write-Host "DRY RUN: $($Global:RemovedFiles) files/dirs would be removed freeing $mbFreed MB"
} else {
    Write-Host "$($Global:RemovedFiles) files/dirs removed freeing $mbFreed MB"
}
Write-Verbose "Elapsed Time: $( ($EndTime - $StartTime).totalseconds ) seconds"
