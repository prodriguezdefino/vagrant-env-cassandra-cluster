VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|  
  config.vm.provider :virtualbox do |vb|
    vb.memory = 2048
    vb.cpus = 1
    vb.name = "cassandra-cluster-env-host.dev"
  end
  config.vm.hostname = "cassandra-cluster-env-host.dev"
  config.vm.box = "ubuntu/trusty64"

  # hadoop base ports in master
  config.vm.network "forwarded_port", guest: 8888, host: 8888

  config.vm.provision :shell, inline: <<-SCRIPT
    echo "Setting env variables..."
    echo "************************"
    echo " "
    # set a nameserver to forward anything outside .docker domain 
    sh -c 'echo "export fwd_dns="8.8.8.8"" >> .bashrc' 
    # set web proxy servers if needed
    sh -c 'echo "export http_proxy=""" >> .bashrc' 
    sh -c 'echo "export https_proxy=""" >> .bashrc' 
  SCRIPT

  config.vm.provision "docker",
    images: ["crosbymichael/skydns","crosbymichael/skydock","prodriguezdefino/cassandranode"]

 config.vm.provision :shell, inline: <<-SCRIPT
    env
    echo "Provisioning Docker..."
    echo "**********************"
    echo " "
    sudo sh -c 'echo "DOCKER_OPTS=\\"-H tcp://0.0.0.0:4444 -H unix:///var/run/docker.sock\\"" >> /etc/default/docker'
    sudo restart docker
    sleep 2 
    echo " "
    echo "Starting containers..."
    echo "**********************"
    echo " "
    
    echo "cleaning up..."
    echo "**************"
    docker rm $(docker ps -qa)
    echo " "
    
    # first find the docker0 interface assigned IP
    DOCKER0_IP=$(ip -o -4 addr list docker0 | perl -n -e 'if (m{inet\s([\d\.]+)\/\d+\s}xms) { print $1 }')
    
    echo "Starting dns regristry..."
    echo "*************************"
    # then launch a skydns container to register our network addresses
    docker run -d -p $DOCKER0_IP:53:53/udp --name skydns crosbymichael/skydns -nameserver $fwd_dns:53 -domain docker
    echo " "
    
    # inspect the container to extract the IP of our DNS server
    DNS_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' skydns)
    
    echo "Starting docker event listener..."
    echo "*********************************"
    # launch skydock as our listener of container events in order to register/deregister all the names on skydns
    docker run -d -v /var/run/docker.sock:/docker.sock --name skydock crosbymichael/skydock -ttl 30 -environment dev -s /docker.sock -domain docker -name skydns
    echo " "
    
    echo "Starting seed node seed1.cassandranode.dev.docker ..."
    echo "*****************************************************"
    # boot a cassandra node as a seed 
	docker run -itd --name=seed1 -h seed1.cassandranode.dev.docker --dns=$DNS_IP -e "http_proxy=$http_proxy" -e "https_proxy=$https_proxy" prodriguezdefino/cassandranode
    echo " "
    
    echo "Starting node node1.cassandranode.dev.docker ..."
    echo "************************************************"
    # now boot another node for this ring 
	docker run -itd --name=node1 -h node1.cassandranode.dev.docker --dns=$DNS_IP -e "http_proxy=$http_proxy" -e "https_proxy=$https_proxy" -e "SEEDS_IPS=seed1.cassandranode.dev.docker" -e "OPTS_CENTER=true" -p 8888:8888 prodriguezdefino/cassandranode
	echo " "
    
    echo "Ops Center available on node1.cassandranode.dev.docker:8888 ..."
    echo "***************************************************************"
    echo " "

  SCRIPT
end
