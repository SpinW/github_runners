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
           trigger.run_remote = {inline: "c:/github/teardown.ps1"}
       end
#      windows.vm.provision :shell, inline: "C:\vagrant\modify_boxes\volumeid.exe C 8EB83CB0 -nobanner", :run => 'always'
   end
end
