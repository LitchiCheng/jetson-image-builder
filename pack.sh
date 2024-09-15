#!/bin/bash

CURRENT_DIR=$(cd $(dirname $0); pwd)
SDK_NAME="${CURRENT_DIR}/Linux_for_Tegra"
CUSTOM_FILE_DIR="${CURRENT_DIR}/custom_file"
script_name="$(basename "${0}")"
folder_name="jetson-orin-nano-bl"

if [ -d ${folder_name} ]; then
    rm -rf ${folder_name}
fi

mkdir ${folder_name}
mkdir -p ${folder_name}/tools
mkdir -p ${folder_name}/rootfs
mkdir -p ${folder_name}/initrdlog
mkdir -p ${folder_name}/temp_initrdflash
mkdir -p ${folder_name}/kernel
mkdir -p ${folder_name}/bootloader

cp -rf ${SDK_NAME}/kernel/* ${folder_name}/kernel/
cp -rf ${SDK_NAME}/rootfs/* ${folder_name}/rootfs/
cp -rf ${SDK_NAME}/bootloader/* ${folder_name}/bootloader/

cp -rf ${SDK_NAME}/p3768-0000+p3767-0000.conf ${folder_name}/jetson-orin-nano-devkit.conf
cp -rf ${SDK_NAME}/p3668.conf.common ${folder_name}
cp -rf ${SDK_NAME}/p3767.conf.common ${folder_name}
cp -rf ${SDK_NAME}/p3701.conf.common ${folder_name}
cp -rf ${SDK_NAME}/p2972-0000.conf.common ${folder_name}
cp -rf ${SDK_NAME}/flash.sh ${folder_name}
cp -rf ${CUSTOM_FILE_DIR}/flash-bl.sh ${folder_name}

rsync -av --exclude images/external ${SDK_NAME}/tools/kernel_flash ${folder_name}/tools











