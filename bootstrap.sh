#!/bin/sh

# This is the main script for provisioning.  Out of this
# file, everything that builds the box is executed.

### Software ###
# NodeJS 4.4.5
# MongoDB 3.2.7
# MySQL
# Git


### Build the box


# Make /opt directory owned by vagrant user
sudo chown ubuntu:ubuntu /opt/

### Update the system
sudo apt-get update

### Install system dependencies
echo "Installing system dependencies"
sudo apt-get install -y build-essential curl g++ git libaio1 libaio-dev nfs-common redis-server openssl python-software-properties tcl python make
sudo apt-get install -y make vim libcairo2-dev libav-tools portmap memcached xz-utils

echo "Run 'vagrant ssh' then set your git config manually, e.g.:"
echo "ssh-keygen -t rsa"
echo "(Copy the contents of ~/.ssh/id_rsa.pub into your GitHub account: https://github.com/settings/ssh)"
echo "git config --global user.name '<your name>'"
echo "git config --global user.email <your email>"

# Heroku toolbelt:
echo "Installing Heroku Toolbelt"

wget -qO- https://toolbelt.heroku.com/install-ubuntu.sh | sh

echo "Run the following commands to finish setting up Heroku:"
echo "heroku login"
echo "heroku keys:add"
echo "heroku git:remote -a heroku"


# Travis-CI toolbelt: install ruby1.9.1-dev package & Travis gem:
# echo "Installing Travis-CI"
# apt-get remove -y ruby1.9.1
# apt-get install -y ruby1.9.1-dev
# gem install travis --no-rdoc --no-ri

# echo "Run the following commands to login:"
# echo "travis login"


# Redis: 
echo "Edit the redis config file by typing the command below"
echo "sudo nano /etc/redis/redis.conf"
echo "Add the text below to the end of the file"
echo "maxmemory 128mb"
echo "maxmemory-policy allkeys-lru"
echo "Since we are running an operating system that uses the systemd init system, we can change set the supervised directive to systemd as below"
echo "supervised systemd"
echo "Set the directory that Redis will use to dump persistent data."
echo "dir /var/lib/redis"
echo "Create a Redis systemd Unit File"
echo "sudo nano /etc/systemd/system/redis.service"
echo "Add the following to the file"
echo "[Unit]
	Description=Redis In-Memory Data Store
	After=network.target
	[Service]
	User=redis
	Group=redis
	ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
	ExecStop=/usr/local/bin/redis-cli shutdown
	Restart=always
	[Install]
	WantedBy=multi-user.target"
echo "Create the Redis User, Group and Directories"

sudo chown redis:redis /var/lib/redis
sudo chmod 770 /var/lib/redis
echo "Start and Test Redis"
sudo systemctl start redis
sudo systemctl status redis


### NodeJS ###

# Download the binary
echo " Installing NodeJS"

# wget -q https://nodejs.org/dist/v6.11.0/node-v6.11.0-linux-x64.tar.xz -O /tmp/node-v6.11.0-linux-x64.tar.xz
# echo "NodeJS download completed"
# Unpack it
# cd /tmp
# tar -xvf /tmp/node-v6.11.0-linux-x64.tar.xz
# mv /tmp/node-v6.11.0-linux-x64 /opt/node-v6.11.0-linux-x64
# ln -s /opt/node-v6.11.0-linux-x64 /opt/nodejs

# Set the node_path
# export NODE_PATH=/opt/nodejs/lib/node_modules
# export NODE_PATH=$NODE_PATH:/opt/dev/node_modules
# export NODE_PATH=$NODE_PATH:/opt/dev/lib/node_modules
# export NODE_PATH=$NODE_PATH:/usr/local/lib/node_modules

# Install global Node dependencies
# /opt/nodejs/bin/npm install -g n

# /opt/nodejs/bin/npm config set loglevel http
# which nodejs
# ln -s /usr/bin/nodejs /usr/bin/node

curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs

# TODO: Install cloud9 IDE


### MongoDB ###
echo "Installing and setting up MongoDB"

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo service mongod start

### Add binaries to path ###

echo "Adding Binaries to system path"
# First run the command
export PATH=$PATH:/opt/mongodb/bin:/opt/nodejs/bin
export NODE_PATH=/opt/nodejs/lib/node_modules
export NODE_PATH=$NODE_PATH:/opt/dev/node_modules
export NODE_PATH=$NODE_PATH:/opt/dev/lib/node_modules
export NODE_PATH=$NODE_PATH:/usr/local/lib/node_modules/lib/node_modules:/usr/local/lib/node_modules

# Now save to the /etc/bash.bashrc file so it works on reboot
cp /etc/bash.bashrc /tmp/bash.bashrc
printf "\n#Add binaries to path\n\nexport PATH=$PATH:/opt/mongodb/bin:/opt/mysql/server-5.6/bin:/opt/nodejs/bin\nexport NODE_PATH=/opt/nodejs/lib/node_modules\nexport NODE_PATH=$NODE_PATH:/opt/dev/node_modules\nexport NODE_PATH=$NODE_PATH:/opt/dev/lib/node_modules" > /tmp/path
cat /tmp/path >> /tmp/bash.bashrc
sudo chown root:root /tmp/bash.bashrc
sudo mv /tmp/bash.bashrc /etc/bash.bashrc


### Update the /etc/hosts file ###
echo "Updating /etc/hosts file"
printf '127.0.0.1       localhost\n127.0.1.1       debian-squeeze.caris.de debian-squeeze nodebox\n\n# The following lines are desirable for IPv6 capable hosts\n::1     ip6-localhost ip6-loopback\nfe00::0 ip6-localnet\nff00::0 ip6-mcastprefix\nff02::1 ip6-allnodes\nff02::2 ip6-allrouters' > /tmp/hosts
sudo mv /tmp/hosts /etc/hosts

printf 'export GITAWAREPROMPT=~/.bash/git-aware-prompt\nsource $GITAWAREPROMPT/main.sh\n\nexport PS1="\${debian_chroot:+(\\$debian_chroot)}\\[\\033[01;32m\\]\\u@\\h\\[\\033[00m\\]:\\[\\033[01;34m\\]\\w\\[\\033[00m\\] \\[$txtcyn\\]\\$git_branch\\[$txtred\\]\\$git_dirty\\[$txtrst\\]\$ "' > ~/.bash_profile

### Test that everything is installed ok ###
printf "\n\n--- Running post-install checks ---\n\n"
node /vagrant/files/postInstall.js

### Finished ###
printf "\n\n--- NodeBox is now built ---\n\n"