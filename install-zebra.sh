#!/bin/bash

echo "Ricerca stampante Zebra..."
device=$(lpinfo -v | grep "usb.*Zebra")
if [[ $device == "" ]]; then
	echo "stampante non trovata"
else
	device=${device##*"direct "}
	echo usb printer found: $device
	lpadmin -p etich01 -v $device -m "drv:///sample.drv/zebra.ppd"
	lpoptions -p etich01 -o media=Custom.48x60mm -o printer-is-shared=true
	cupsenable etich01
	cupsaccept etich01

	echo OP | lp -d etich01 -o raw
	echo ZB | lp -d etich01 -o raw
	
	echo "Stampante installata: etich01"
fi
