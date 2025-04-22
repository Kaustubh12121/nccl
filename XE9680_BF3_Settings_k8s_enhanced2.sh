#!/bin/bash

pci_devices=$(mlxfwmanager --query | grep -A 3 "B3140H" | grep "PCI Device Name" | awk '{print $4}')
eth_devices=""
mlx_devices=""
altnames=""
for device in $pci_devices; do
    eth_device=$(mst status -v | grep -B 1 "$device" | grep "net-" | awk '{print $5}' | sed 's/net-//')
    eth_devices="$eth_devices $eth_device"
    mlx_device=$(rdma link show | grep -w "$eth_device" | awk '{print $2}' | cut -d'/' -f1)
    mlx_devices="$mlx_devices $mlx_device"
    altname=$(ip a show $eth_device | grep 'altname' | awk '{print $2}')
    altnames="$altnames $altname"
done

# Print each device on a new line
echo "List of MLX devices in the server that are B3140H"
for device in $mlx_devices; do
    echo $device
done

echo -e "\nList of Ethernet devices in the server that are B3140H"
for device in $eth_devices; do
    echo $device
done

echo -e "\nList of altnames for Ethernet devices in the server that are B3140H"
for device in $altnames; do
    echo $device
done

echo -e "\nList of PCI devices in the server that are B3140H"
for device in $pci_devices; do
    echo $device
done

mst start
mst status -v
for device in $mlx_devices; do cma_roce_tos -d $device -t 106 ; done
for device in $mlx_devices; do echo 106 > /sys/class/infiniband/$device/tc/1/traffic_class; done
for iface in $eth_devices; do mlnx_qos -i $iface --pfc=0,0,0,1,0,0,0,0 --trust=dscp; done
for device in $mlx_devices; do cma_roce_tos -d $device -t 106 ; done
for device in $mlx_devices; do
	traffic_class=$(find /sys/devices/ | grep traffic_class | grep $device/ )
	echo 106 | tee $traffic_class
done

for device in $pci_devices; do mlxreg -d $device --set "ipg=0x00000019" --reg_name PIPG --indexes "local_port=1,lp_msb=0,ipg_cap_index=0" -y ; done 
for device in $pci_devices; do mlxreg -d $device --reg_id 0x5006 --set "0x0.8:4=2,0x0.16:8=1,0x4.8:1=1,0x4.31:1=1" --reg_len 16 -y ; done
for device in $pci_devices; do mlxreg -d $device --reg_id 0x5006 --set "0x0.8:4=1,0x0.16:8=1,0x4.8:1=1,0x4.31:1=1" --reg_len 16 -y ; done
ip route replace default via 192.168.1.254 table 101
ip route replace default via 192.168.2.254 table 102
ip route replace default via 192.168.3.254 table 103
ip route replace default via 192.168.4.254 table 104
ip route replace default via 192.168.5.254 table 105
ip route replace default via 192.168.6.254 table 106
ip route replace default via 192.168.7.254 table 107
ip route replace default via 192.168.8.254 table 108
firstip=$(echo $eth_devices[0] | awk '{print $1}')
node=$(ip address show $firstip | awk '/inet / {split($2,a,".");print a[4] }' | awk -F"/" '{print $1 }')
echo "We are in node $node. Configuring IP routes"
ip rule delete from 192.168.1.$node lookup 101
ip rule delete from 192.168.2.$node lookup 102
ip rule delete from 192.168.3.$node lookup 103
ip rule delete from 192.168.4.$node lookup 104
ip rule delete from 192.168.5.$node lookup 105
ip rule delete from 192.168.6.$node lookup 106
ip rule delete from 192.168.7.$node lookup 107
ip rule delete from 192.168.8.$node lookup 108
ip rule add from 192.168.1.$node lookup 101
ip rule add from 192.168.2.$node lookup 102
ip rule add from 192.168.3.$node lookup 103
ip rule add from 192.168.4.$node lookup 104
ip rule add from 192.168.5.$node lookup 105
ip rule add from 192.168.6.$node lookup 106
ip rule add from 192.168.7.$node lookup 107
ip rule add from 192.168.8.$node lookup 108

modprobe nvidia-peermem
lsmod | grep peer
