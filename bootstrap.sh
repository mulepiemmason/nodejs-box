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
echo "Current User: "
whoami
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
wget -q https://nodejs.org/dist/v6.11.0/node-v6.11.0-linux-x64.tar.xz -O /tmp/node-v6.11.0-linux-x64.tar.xz
echo "NodeJS download completed"
# Unpack it
cd /tmp
tar -xvf /tmp/node-v6.11.0-linux-x64.tar.xz
mv /tmp/node-v6.11.0-linux-x64 /opt/node-v6.11.0-linux-x64
ln -s /opt/node-v6.11.0-linux-x64 /opt/nodejs

# Set the node_path
export NODE_PATH=/opt/nodejs/lib/node_modules
export NODE_PATH=$NODE_PATH:/opt/dev/node_modules
export NODE_PATH=$NODE_PATH:/opt/dev/lib/node_modules
export NODE_PATH=$NODE_PATH:/usr/local/lib/node_modules

# Install global Node dependencies
/opt/nodejs/bin/npm install -g n

/opt/nodejs/bin/npm config set loglevel http

sudo ln -s "$(which nodejs)" /usr/local/bin/node

# TODO: Install cloud9 IDE


### MongoDB ###
echo "Installing and setting up MongoDB"

# Download it
# NOTE: Always check online for the latest version and change respectively
wget -q https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1604-3.4.6.tgz -O /tmp/mongodb-linux-x86_64-ubuntu1604-3.4.6.tgz

# Create mongo user and group
sudo groupadd -g 550 mongodb
sudo useradd -g mongodb -u 550 -c "MongoDB Database Server" -M -s /sbin/nologin mongodb

# Unpack it and move to /opt directory
cd /tmp
tar -zxvf mongodb-linux-x86_64-ubuntu1604-3.4.6.tgz
mv /tmp/mongodb-linux-x86_64-ubuntu1604-3.4.6 /opt
ln -s /opt/mongodb-linux-x86_64-ubuntu1604-3.4.6 /opt/mongodb

# Create the directories
mkdir -p /opt/mongodb/data
mkdir -p /opt/mongodb/etc
mkdir -p /opt/mongodb/log
mkdir -p /opt/mongodb/run

# Set permissions:
sudo chown mongodb /opt/mongodb/data
sudo chown mongodb /opt/mongodb/log
sudo chown mongodb /opt/mongodb/run

# Create the config file
printf "port = 27017\nlogpath=/opt/mongodb/log/mongodb.log\nfork = true\ndbpath=/opt/mongodb/data\npidfilepath=/opt/mongodb/run/mongodb.pid\nnojournal=true" > /opt/mongodb/etc/mongodb.conf

# Create the init.d file
printf '#!/bin/bash\n\nControls the main MongoDB server daemon "mongod"\n### END INIT INFO\n\n\npid_file="/opt/mongodb/run/mongodb.pid"\n\n\n# abort if not being ran as root\nif [ "${UID}" != "0" ] ; then\n        echo "you must be root"\n        exit 20\nfi\n\n\nstatus() {\n        # read pid file, return if file does not exist or is empty\n        if [ -f "$pid_file" ] ; then\n                read pid < "$pid_file"\n                if [ -z "${pid}" ] ; then\n                        # not running (empty pid file)\n                        return 1\n                fi\n        else\n                # not running (no pid file)\n                return 2\n        fi\n\n        # pid file exists, check if it is stale\n        if [ -d "/proc/${pid}" ]; then\n                # it is running (pid file is valid)\n                return 0\n        else\n                # not running (stale pid file)\n                return 3\n        fi\n}\n\nshow_status() {\n       # get the status\n        status\n\n        case "$?" in\n      0)\n            echo "running (pid ${pid})"\n           return 0\n          ;;\n        1)\n            echo "not running (empty pid file)"\n           return 1\n          ;;\n        2)\n            echo "not running (no pid file)"\n          return 2\n          ;;\n        3)\n            echo "not running (stale pid file)"\n           return 3\n          ;;\n        *)\n            # should never get here\n           echo "could not get status"\n           exit 10\n   esac\n}\n\nstart() {\n  # return if it is already running\n if ( status ) ; then\n      echo "already running"\n        return 1\n  fi\n\n  # start it\n    echo "Starting MongoDB"\n   sudo /bin/bash -c "/opt/mongodb/bin/mongod --quiet -f /opt/mongodb/etc/mongodb.conf run"\n}\n\nstop() {\n   # return if it is not running\n if ( ! status ) ; then\n        echo "already stopped"\n        return 1\n  fi\n\n  # stop it\n # call status again to get the pid\n    status\n    echo "Stopping MongoDB (killing ${pid})"\n  kill "${pid}"\n}\n\n\ncase "$1" in\n    status)\n       show_status\n       ;;\n    start)\n        start\n     ;;\n    stop)\n     stop\n      ;;\n    *)\n        echo $"Usage: $0 {start|stop|status}"\n     exit 100\nesac\n\nexit $?\n\n' > /opt/mongodb/etc/init-script
chmod 755 /opt/mongodb/etc/init-script

# Register the init.d file
sudo update-rc.d mongodb defaults

# Start MongoDB
sudo service mongodb start


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