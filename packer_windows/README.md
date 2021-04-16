# Packer template to create a Windows 10 VM with Matlab installed

Most of these files were taken from [StefanScherer/packer-windows](https://github.com/StefanScherer/packer-windows).

This folder contains templates for [Packer](https://www.packer.io/docs/builders/vagrant)
to create vagrant boxes for Windows 10 with Matlab installed from an installation ISO.
By default the script will download an evaluation ISO image from Microsoft.
This installation will then expire in 90 days.
You can also specify your own ISO file instead.

The script also assumes that you have a Matlab installation ISO which can be mounted.
If you're using the web-installer, please use the "Download Products Without Installing"
option to get the installer files.
Make an iso from the installer files and use that. 
(It should also be possible to use a shared folder by modifying the `vboxmanage` section
in [`windows_10.json`](windows_10.json) but this has not been tested.
This would also likely need changes to [`install_matlab.ps1`](scripts/install_matlab.ps1).)
To get the "File Installation Key", in the "Install and Activate" webpage,
answer "No" to whether you have installed or not.
You should then put this key in the [`installer_input.txt`](installer_input.txt) file.

To create a VirtualBox image use:

```
./packer build --only virtualbox-iso windows_10.json -var matlab_iso=./matlab.iso -var matlab_installer_input=./installer_input.txt -var matlab_license_file=./network.lic
```

Note that the variables values shown are the defaults - if you're happy with those, you can omit them.
If not, you can also redefine them in `windows_10.json`

E.g. to create a QEMU image with the default values use:

```
./packer build --only qemu windows_10.json
```

Only the VirtualBox and QEMU builders have been changed to install Matlab and tested so far.
(The other builders will likely fail).


Note that the windows evaluation will run for 90 days. 
After this, ([from Microsoft](https://www.microsoft.com/en-gb/evalcenter/evaluate-windows-10-enterprise)):

```
If you fail to activate this evaluation after installation, or if your evaluation period expires,
the desktop background will turn black, you will see a persistent desktop notification indicating
that the system is not genuine, and the PC will shut down every hour.
```

So you will need to run `packer` again to regenerate the image,
or depending on your needs, the 1 hour limit may be enough.
