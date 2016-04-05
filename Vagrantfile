# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/trusty64"

  config.vm.define "lxd1" do |lxd1|
    lxd1.vm.box = "ubuntu/trusty64"
    lxd1.vm.network "forwarded_port", guest: 8443, host: 8443
    lxd1.vm.network "private_network", ip: "192.168.103.101"

    lxd1.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      disk_file = File.expand_path("../.vagrant/disks/lxd1-disk1.vdi", __FILE__)

      if ! File.exist?(disk_file)
        vb.customize ['createhd', '--filename', disk_file, '--size', 1024 * 1024]
        vb.customize ['storageattach', :id, '--storagectl', 'SATAController', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk_file]
      end

    end

    lxd1.vm.provision "ansible" do |ansible|
      ansible.playbook = File.expand_path("../spec/vagrant/lxd-playbook.yml", __FILE__)
      ansible.extra_vars = {
        lxd_port: 8443,
        lxd_trust_password: "lxd1"
      }
    end

  end

  config.vm.define "lxd2" do |lxd2|
    lxd2.vm.box = "ubuntu/trusty64"
    lxd2.vm.network "forwarded_port", guest: 8444, host: 8444
    lxd2.vm.network "private_network", ip: "192.168.103.102"

    lxd2.vm.provider "virtualbox" do |vb|
      vb.memory = "256"

      disk_file = File.expand_path("../.vagrant/disks/lxd2-disk1.vdi", __FILE__)

      if ! File.exist?(disk_file)
        vb.customize ['createhd', '--filename', disk_file, '--size', 1024 * 1024]
        vb.customize ['storageattach', :id, '--storagectl', 'SATAController', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', disk_file]
      end
    end

    lxd2.vm.provision "ansible" do |ansible|
      ansible.playbook = File.expand_path("../spec/vagrant/lxd-playbook.yml", __FILE__)
      ansible.extra_vars = {
        lxd_port: 8443,
        lxd_trust_password: "lxd2"
      }
    end

  end

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
end
