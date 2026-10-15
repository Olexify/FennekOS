# Creates and starts the Fennek OS test VM in Hyper-V. Run in an ADMIN PowerShell:
#   powershell -ExecutionPolicy Bypass -File E:\Projects\LexOS\vm.ps1
# Re-running replaces the VM (the disk file is rebuilt separately).
# Fresh install from the installer ISO instead (new empty disk, like a real PC):
#   powershell -ExecutionPolicy Bypass -File E:\Projects\LexOS\vm.ps1 -Iso E:\Fennek-build\iso\<file>.iso
param([string]$Iso)
$ErrorActionPreference = 'Stop'
$name = 'Fennek-dev'
$dir  = 'E:\Fennek-build\vm'
$vhd  = "$dir\fennek.vhdx"

if (Get-VM $name -ErrorAction SilentlyContinue) { Stop-VM $name -TurnOff -Force; Remove-VM $name -Force }

# One-time cleanup of the pre-rename test VM (LexOS) and its files.
if (Get-VM 'LexOS-dev' -ErrorAction SilentlyContinue) { Stop-VM 'LexOS-dev' -TurnOff -Force; Remove-VM 'LexOS-dev' -Force }
if (Test-Path 'E:\LexOS-build') { Remove-Item 'E:\LexOS-build' -Recurse -Force }

if ($Iso) {
    # Replaces the old test disk with an empty 64 GB one (grows as used) and boots the installer.
    Remove-Item $vhd, "$dir\*.avhdx" -Force -ErrorAction SilentlyContinue
    New-VHD -Path $vhd -SizeBytes 64GB -Dynamic | Out-Null
}
# A fresh build is written as fennek-next.vhdx (the old disk may be in use); swap it in now.
if (Test-Path "$dir\fennek-next.vhdx") {
    Get-ChildItem $dir -Filter *.avhdx | Remove-Item   # leftover checkpoint diffs of the old disk
    Move-Item "$dir\fennek-next.vhdx" $vhd -Force
}

# Network: the 'Fennek-External' switch (straight to your router) if you made one, else Hyper-V's Default Switch.
$switch = if (Get-VMSwitch 'Fennek-External' -ErrorAction SilentlyContinue) { 'Fennek-External' } else { 'Default Switch' }
New-VM -Name $name -Generation 2 -MemoryStartupBytes 4GB -VHDPath $vhd -Path $dir -SwitchName $switch | Out-Null
Set-VMProcessor $name -Count 4
Set-VM $name -AutomaticCheckpointsEnabled $false   # no snapshot on every start (saves space on E:)
Set-VMVideo $name -HorizontalResolution 1920 -VerticalResolution 1080 -ResolutionType Single   # fill the window, not 1024x768
Set-VMFirmware $name -SecureBootTemplate MicrosoftUEFICertificateAuthority   # Secure Boot on, Linux shim allowed
if ($Iso) {
    # Disk first: while it's empty the VM falls through to the installer; once installed it boots Fennek OS.
    $dvd = Add-VMDvdDrive $name -Path $Iso -Passthru
    Set-VMFirmware $name -BootOrder (Get-VMHardDiskDrive $name), $dvd
}
Start-VM $name
vmconnect.exe localhost $name
