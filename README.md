# Self-hosted github runners in SpinW

Because SpinW requires Matlab and in future will need to compile mex files for different OSes,
we decided to use self-hosted Github Actions runners instead of using Github-hosted runners.
(Note that Matlab is [available](https://github.com/matlab-actions/overview)
on Github-hosted *Linux* runners (no other OS))

In order to make the process more secure and scalable we chose to run each workflow in its
its own virtual machine instance so that no data can persist between runs.
This is in order ensure data security and reduce the threat of a malicious actor.
We chose to use full virtual machine instances rather than containers although there is
a performance cost as this would enable easy scalability on a cloud architecture.
[Vagrant](https://www.vagrantup.com/) is used to automate creating and destroying VM instances.
In the concrete implementation used by SpinW, the instances are hosted on the STFC cloud
which uses [OpenStack](https://www.openstack.org/).

In this system a small VM runs a [Flask](https://pythonbasics.org/what-is-flask-python/) webserver
which is always on and listens for requests to start/stop VM instances.
A Github Actions workflow then consists of (at least) three jobs:

 - A "create" job to trigger (via a webhook) the Flask server to start a new VM instance.
   This instance is named after the workflow `ID` to avoid collisions between workflows
   and allow concurrent workflows.
 - The actual CI test / build job is run on the created instance.
 - A "destroy" job to trigger a webhook to the Flask server to destroy the VM instance.

The "create" and "destroy" jobs are run on Github-hosted Linux runners.
The "create" job is needed because it takes a finite amount of time for the VMs to spawn and start.
During this time Github sees that there is no available self-hosted runner.
So, if a job requires a self-hosted runner it would fail.
To enfore this wait, the test job has a `needs` property which depends on the "create" job.
[Github Webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
cannot be used to trigger the VM creation because there is no way to enfore the waiting period.

The "destroy" job is not strictly necessary: VM destruction can be triggered by the test job.
However, as the test job is itself running inside the VM which it is triggering the destruction of,
it cannot wait until the VM is destroyed to see if any error occurs.
In addition, we found that sometimes the destruction is not correctly triggered leaving zombie
VMs active on the system.

The VM images for Linux and Windows which is created on the (STFC) cloud is in 
[QEMU](https://www.qemu.org/) (`qcow2`) format and are generated using
[Packer](https://www.packer.io/).

Finally all the VMs are behind the STFC firewall so the "create" and "destroy" webhooks
cannot directly contact the `Flask` server.
Instead we use a [relay webpage](https://webhookrelay.com/) to forward requests from Github.


## Instructions for use

1. Create a Linux VM and install `python3-flask` and `openssl`
2. Install [`vagrant`](https://www.vagrantup.com/)
3. Clone this repository
4. Create a [webhook relay](https://webhookrelay.com/) account, download the `relay` app
   and run this in a terminal multiplexer:
```
relay login -k <KEY> -s <SECRET>
relay connect http://127.0.0.1:4000
```
5. Run the Flask server in another terminal multiplexer instance:
```
python3 receiveData.py >& logfile
```
6. Copy the [`self_hosted.yml`](.github/workflows/self_hosted.yml) to the repository you
   want to run the Actions, and modify it to run your tests.
7. Add the URL of the webhook (either relay or the URL of the Flask server if it is not
   behind a firewall) to the secrets of this repositroy as `WEBHOOK_URL`.
8. Generate an [Access Token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
   with either the `repo` scope (private _or_ public repositories) or just `public_repo`.
   Put this token as a secret `PERSONAL_TOKEN` in the repo the action will run in.
9. Create a secret called `OPENSSL_PW` with a password for the SSL encryption of the access token.
   If you're using an `https` encrypted webhook, you can comment out the encryption
   in [`self_hosted.yml`](.github/workflows/self_hosted.yml) and decryption in 
   [receiveData.py](receiveData.py) and not use this encryption.

These instructions assume that you've created the VM instances already.
If running with Vagrant boxes on the same system, this means using `vagrant box add` etc.
For running on an OpenStack system, you need to modify the [`Vagrantfile`](Vagrantfile)
to ensure it points to image names which exist.
Also, to use OpenStack with Vagrant,
a [plugin](https://github.com/ggiamarchi/vagrant-openstack-provider) is needed.
OpenStack images can be generated as discussed below.


## Implementation details

The Flask server application is in the [receiveData.py](receiveData.py) file.
An sample Github Actions workflow is in [`.github/workflows/self_hosted.yml`](.github/workflows/self_hosted.yml).

Since the webhook relay does not support `https` unless a subscription fee is paid we use unencrypted webhooks.
However, in order to register the self-hosted runner with Github, an Access Token has to be used.
This could be stored manually on the Flask server but we chose to have it as repository secret
which is passed to the Flask server in the webhook request.
This means that it needs to be encrypted and decrypted which is done in `self_hosted.yaml` and `receiveData.py`.

Setting up the self-hosted runners themselves are done by the `bootstrap_{OS}.*` scripts,
which are run by Vagrant in the provisioning step.
These scripts also write a "teardown" script on the worker VMs which is executed to deregister the runners
when the VMs are destroyed.
These steps are described in the [`Vagrantfile`](Vagrantfile) configuration file.

The [`packer_windows`](packer_windows) folder contains a Packer template to create a Windows 10 image
with Matlab installed from a trial ISO image downloadable from Microsoft.
This trial expires after 90 days, [whereupon](https://www.microsoft.com/en-gb/evalcenter/evaluate-windows-10-enterprise):

```
If you fail to activate this evaluation after installation, or if your evaluation period expires,
the desktop background will turn black, you will see a persistent desktop notification indicating
that the system is not genuine, and the PC will shut down every hour.
```

A new image can the be created using Packer or the image can still be run with the 1h time limit
(since our tests last <~10min).

The [`openstack`](openstack) folder contains scripts for creating a Linux image with Matlab installed from
stock Ubuntu images on the STFC cloud.
The [`run_installation.sh`](openstack/run_installation.sh) script is used to launch an instance
and install Matlab using Vagrant, and then to upload the image for future use.
The installation details are in [`bootstrap.sh`](openstack/bootstrap.sh).


## Timings

For these workflows timing is as follows:

- Create and register VM: ~ 5 minutes
- Run test > ~3 minutes on Linux, ~9 minutes on Windows
- Destroy VM ~ 1 minute

It can be noted that the create VM task can be sped up by ~1.5 minutes in provisioning
if it does not check for system updates.
But from a security standpoint, we want these updates to happen.

It's unclear why the Windows tests take over twice as long as the Linux even though the VM is the same type.


## Platform specific notes


### Windows

[Packer](https://www.packer.io/docs/builders/vagrant) is used to create a `box` for Windows.
The [`packer_windows`](packer_windows) folder has the necessary files to build a Windows 10 `box` from a MS evaluation image.
It assumes you have a Matlab installation ISO which can be mounted.
To use it, modify the `installer_input.txt` file, [download packer](https://www.packer.io/downloads) and run:

```
./packer build --only virtualbox-iso windows_10.json -var matlab_iso=./matlab.iso -var matlab_installer_input=./installer_input.txt -var matlab_license_file=./network.lic
```

Note that the variables values shown are the defaults - if you're happy with those, you can omit them.
If not, you can also redefine them in `windows_10.json`

If you're using the web-installer, please use the "Download Products Without Installing" options to get the installer files.
Make an iso from the installer files and use that. 
(It should also be possible to use a shared folder by modifying the `vboxmanage` section in `windows_10.json` but this has not been tested.
This would also likely need changes to `install_matlab.ps1`.)
To get the "File Installation Key", in the "Install and Activate" webpage, answer "No" to whether you have installed or not.

Note that the windows evaluation will run for 90 days, and then ([from Microsoft](https://www.microsoft.com/en-gb/evalcenter/evaluate-windows-10-enterprise)):

```
If you fail to activate this evaluation after installation, or if your evaluation period expires,
the desktop background will turn black, you will see a persistent desktop notification indicating
that the system is not genuine, and the PC will shut down every hour.
```

This should be ok for our purposes (the tests only take ~5 min).

Alternatively, `packer` could be run again to regenerate the image and so reset the 90 day countdown.


### OpenStack

Vagrant can also be used to run OpenStack directly using a [plugin](https://github.com/ggiamarchi/vagrant-openstack-provider).
The script in the `openstack` folder can be run to automatically update and install Matlab on the VM.
The OpenStack VM is commented out in the `Vagrantfile` at present - to use it, comment out the `linux` entry and uncomment the `openstack` one.
The STFC openstack implementation only supports password log in so this is stored in an environment variable for security reasons.
You need to export the `OS_USERNAME` and `OS_PASSWORD` variables before running the Python webhook receiver, otherwise the VM cannot be started in the workflow.
Note that there is a [bug in the plugin](https://github.com/ggiamarchi/vagrant-openstack-provider/issues/387)
where it uses non-standard states which means the teardown trigger does not run. You can either modify the Ruby file in Vagrant itself
(change line 307 of `trigger.rb` to `elsif @machine.state.id != :running && @machine.state.id != :active`)
or change the plugin code and recompile (many more lines; not explored/tried).


### MacOS

Currently, MacOS is not supported because licensing restrictions means that a MacOS VM must run on a physical MacOS machine
and this is not compatible with the STFC cloud which is running on Linux servers.
MacOS support is probably best handled by either hosting the Flask server on a MacOS machine
and having it spawn VMs or Docker containers or writing a custom Vagrant provider to spawn such container on an external machine.
