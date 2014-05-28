# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = "quantal64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/quantal/current/quantal-server-cloudimg-amd64-vagrant-disk1.box"
  config.vm.provision :shell, :path => "provision.sh"
  config.ssh.forward_agent = true
end

Vagrant.configure("2") do |config|
    config.vm.provider :virtualbox do |v|
        v.customize ["modifyvm", :id, "--memory", 2048]
    end
    config.vm.provider :vmware_fusion do |v|
      config.vm.define :cedarish do |s|
        v.vmx["memsize"] = "2048"
      end
      config.vm.define :cedarish do |s|
        v.vmx["displayName"] = "cedarish"
      end
    end
end