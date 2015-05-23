#!/bin/bash

if [ -z "$1" ]
  then
    echo "No argument supplied, worker name needed."
    exit 1
fi

# inspect the container to extract the IP of our DNS server
DNS_IP=$(sudo docker inspect --format '{{ .NetworkSettings.IPAddress }}' skydns)

# now boot another node for this ring 
newnode=$(sudo docker run -itd \
	--name=$1 \
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
	-v /srv/$1:/var/lib/cassandra/ \
	prodriguezdefino/cassandranode)
echo "Starting node $1.cassandranode.dev.docker ..."
echo "************************************************"
echo $newnode
echo " "