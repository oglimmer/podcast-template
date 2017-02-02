#!/bin/bash

FREE_DISK_SPACE=$(df | grep $(mount|grep " / "|awk '{print $1}')|awk '{print $4}')
if [ "$FREE_DISK_SPACE" -lt "10000000" ]; then
	echo "low disk space"
fi
