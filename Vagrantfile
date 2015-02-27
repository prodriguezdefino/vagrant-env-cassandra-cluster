VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|  
  config.vm.provider :virtualbox do |vb|
    vb.memory = 2048
    vb.cpus = 1
    vb.name = "cassandra-cluster-env-host.dev"
  end
  config.vm.hostname = "cassandra-cluster-env-host.dev"
  config.vm.box = "ubuntu/trusty64"

  # opscenter port
  config.vm.network "forwarded_port", guest: 8888, host: 8888
  # cassandra seed ports
  config.vm.network "forwarded_port", guest: 7000, host: 7000
  config.vm.network "forwarded_port", guest: 7001, host: 7001
  config.vm.network "forwarded_port", guest: 7199, host: 7199
  config.vm.network "forwarded_port", guest: 9042, host: 9042
  config.vm.network "forwarded_port", guest: 9160, host: 9160
  # cassandra node ports (defaults +100)
  config.vm.network "forwarded_port", guest: 7100, host: 7100
  config.vm.network "forwarded_port", guest: 7101, host: 7101
  config.vm.network "forwarded_port", guest: 7299, host: 7299
  config.vm.network "forwarded_port", guest: 9142, host: 9142
  config.vm.network "forwarded_port", guest: 9260, host: 9260

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
    
    # then launch a skydns container to register our network addresses
    dns=$(docker run -d \
	    -p $DOCKER0_IP:53:53/udp \
	    --name skydns \
	    crosbymichael/skydns \
	    -nameserver $fwd_dns:53 \
	    -domain docker)
    echo "Starting dns regristry..."
    echo "*************************"
    echo $dns
    echo " "
    
    # inspect the container to extract the IP of our DNS server
    DNS_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' skydns)
    
    # launch skydock as our listener of container events in order to register/deregister all the names on skydns
	skydock=$(docker run -d \
		-v /var/run/docker.sock:/docker.sock \
		--name skydock \
		crosbymichael/skydock \
		-ttl 30 \
		-environment dev \
		-s /docker.sock \
		-domain docker \
		-name skydns)
    echo "Starting docker event listener..."
    echo "*********************************"
    echo $skydock
    echo " "
    
    # boot a cassandra node as a seed 
	seed1=$(docker run -itd \
		--name=seed1 \
		-h seed1.cassandranode.dev.docker \
		--dns=$DNS_IP \
		-e "http_proxy=$http_proxy" \
		-e "https_proxy=$https_proxy" \
		-p 7000:7000 \
		-p 7001:7001 \
		-p 7199:7199 \
		-p 9042:9042 \
		-p 9160:9160 \
		prodriguezdefino/cassandranode)
    echo "Starting seed node seed1.cassandranode.dev.docker ..."
    echo "*****************************************************"
    echo $seed1
    echo " "
    
    # now boot another node for this ring 
	node1=$(docker run -itd \
		--name=node1 \
		-h node1.cassandranode.dev.docker \
		--dns=$DNS_IP \
		-e "http_proxy=$http_proxy" \
		-e "https_proxy=$https_proxy" \
		-e "SEEDS_IPS=seed1.cassandranode.dev.docker" \
		-e "OPTS_CENTER=true" \
		-p 8888:8888 \
		-p 7100:7000 \
		-p 7101:7001 \
		-p 7299:7199 \
		-p 9142:9042 \
		-p 9260:9160 \
		prodriguezdefino/cassandranode)
    echo "Starting node node1.cassandranode.dev.docker ..."
    echo "************************************************"
    echo $node1
	echo " "
    
    echo "Ops Center available on node1.cassandranode.dev.docker:8888 ..."
    echo "***************************************************************"
    echo " "

  SCRIPT
end
