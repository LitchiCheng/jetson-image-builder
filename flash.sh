#!/bin/bash 

CURRENT_DIR=$(cd $(dirname $0); pwd)
SDK_NAME="${CURRENT_DIR}/Linux_for_Tegra"
script_name="$(basename "${0}")"

function flashBootloader()
{
    pushd "${SDK_NAME}" > /dev/null 2>&1
    if [ -f "$SDK_NAME/customFinished" ]; then
	# -k A_cpu-bootloader
        sudo ODMDATA="gbe-uphy-config-8,hsstp-lane-map-3,hsio-uphy-config-40" ./flash.sh --no-flash -c bootloader/t186ref/cfg/flash_t234_qspi.xml jetson-orin-nano-devkit nvme0n1p1
    else
        echo "No aviable Image, please run customize_rootfs.sh first."
    fi
    popd > /dev/null
}

function flashRootfs()
{
    pushd "${SDK_NAME}" > /dev/null 2>&1
    if [ -f "$SDK_NAME/customFinished" ]; then
        sudo ODMDATA="gbe-uphy-config-8,hsstp-lane-map-3,hsio-uphy-config-40" ADDITIONAL_DTB_OVERLAY_OPT="BootOrderNvme.dtbo" ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_external.xml -p "-c bootloader/t186ref/cfg/flash_t234_qspi.xml --no-systemimg" --network usb0 jetson-orin-nano-devkit nvme0n1p1
    else
        echo "No aviable Image, please run customize_rootfs.sh first."
    fi
    popd > /dev/null
}

function usage()
{
	if [ -n "${1}" ]; then
		echo "${1}"
	fi

	echo "Usage:"
	echo "Example:"
	echo "${script_name} -bootloader"
	echo ""
	echo "${script_name} -rootfs"
	echo ""
	exit 1
}

function main()
{
	if [ -n "${1}" ]; then
		case "${1}" in
		-help)
			usage
			;;
		-bootloader)
			flashBootloader
			;;
		-rootfs)
			flashRootfs
			;;
		*)
			usage "Unknown option: ${1}"
			;;
		esac
    else 
        usage
	fi
}

main "${@}"

