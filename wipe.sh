#!/bin/bash

oc cluster down

umount `mount | grep "tmpfs on /root/openshift/" | sed "s/^tmpfs on \(.*\) type .*$/\1/"`

docker rm `docker ps -a | grep Exited | sed "s/^\([a-z0-9]*\).*$/\1/"`

rm -rf /root/openshift
rm -rf /root/.kube

rm -rf /usr/bin/oc