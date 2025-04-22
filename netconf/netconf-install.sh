#!/bin/bash

cp net-conf.sh /usr/local/bin
cp net-conf.service /etc/systemd/system
chmod 744 /usr/local/bin/net-conf.sh
chmod 644 /etc/systemd/system/net-conf.service
systemctl daemon-reload
systemctl enable net-conf.service --now
