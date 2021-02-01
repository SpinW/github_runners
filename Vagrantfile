Vagrant.configure("2") do |config|
    config.vm.box = "hashicorp/bionic64"
    config.vm.box_url = "https://vagrantcloud.com/hashicorp/bionic64"

   config.vm.provision :shell, inline: "echo 'source /vagrant/bootstrap_vars.sh' > /etc/profile.d/gh-environment.sh", :run => 'always'

    config.vm.provision :shell do |s|
        s.path = 'bootstrap.sh'
    end

    config.trigger.before :destroy do |trigger|
        trigger.info = "Remove the github runner"
        trigger.run_remote = {inline: "/home/github/teardown.sh"}
    end
end