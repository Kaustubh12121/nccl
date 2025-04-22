#!/bin/bash

trafficclass=$(find /sys/devices -name traffic_class | grep infiniband | grep -v "mlx5_1/" | grep -v "mlx5_2/" | grep -v "mlx5_7/" | grep -v "mlx5_8/" )
for i in $trafficclass; do
	echo 106 | tee $trafficclass
	cat $i
done

