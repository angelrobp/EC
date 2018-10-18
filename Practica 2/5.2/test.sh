#! /bin/bash

for i in $(seq 1 8); do 
	rm suma; 
	gcc -x assembler-with-cpp -D TEST=$i *.s -o suma -no-pie; 
	echo -n "T#$i "; 
	./suma;
done
