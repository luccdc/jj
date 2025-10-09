# -*- mode: ruby -*-
# vi: set ft=ruby :


$set_environment_variables = <<SCRIPT
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

  config.vm.define "rocky9" do |rocky|
    rocky.vm.box = "rocky_9"
    rocky.vm.box_url = "https://vagrantboxes.lucyber.team/rocky_9.json"
    rocky.vm.synced_folder ".", "/vagrant", disabled: true
    rocky.vm.network "private_network", ip: "192.168.56.48"
  end

end
