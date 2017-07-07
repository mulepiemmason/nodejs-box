# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
 
    config.vm.box = "ubuntu/xenial64"
    #config.vm.box = "ffuenf/debian-6.0.9-amd64"

    # Configgure a private network to allow access to only localhost
    # config.vm.network :private_network, ip: "192.168.33.10"

    config.vm.network :forwarded_port, guest: 27017, host: 27017
    config.vm.network :forwarded_port, guest: 3131, host: 3131, auto_correct: true

    # Configure shared folders with nfs
    # config.vm.synced_folder "../", "/opt/dev", :nfs => true, :create => true

    config.vm.provider :virtualbox do |vb|
        vb.memory = 256
    end

    config.vm.provision :shell, :keep_color => true, :path => "bootstrap.sh", :privileged => false

end
