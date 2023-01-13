#!/bin/bash
echo '############################## installing docker...'
sudo apt-get update -y
sudo apt-get -y install docker.io
echo '############################## installing wp...'
sudo docker pull wordpress
echo '############################## running wp...'
sudo docker run --restart always --name wpsite -e WORDPRESS_DB_HOST=$1:3306 -e WORDPRESS_DB_USER=$2 -e WORDPRESS_DB_PASSWORD=$3 -p 80:80 -d wordpress
echo '############################## Done'
sleep 20