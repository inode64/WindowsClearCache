# WindowsClearCache

Simple scripts to clear temp files, browser cache/history, caches for applications like Microsoft Teams, Slack, Discord, Opera,
and OneDrive, and remove Windows Defender scan and definition update backups (including the NisBackup folder), Windows dump files, and Windows Error Reporting (WER) temp files

## Installation

1) Build the graphical installer by running `makensis WindowsClearCache.nsi` (or download a pre-built `WindowsClearCacheInstaller.exe`).
   - A GitHub Actions workflow builds the installer and attaches it to a release when you push a tag such as `v1.0.0`.
2) Run `WindowsClearCacheInstaller.exe` as an administrator.
   - The installer launches `cleanmgr.exe /sageset:1` so you can configure Disk Cleanup before the first run.
   - You can choose to create a weekly scheduled task that runs the cleanup with highest privileges.
   - The cleaner script is copied to `c:\Program Files\WindowsClearCache`.

## How To Run

After installation you can run the cleaner manually with:
`powershell.exe -ExecutionPolicy Bypass -File "%ProgramFiles%\WindowsClearCache\DriveClean.ps1"`

Optional flags:

- Use `-DryRun` to preview the files that would be deleted without removing them.
- Use `-Verbose` to display each file as it is deleted (or would be deleted in dry run).
- Use `-IncludeUsers` to target specific active user profiles.
- Use `-ExcludeUsers` to skip particular user profiles.
  - `-IncludeUsers` and `-ExcludeUsers` are mutually exclusive.
- Use `-CleanSystem:$false` to skip clearing system caches.
- Use `-CleanUsers:$false` to skip clearing user profile caches.
  - `CleanSystem` and `CleanUsers` cannot both be set to `$false`.

## Uninstallation

Run `Uninstall.exe` from `c:\Program Files\WindowsClearCache` or use Add/Remove Programs. This removes the scheduled task and deletes the installed files.

## Tested on following Windows Versions

Verified on the following platforms:

|Windows Version         |Yes/No?|
|:-----------------------|:-----:|
| Windows Server 2025    | Yes   |
| Windows Server 2022    | Yes   |
| Windows Server 2019    | Yes   |
| Windows Server 2016    | Yes   |
| Windows Server 2012 R2 | Yes   |
| Windows Server 2012    | Yes   |
| Windows Server 2008 R2 | Yes   |
| Windows Server 2008 SP2| Yes   |
| Windows Server 2008    | No    |
| Windows Server 2003    | No    |
| Windows 11             | Yes   |
| Windows 10             | Yes   |
| Windows 8              | Yes   |
| Windows 7 SP1          | Yes   |
| Windows 7              | No    |
| Windows Vista          | No    |
| Windows XP             | No    |
| Windows 2000           | No    |

It is likely to work on other platforms as well. If you try it and find that it works on another platform, please let me know.

### Requirements and Limitations

- Requires PowerShell 5 or later and administrative privileges.
- Disk Cleanup (`cleanmgr.exe`) and DISM may be installed. These tools are present when the Desktop Experience feature is enabled and are not available on Server Core installations, which are required for native Windows optimizations.
- The Windows Update service should be available to allow cache cleanup.

## Disclaimer

**WARNING:** I do **NOT** take responsibility for what may happen to your system! Run scripts at your own risk!
