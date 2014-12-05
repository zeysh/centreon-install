# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "debian7"
  config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/debian-73-x64-virtualbox-puppet.box"

  config.vm.provider :virtualbox do |virtualbox|
    if Vagrant.has_plugin?("vagrant-cachier")
      config.cache.scope = :box
      config.cache.synced_folder_opts = {
        type: :nfs,
        mount_options: ['rw', 'vers=3', 'tcp', 'nolock']
      }
    end
  end

  config.vm.network :forwarded_port, guest: 80, host: 8080

  config.vm.define :centreon do |master_config|
     master_config.vm.box = config.vm.box
     master_config.vm.host_name = "centreon"
     master_config.vm.network :private_network, ip: '192.168.33.10'

     master_config.vm.provider :virtualbox do |vb|
  #   # Don't boot with headless mode
  #   vb.gui = true
  #
     vb.customize ["modifyvm", :id, "--memory", "2048"]
   end
     master_config.vm.provision :shell,
       :path => "centreon.sh"
   end
end
