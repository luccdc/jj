# -*- mode: ruby -*-
# vi: set ft=ruby :


$set_environment_variables = <<SCRIPT
dnf install -y perl
tee "/etc/profile.d/myvars.sh" > "/dev/null" <<EOF
export PATH="/jj/bin:$PATH"
export PERL5LIB="/jj/lib:$PERL5LIB"
EOF
SCRIPT


# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|


  # config.vm.define "rhel6" do |rocky|
  #   rocky.vm.box = "rhel_6"
  #   #rocky.vm.box_url = "https://vagrantboxes.lucyber.team/rocky_9.json"
  #   rocky.vm.box_url = "file:///home/judah/20-29-school/24-ccdc/17-packer-templates/artifacts/vagrant/rhel_6.json"
  #   rocky.vm.synced_folder ".", "/vagrant", disabled: true
  #   rocky.vm.synced_folder "./", "/jj"
  #   rocky.vm.provision "shell", inline: $set_environment_variables, run: "always"
  #   rocky.vm.network "private_network", ip: "192.168.56.48"
  #   rocky.vm.ssh.password "Chiapet1!"
  # end


  config.vm.define "rocky9" do |rocky|
    rocky.vm.box = "rocky_9"
    rocky.vm.box_url = "https://vagrantboxes.lucyber.team/rocky_9.json"
    rocky.vm.provision "shell", inline: $set_environment_variables, run: "always"
    rocky.vm.synced_folder ".", "/vagrant", disabled: true
    rocky.vm.synced_folder "./bin", "/jj/bin", type: "nfs", nfs_version: 4
    rocky.vm.synced_folder "./lib", "/jj/lib", type: "nfs", nfs_version: 4
    rocky.vm.network "private_network", ip: "192.168.56.48"
  end

end
