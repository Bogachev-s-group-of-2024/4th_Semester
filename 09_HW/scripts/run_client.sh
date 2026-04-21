#!/bin/bash

# Gold.6138-2
host="10.1.13.2"
dir="$HOME/students/data"

for ((port=20801; port <= 20804; port ++))
do
	(
		echo "Connecting to host=${host} port=${port}"
		./client ${host} ${port} < "${dir}/commands6 order order.txt" > /tmp/res-${port}
		./client ${host} ${port} < "${dir}/init_commands.txt" >> /tmp/res-${port}

		for ((i=0; i<20; i++))
		do
			./client ${host} ${port} < "${dir}/client_commands.txt" > /tmp/res-${port}-${i} &
		done

		wait
		./client ${host} ${port} < "${dir}/finish_commands.txt"
		echo "------------------------------------------------------------"
	) &
done

wait

for ((port=20801; port <= 20804; port ++))
do
	result_init=`grep '^[[:space:]]*Student' /tmp/res-${port} | wc -l`
	result=`grep '^[[:space:]]*Student' /tmp/res-${port}-0 | wc -l`

	for ((i=1; i<20; i++))
	do
		diff -q /tmp/res-${port}-0 /tmp/res-${port}-${i}
	done

	echo "For port=${port} init=${result_init} answer=${result}"
	echo "------------------------------------------------------------"
done
