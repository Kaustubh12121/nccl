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

echo -e "\nfirst element"
echo $(echo $eth_devices[0] | awk '{print $1}')

echo -e "\n Lists all the traffic class files to update"
for device in $mlx_devices; do
	traffic_class=$(find /sys/devices/ | grep traffic_class | grep $device/ )
	echo $traffic_class
done

