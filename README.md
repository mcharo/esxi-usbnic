# Integrating the VMware USB NIC Fling driver into ESXi 7.x

Honestly, you should probably use [ESXi-Customizer-PS](https://github.com/VFrontDe/ESXi-Customizer-PS), but if your use case is this one and you've run into an error similar to `Export-ESXImageProfile : [WinError 10054] An existing connection was forcibly closed by the remote host` then give this a shot.

## Requirements

- `VMware.ImageBuilder` 7.x PowerShell module
- Windows + PowerShell Desktop edition
    - This is only because: `The VMware.ImageBuilder module is not currently supported on the Core edition of PowerShell.`

## Demo

The gif has been sped up but the timestamps within the image are accurate.
![Demo of script](esxi.gif)