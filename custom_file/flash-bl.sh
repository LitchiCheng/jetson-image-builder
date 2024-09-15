#!/bin/bash 

sudo ODMDATA="gbe-uphy-config-8,hsstp-lane-map-3,hsio-uphy-config-40" ./flash.sh -r -c bootloader/t186ref/cfg/flash_t234_qspi.xml jetson-orin-nano-devkit nvme0n1p1