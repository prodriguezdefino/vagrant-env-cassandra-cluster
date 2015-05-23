VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|  
  config.vm.provider :virtualbox do |vb|
    vb.memory = 5120
    vb.cpus = 2
    vb.name = "cass-cluster-env-host.dev"
  end
  config.vm.hostname = "cass-cluster-env-host.dev"
  config.vm.box = "ubuntu/trusty64"

  # cassandra ports
  config.vm.network "forwarded_port", guest: 7199, host: 7199
  config.vm.network "forwarded_port", guest: 7000, host: 7000
  config.vm.network "forwarded_port", guest: 7001, host: 7001
  config.vm.network "forwarded_port", guest: 9160, host: 9160
  config.vm.network "forwarded_port", guest: 9042, host: 9042
  # opscenter web console access port
  config.vm.network "forwarded_port", guest: 8888, host: 8888
  # monitoring ports for opscenter communication
  config.vm.network "forwarded_port", guest: 61620, host: 61620
  config.vm.network "forwarded_port", guest: 61621, host: 61621
  
  config.vm.provision "docker",
    images: ["crosbymichael/skydns","crosbymichael/skydock","prodriguezdefino/cassandranode"]

  config.vm.provision :shell, path: "cassandra-docker-startup.sh"
end
