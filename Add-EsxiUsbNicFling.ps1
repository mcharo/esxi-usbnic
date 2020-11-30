#Requires -PSEdition Desktop
#Requires -Module VMware.ImageBuilder
[CmdletBinding()]
param(
    [string]$VmwareDepotUrl = "https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml",
    [string]$EsxiVersion = '7.0',
    [string]$UsbNicFlingUrl = 'https://download3.vmware.com/software/vmw-tools/USBNND/ESXi701-VMKUSB-NIC-FLING-40599856-component-17078334.zip'
)

function timestamp() {
    "[$(Get-Date -Format HH:mm:ss)]"
}

function log() {
    Write-Host "$(timestamp) " -NoNewline -ForegroundColor Green
    Write-Host "$($args -join ' ')"
}

function error() {
    Write-Host "$(timestamp) " -NoNewline -ForegroundColor Red
    Write-Host "$($args -join ' ')" -ForegroundColor Red
}

$ErrorActionPreference = 'Stop'

trap {
    error $_
}

log "Adding VMware software depot"
$VmwareDepot = Add-EsxSoftwareDepot $VmwareDepotUrl

log "Getting latest image profiles"
$Profiles = Get-EsxImageProfile "ESXi-$($EsxiVersion)*" -SoftwareDepot $VmwareDepot
$LatestProfile = $Profiles | Where-Object Name -match standard | Sort-Object -Property ModifiedTime | Select-Object -Last 1

if (Test-Path -Path "$($LatestProfile.Name).zip") {
    log "Found existing offline bundle, skipping re-export"
} else {
    log "Exporting latest profile to offline bundle"
    Export-ESXImageProfile -ImageProfile $LatestProfile -ExportToBundle -FilePath "$($LatestProfile.Name).zip"
}
Remove-EsxSoftwareDepot $VmwareDepotUrl

log "Adding offline bundle and driver directory as software depots"
$null = Add-EsxSoftwareDepot "$($LatestProfile.Name).zip"

log "Integrating drivers into offline bundle"
$CustomProfileName = "$($LatestProfile.Name)-customized"
$CustomProfile = New-EsxImageProfile -CloneProfile $LatestProfile.Name -Name $CustomProfileName -Vendor $LatestProfile.Vendor

$TempDirectory = "$env:TEMP\vmwareusbfling"
if (-Not (Test-Path -Path $TempDirectory)) {
    $null = New-Item -Path $TempDirectory -ItemType Directory
}
$UsbNicFlingFilename = [System.IO.Path]::GetFileName($UsbNicFlingUrl)
$LocalUsbNicFling = Join-Path -Path $TempDirectory -ChildPath $UsbNicFlingFilename
if (-Not (Test-Path -Path $LocalUsbNicFling)) {
    log "Downloading USB NIC Fling"
    Invoke-WebRequest -Uri $UsbNicFlingUrl -OutFile $LocalUsbNicFling
}

$EsxPackages = Add-EsxSoftwareDepot $LocalUsbNicFling | Get-EsxSoftwarePackage
foreach ($Package in $EsxPackages) {
    log "Integrating $($Package.Name)..."
    $null = Add-EsxSoftwarePackage -ImageProfile $CustomProfileName -SoftwarePackage $Package
}

log "Exporting $CustomProfileName.iso"
Export-ESXImageProfile -ImageProfile $CustomProfileName -ExportToIso -FilePath "$($CustomProfileName).iso" -Force
Get-EsxSoftwareDepot | Remove-EsxSoftwareDepot
log "Completed"