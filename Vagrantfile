Vagrant.configure("2") do |config|

   config.vm.define "linux" do |linux|
       linux.vm.box = "matlab_linux"
       linux.vm.provider "virtualbox" do |vb|
         vb.customize ["modifyvm", :id, "--macaddress1", "5CA1AB1E0001" ]
       end

       linux.vm.provision :shell, inline: "cat /vagrant/bootstrap_vars.sh > /root/.bashrc", :run => 'always'

       linux.vm.provision :shell do |s|
           s.path = 'bootstrap_linux.sh'
       end

       linux.trigger.before :destroy do |trigger|
           trigger.info = "Remove the github runner"
           trigger.run_remote = {inline: "/root/teardown.sh"}
       end
   end
#    config.vm.define "macos" do |macos|
#        macos.vm.box = "ramsey/macos-catalina"
#        macos.vm.provider "virtualbox" do |vb|
#          vb.customize ["modifyvm", :id, "--macaddress1", "5CA1AB1E0001" ]
#        end
#        macos.vm.provision :shell, inline: "echo 'source /vagrant/bootstrap_vars.sh' >> /etc/profile", :run => 'always'
#    end
#
#    config.vm.define "windows" do |windows|
#        windows.vm.box = "gusztavvargadr/windows-10"
#        windows.vm.provider "virtualbox" do |vb|
#          vb.customize ["modifyvm", :id, "--macaddress1", "020000160423" ]
#        end
#        windows.vm.provision :shell, inline: "C:\vagrant\modify_boxes\volumeid.exe C 8EB83CB0 -nobanner", :run => 'always'
#    end
end
