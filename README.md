# WindowsClearCache

Simple scripts to clear temp files, browser cache/history, caches for applications like Microsoft Teams, Slack, Discord, Opera, and OneDrive, and remove Windows Defender scan and definition update backups (including the NisBackup folder), Windows dump files, and Windows Error Reporting (WER) temp files

## How To Run

To run this with parameters, do the following:

1) Download the .zip file on the main page of the GitHub and extract the .zip file to your desired location, e.g. - `c:\WindowsClearCache`
2) Once extracted, open [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting) (or [PowerShell ISE](https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/ise/introducing-the-windows-powershell-ise)) as an Administrator
3) Enable PowerShell execution: `Set-ExecutionPolicy Unrestricted -Force` (to allow executing unsigned code)
4) Run the Disk Cleanup utility (cleanmgr.exe) with the /sageset:1 option, which allows users to configure cleanup settings before executing the actual cleanup process 
e.g. - `cleanmgr.exe /sageset:1`
5) On the prompt, change to the directory where you extracted the files:
e.g. - `cd c:\Program Files\WindowsClearCache`
6) Next, to run the script, enter in the following:
e.g. - `.\DriveClean.ps1`

Optional flags:

- Use `-DryRun` to preview the files that would be deleted without removing them.
- Use `-Verbose` to display each file as it is deleted (or would be deleted in dry run).

## Tested on following Windows Versions

Verified on the following platforms:

|Windows Version         |Yes/No?|
|:-----------------------|:-----:|
| Windows Server 2025    | ???   |
| Windows Server 2022    | Yes   |
| Windows Server 2019    | Yes   |
| Windows Server 2016    | Yes   |
| Windows Server 2012 R2 | Yes   |
| Windows Server 2012    | Yes   |
| Windows Server 2008 R2 | Yes   |
| Windows Server 2008    | Yes   |
| Windows Server 2003    | No    |
| Windows 11             | Yes   |
| Windows 10             | Yes   |
| Windows 8              | ???   |
| Windows 7              | ???   |
| Windows Vista          | No    |
| Windows XP             | No    |
| Windows 2000           | No    |

It is likely to work on other platforms as well. If you try it and find that it works on another platform, please let me know.

## Disclaimer

**WARNING:** I do **NOT** take responsibility for what may happen to your system! Run scripts at your own risk!
