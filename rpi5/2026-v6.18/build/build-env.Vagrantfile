Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/noble64"
#  config.vm.box_version = "3.1.16"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "8192"]
    vb.customize ["modifyvm", :id, "--cpus", "8"]
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    #vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
  end

end
