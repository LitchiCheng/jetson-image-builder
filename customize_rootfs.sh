#!/bin/bash
#customize_rootfs.sh

CURRENT_DIR=$(cd $(dirname $0); pwd)
script_name="$(basename "${0}")"
CUSTOM_FILE_DIR="${CURRENT_DIR}/custom_file"
SDK_NAME="${CURRENT_DIR}/Linux_for_Tegra"
RFS_DIR="${SDK_NAME}/rootfs"
CUSTOM_SOURCES_LIST="${CUSTOM_FILE_DIR}/sources.list"
CUSTOM_PACKAGE_LIST="${CUSTOM_FILE_DIR}/custom_package_list"
CUSTOM_NET_CONFIG="${CUSTOM_FILE_DIR}/00-installer-config-static.yaml"
CUSTOM_NAME="LitchiCheng"

function downloadSDK(){
    if [ -d "$SDK_NAME" ]; then
        echo "$SDK_NAME exists"
    else
        wget https://developer.nvidia.com/downloads/embedded/l4t/r35_release_v5.0/release/jetson_linux_r35.5.0_aarch64.tbz2 -O sdktemp
        tar jxvf sdktemp
    fi
    # sudo cp -rf ${CUSTOM_FILE_DIR}/uefi_jetson.bin ${SDK_NAME}/bootloader/
    # sudo cp -rf ${CUSTOM_FILE_DIR}/p3767.conf.common ${SDK_NAME}/
    # sudo cp -rf ${CUSTOM_FILE_DIR}/tegra234-mb2-bct-misc-p3767-0000.dts ${SDK_NAME}/bootloader/t186ref/BCT/
}

function creatBaseRootfs () {
    if [ -f "$SDK_NAME/tools/samplefs/sample_fs.tbz2" ]; then
        echo "$SDK_NAME/tools/samplefs/sample_fs.tbz2 exists"
    else
        sudo cp -rf ${CUSTOM_SOURCES_LIST} ${SDK_NAME}/tools/samplefs/
        sudo cp -rf ${CUSTOM_FILE_DIR}/nvubuntu-focal-aarch64-samplefs ${SDK_NAME}/tools/samplefs/
        sudo cp -rf ${CUSTOM_FILE_DIR}/nvubuntu_samplefs.sh ${SDK_NAME}/tools/samplefs/
        sudo $SDK_NAME/tools/samplefs/nv_build_samplefs.sh --abi aarch64 --distro ubuntu --flavor desktop --version focal
    fi
}

function deployRootfs(){
    if [ -d "$RFS_DIR" ]; then
        sudo rm -rf $RFS_DIR/*
    else
        mkdir -p $RFS_DIR
    fi
    echo "extract rootfs..."
    sudo tar xpf "$SDK_NAME"/tools/samplefs/sample_fs.tbz2 -C $RFS_DIR
    if [ ! -f "$RFS_DIR/etc/apt/sources.list" ]; then
        echo "$RFS_DIR empty, exit!"
        exit 1
    fi
    
    sudo "$SDK_NAME"/apply_binaries.sh
    sudo "$SDK_NAME"/tools/l4t_flash_prerequisites.sh
    sudo "$SDK_NAME"/tools/l4t_create_default_user.sh --accept-license -u litchi -p \' -a -n $CUSTOM_NAME
}

function cleanup() {
	set +e
	pushd "${RFS_DIR}" > /dev/null 2>&1

	for attempt in $(seq 10); do
		mount | grep -q "${RFS_DIR}/sys" && umount ./sys
		mount | grep -q "${RFS_DIR}/proc" && umount ./proc
		mount | grep -q "${RFS_DIR}/dev" && umount ./dev
        mount | grep -q "${RFS_DIR}/dev/pts" && umount ./dev/pts
		mount | grep -q "${RFS_DIR}"
		if [ $? -ne 0 ]; then
			break
		fi
		sleep 1
	done
	popd > /dev/null
}
trap cleanup EXIT

function userCustomize(){
    pushd "${RFS_DIR}" > /dev/null 2>&1
	cp "/usr/bin/qemu-aarch64-static" "usr/bin/"
	chmod 755 "usr/bin/qemu-aarch64-static"
	mount /sys ./sys -o bind
	mount /proc ./proc -o bind
	mount /dev ./dev -o bind
    mount /dev/pts ./dev/pts -o bind

	LC_ALL=C chroot . mv /etc/apt/sources.list /etc/apt/sources.list_bak
    cp -rf "${CUSTOM_SOURCES_LIST}" "${RFS_DIR}"/etc/apt/
    set +e
    LC_ALL=C chroot . dpkg --configure -a
    LC_ALL=C chroot . apt update || true
    set -e
    
    echo "apt install package list"

    package_list=$(cat "${CUSTOM_PACKAGE_LIST}")
    	if [ ! -z "${package_list}" ]; then
        #--no-install-recommends
        sudo LC_ALL=C DEBIAN_FRONTEND=noninteractive chroot . apt -y --fix-broken install
		sudo LC_ALL=C DEBIAN_FRONTEND=noninteractive chroot . apt-get -y install ${package_list}
        set +e
        sudo LC_ALL=C chroot . pip3 install jetson-stats
        set -e
	else
		echo "ERROR: Package list is empty"
	fi

    cp -rf "${CUSTOM_NET_CONFIG}" "${RFS_DIR}"/etc/netplan/

    LC_ALL=C chroot . systemctl disable nv-oem-config.service

    sudo rm -rf "${RFS_DIR}"/etc/localtime 
    LC_ALL=C chroot . ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 

    umount ./sys
	umount ./proc
	umount ./dev/pts
	umount ./dev

    rm -rf var/lib/apt/lists/*
	rm -rf dev/*
	rm -rf var/log/*
	rm -rf var/cache/apt/archives/*.deb
	rm -rf var/tmp/*
	rm -rf tmp/*

    popd > /dev/null

    touch $SDK_NAME/customFinished
}

function usage()
{
	if [ -n "${1}" ]; then
		echo "${1}"
	fi

	echo "Usage:"
	echo "Example:"
	echo "${script_name} -ds"
	echo "download jetson sdk"
    echo ""
	echo "${script_name} -cr"
	echo "create base rootfs"
    echo ""
    echo "${script_name} -dr"
	echo "deploy rootfs"
    echo ""
    echo "${script_name} -uc"
	echo "user customize"
    echo ""
    echo "${script_name} -all"
	echo "do all command"
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
		-ds)
			downloadSDK
			;;
		-cr)
			creatBaseRootfs
			;;
        -dr)
			deployRootfs
			;;
        -uc)
			userCustomize
			;;
        -all)
            downloadSDK
            creatBaseRootfs
            deployRootfs
			userCustomize
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








