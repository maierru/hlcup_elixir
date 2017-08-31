#!/bin/bash
#echo "ПОЧИНИТЕ МЕНЯ"
cat /tmp/data/options.txt
#netstat -anl
#ifconfig
#cat /etc/hosts
#ls -la /tmp/data/data.zip
#unzip -p /tmp/data/data.zip
# sysctl -a | grep syncook
MIX_ENV=prod /opt/hlcup/bin/hlcup foreground
