#!/bin/bash

## see: https://www.youtube.com/watch?v=-OOnGK-XeVY

DOMAIN=${DOMAIN:="antboss.ml"}
USERNAME=${USERNAME:="zzes"}
PASSWORD=${PASSWORD:=Ga841127}

SCRIPT_REPO=${SCRIPT_REPO:="https://raw.githubusercontent.com/hebskjcc/installcentos/ocu"}

echo "******"
echo "* Your domain is $DOMAIN "
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "******"

usermod -aG wheel zzes

yum install -y epel-release

yum install -y wget zile vim nano net-tools docker httpd-tools NetworkManager rubygem-psych

systemctl start NetworkManager
systemctl enable NetworkManager

echo "127.0.0.1	$(hostname)" >> /etc/hosts

if [ -z $DISK ]; then 
	echo "Not setting the Docker storage."
else
	echo DEVS=$DISK >> /etc/sysconfig/docker-storage-setup
	echo VG=DOCKER >> /etc/sysconfig/docker-storage-setup
	echo SETUP_LVM_THIN_POOL=yes >> /etc/sysconfig/docker-storage-setup
	echo DATA_SIZE="100%FREE" >> /etc/sysconfig/docker-storage-setup

	systemctl stop docker

	rm -rf /var/lib/docker
	wipefs --all $DISK
	docker-storage-setup
fi

sed -i "s/OPTIONS='\(.*\)'/OPTIONS='\1 --insecure-registry 172.30.0.0\/16'/" /etc/sysconfig/docker

systemctl restart docker
systemctl enable docker

firewall-cmd --add-port=8443/tcp
firewall-cmd --add-port=8443/tcp --permanent
firewall-cmd --add-port=80/tcp
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --add-port=443/tcp
firewall-cmd --add-port=443/tcp --permanent

if [ ! -f /usr/bin/oc ]; then
	curl -o openshift.tar.gz -L https://github.com/openshift/origin/releases/download/v3.9.0/openshift-origin-client-tools-v3.9.0-191fece-linux-64bit.tar.gz
	tar xf openshift.tar.gz 
	rm -f openshift.tar.gz 
	mv openshift-origin-client-tools-*/oc .
	rm -rf openshift-origin-client-tools-*
	mv oc /usr/bin
fi

mkdir -p openshift/config/master/
touch openshift/config/master/users.htpasswd
htpasswd -b openshift/config/master/users.htpasswd ${USERNAME} ${PASSWORD}

ARGS="--host-data-dir=/root/openshift/data --host-config-dir=/root/openshift/config --use-existing-config=true"
ARGS="$ARGS --host-pv-dir=/root/openshift/pvs --host-volumes-dir=/root/openshift/volumes"
ARGS="$ARGS --public-hostname=console.$DOMAIN --routing-suffix=apps.$DOMAIN"
ARGS="$ARGS  --metrics=true --version=v3.9.0"

oc cluster up $ARGS

curl $SCRIPT_REPO/scripts/auth | ruby

oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin ${USERNAME}

docker restart origin

echo "******"
echo "* Your conosle is https://console.$DOMAIN:8443"
echo "* Your username is $USERNAME "
echo "* Your password is $PASSWORD "
echo "*"
echo "* Login using:"
echo "*"
echo "$ oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:8443/"
echo "******"

oc login -u ${USERNAME} -p ${PASSWORD} https://console.$DOMAIN:8443/
