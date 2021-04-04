require 'vagrant-openstack-provider'

Vagrant.configure("2") do |config|
    config.vm.define "linux" do |linux|
        linux.vm.box = "matlab_linux"
        linux.vm.provider "virtualbox" do |vb|
          vb.customize ["modifyvm", :id, "--macaddress1", "5CA1AB1E0001" ]
        end
        linux.vm.provision :shell, path: 'bootstrap_linux.sh'
        linux.trigger.before :destroy do |trigger|
            trigger.info = "Remove the github runner"
            trigger.run_remote = {inline: "/root/teardown.sh"}
        end
    end
 
#   config.ssh.username = "vagrant"
#   config.ssh.private_key_path = "~/.vagrant.d/insecure_private_key"
#   config.vm.define "linux" do |linux|
#       linux.vm.provider "openstack" do |os|
#           os.openstack_auth_url = "https://openstack.nubes.rl.ac.uk:5000/v3"
#           os.identity_api_version = "3"
#           os.project_name = "SpinW_CI"
#           os.project_domain_name = "default"
#           os.user_domain_name = "stfc"
#           os.username = ENV['OS_USERNAME']
#           os.password = ENV['OS_PASSWORD']
#           os.region = "RegionOne"
#           os.flavor = "m3.small"
#           os.image = "matlab_linux"
#           os.availability_zone = "ceph"
#           os.keypair_name = "vagrant_insecure"
#       end
#       linux.vm.synced_folder ".", "/vagrant", type: "rsync"
#       linux.vm.provision :shell, path: 'bootstrap_linux.sh'
#       linux.trigger.before :destroy do |trigger|
#           trigger.info = "Remove the github runner"
#           trigger.run_remote = {inline: "/root/teardown.sh"}
#       end
#   end

#   config.vm.define "windows" do |windows|
#       windows.vm.provider "openstack" do |os|
#           os.openstack_auth_url = "https://openstack.nubes.rl.ac.uk:5000/v3"
#           os.identity_api_version = "3"
#           os.project_name = "SpinW_CI"
#           os.project_domain_name = "default"
#           os.user_domain_name = "stfc"
#           os.username = ENV['OS_USERNAME']
#           os.password = ENV['OS_PASSWORD']
#           os.region = "RegionOne"
#           os.flavor = "m3.small"
#           os.image = "matlab_windows"
#           os.availability_zone = "ceph"
#           os.keypair_name = "vagrant_insecure"
#       end
#       windows.vm.guest = :windows
#       windows.vm.communicator = 'winrm'
#       # NFS folder syncing doesn't work on qemu and we didn't install rsync
#       windows.vm.synced_folder ".", "/vagrant", disabled: true
#       windows.vm.provision "file", source: "bootstrap_vars_windows", destination: "c:/vagrant/bootstrap_vars_windows"
#       windows.vm.provision :shell, path: 'bootstrap_windows.ps1'
#       windows.trigger.before :destroy do |trigger|
#           trigger.info = "Remove the github runner"
#           trigger.run_remote = {inline: "c:/users/vagrant/teardown.ps1"}
#       end
#   end

#   config.vm.define "macos" do |macos|
#       macos.vm.box = "matlab_macOS"
#       macos.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: [".vagrant/", ".git/", "*.box", "boxes/", "modify_boxes/"]
#       macos.vm.provision :shell, inline: "/bin/zsh /vagrant/bootstrap_macos.sh", :run => 'always'
#
#       macos.trigger.before :destroy do |trigger|
#           trigger.info = "Remove the github runner"
#           trigger.run_remote = {inline: "/Users/vagrant/teardown.sh"}
#       end
#   end

    config.vm.define "windows" do |windows|
        windows.vm.box = "matlab_windows"
        windows.vm.provider "virtualbox" do |vb|
             #vb.customize ["modifyvm", :id, "--memory", 8192]
             #vb.customize ["modifyvm", :id, "--cpus", 4]
             vb.customize ["modifyvm", :id, "--macaddress1", "020000160423" ]
        end
        windows.vm.provision :shell, path: 'bootstrap_windows.ps1'
        windows.trigger.before :destroy do |trigger|
            trigger.info = "Remove the github runner"
            trigger.run_remote = {inline: "c:/users/vagrant/teardown.ps1"}
        end
    end

end
