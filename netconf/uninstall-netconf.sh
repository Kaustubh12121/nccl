#!/bin/bash

systemctl disable waco-net-conf.service --now
systemctl daemon-reload
rm -rf /usr/local/bin/waco-net-conf.sh
rm -rf /usr/local/bin/waco-net-conf.service


