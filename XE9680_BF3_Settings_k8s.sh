mst start
mst status -v
for i in {0,2,3,4,5,7,8,9}; do cma_roce_tos -d mlx5_$i -t 96 ; done
for i in {0,2,3,4,5,7,8,9}; do echo 96 > /sys/class/infiniband/mlx5_$i/tc/1/traffic_class; done
for iface in {enp156s0f0np0,enp188s0f0np0,enp204s0f0np0,enp220s0f0np0,enp94s0f0np0,enp77s0f0np0,enp26s0f0np0,enp60s0f0np0} ; do mlnx_qos -i $iface --pfc=0,0,0,1,0,0,0,0 --trust=dscp; done
for i in {0,2,3,4,5,7,8,9}; do mlxreg -d /dev/mst/mt41692_pciconf$i --set "ipg=0x00000019" --reg_name PIPG --indexes "local_port=1,lp_msb=0" -y ; done
for i in {0,2,3,4,5,7,8,9}; do mlxreg -d /dev/mst/mt41692_pciconf$i --reg_id 0x5006 --set "0x0.8:4=2,0x0.16:8=1,0x4.8:1=1,0x4.31:1=1" --reg_len 16 -y ; done
for i in {0,2,3,4,5,7,8,9}; do mlxreg -d /dev/mst/mt41692_pciconf$i --reg_id 0x5006 --set "0x0.8:4=1,0x0.16:8=1,0x4.8:1=1,0x4.31:1=1" --reg_len 16 -y ; done
ip route replace default via 192.168.1.254 table 101
ip route replace default via 192.168.2.254 table 102
ip route replace default via 192.168.3.254 table 103
ip route replace default via 192.168.4.254 table 104
ip route replace default via 192.168.5.254 table 105
ip route replace default via 192.168.6.254 table 106
ip route replace default via 192.168.7.254 table 107
ip route replace default via 192.168.8.254 table 108
node=$(ip address show enp156s0f0np0 | awk '/inet / {split($2,a,".");print a[4] }' | awk -F"/" '{print $1 }')
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
#ip route replace 192.168.1.0/24 via 192.168.1.254 dev enp156s0f0np0 proto static
#ip route replace 192.168.2.0/24 via 192.168.2.254 dev enp188s0f0np0 proto static
#ip route replace 192.168.3.0/24 via 192.168.3.254 dev enp204s0f0np0 proto static
#ip route replace 192.168.4.0/24 via 192.168.4.254 dev enp220s0f0np0 proto static
#ip route replace 192.168.5.0/24 via 192.168.5.254 dev enp94s0f0np0 proto static
#ip route replace 192.168.6.0/24 via 192.168.6.254 dev enp77s0f0np0 proto static
#ip route replace 192.168.7.0/24 via 192.168.7.254 dev enp26s0f0np0 proto static
#ip route replace 192.168.8.0/24 via 192.168.8.254 dev enp60s0f0np0 proto static
