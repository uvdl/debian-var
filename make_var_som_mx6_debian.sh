#!/bin/bash
# It is designed to build Debian linux for Variscite MX6 modules
# prepare host OS system:
#  sudo apt-get install binfmt-support qemu qemu-user-static debootstrap kpartx
#  sudo apt-get install lvm2 dosfstools gpart binutils git lib32ncurses5-dev python-m2crypto
#  sudo apt-get install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat libsdl1.2-dev
#  sudo apt-get install autoconf libtool libglib2.0-dev libarchive-dev
#  sudo apt-get install python-git xterm sed cvs subversion coreutils texi2html
#  sudo apt-get install docbook-utils python-pysqlite2 help2man make gcc g++ desktop-file-utils libgl1-mesa-dev
#  sudo apt-get install libglu1-mesa-dev mercurial automake groff curl lzop asciidoc u-boot-tools mtd-utils
#

# -e  Exit immediately if a command exits with a non-zero status.
set -e

SCRIPT_NAME=${0##*/}
CPUS=`nproc`
readonly SCRIPT_VERSION="0.5.10"


#### Exports Variables ####
#### global variables ####
readonly ABSOLUTE_FILENAME=`readlink -e "$0"`
readonly ABSOLUTE_DIRECTORY=`dirname ${ABSOLUTE_FILENAME}`
readonly SCRIPT_POINT=${ABSOLUTE_DIRECTORY}
readonly SCRIPT_START_DATE=`date +%Y%m%d`
readonly LOOP_MAJOR=7

# default mirror
readonly DEF_DEBIAN_MIRROR="http://httpredir.debian.org/debian"
readonly DEB_RELEASE="stretch"
readonly DEF_ROOTFS_TARBAR_NAME="rootfs.tar.gz"

## base paths
readonly DEF_BUILDENV="${ABSOLUTE_DIRECTORY}"
readonly DEF_SRC_DIR="${DEF_BUILDENV}/src"
readonly G_ROOTFS_DIR="${DEF_BUILDENV}/rootfs"
readonly G_TMP_DIR="${DEF_BUILDENV}/tmp"
readonly G_TOOLS_PATH="${DEF_BUILDENV}/toolchain"
readonly G_VARISCITE_PATH="${DEF_BUILDENV}/variscite"

## LINUX kernel: git, config, paths and etc
readonly G_LINUX_KERNEL_SRC_DIR="${DEF_SRC_DIR}/kernel"
readonly G_LINUX_KERNEL_GIT="https://github.com/uvdl/linux-imx.git"
readonly G_LINUX_KERNEL_BRANCH="feature/develop"
readonly G_LINUX_KERNEL_REV="1e242ad670734608c59eb0ee3974d98c3603f1a1"
readonly G_LINUX_KERNEL_DEF_CONFIG='imx_v7_iris2_defconfig'
readonly G_LINUX_DTB='imx6q-var-dart.dtb imx6q-iris2-R0.dtb imx6q-iris2-R1.dtb imx6q-nightcrawler-R0.dtb'

## uboot
readonly G_UBOOT_SRC_DIR="${DEF_SRC_DIR}/uboot"
readonly G_UBOOT_GIT="https://github.com/uvdl/uboot-imx.git"
readonly G_UBOOT_BRANCH="iris2"
readonly G_UBOOT_REV="7a70a5b5fe517a89391c309d801a0a2e9fd06c5f"
readonly G_UBOOT_DEF_CONFIG_MMC='mx6var_som_sd_config'
readonly G_UBOOT_DEF_CONFIG_NAND='mx6var_som_nand_config'
readonly G_UBOOT_NAME_FOR_EMMC='u-boot.img.mmc'
readonly G_SPL_NAME_FOR_EMMC='SPL.mmc'
readonly G_UBOOT_NAME_FOR_NAND='u-boot.img.nand'
readonly G_SPL_NAME_FOR_NAND='SPL.nand'

## wilink8 ##
readonly G_WILINK8_GIT="git://git.ti.com/wilink8-wlan"
readonly G_WILINK8_UTILS_SRC_DIR="${DEF_SRC_DIR}/wilink8/utils"
readonly G_WILINK8_UTILS_GIT="${G_WILINK8_GIT}/18xx-ti-utils.git"
readonly G_WILINK8_UTILS_GIT_BRANCH="master"
readonly G_WILINK8_UTILS_GIT_SRCREV="5040274cae5e88303e8a895c2707628fa72d58e8"
readonly G_WILINK8_FW_WIFI_SRC_DIR="${DEF_SRC_DIR}/wilink8/fw_wifi"
readonly G_WILINK8_FW_WIFI_GIT="${G_WILINK8_GIT}/wl18xx_fw.git"
readonly G_WILINK8_FW_WIFI_GIT_BRANCH="master"
readonly G_WILINK8_FW_WIFI_GIT_SRCREV="d153edae2a75393937da43159b7e6251c2cd01b6"
readonly G_WILINK8_FW_BT_SRC_DIR="${DEF_SRC_DIR}/wilink8/fw_bt"
readonly G_WILINK8_FW_BT_GIT="git://git.ti.com/ti-bt/service-packs.git"
readonly G_WILINK8_FW_BT_GIT_BRANCH="master"
readonly G_WILINK8_FW_BT_GIT_SRCREV="31a43dc1248a6c19bb886006f8c167e2fd21cb78"

## imx accelerations ##
# much more standard replacement for Freescale's imx-gst1.0-plugin
# Freescale mirror
readonly G_FSL_MIRROR="http://www.freescale.com/lgfiles/NMG/MAD/YOCTO"
# apt-get install gstreamer1.0-x gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-alsa
# sh firmware-imx-7.5.bin --auto-accept
readonly G_IMX_FW_PKG="firmware-imx-7.5"
readonly G_IMX_FW_LOCAL_DIR="${DEF_SRC_DIR}/imx/${G_IMX_FW_PKG}"
readonly G_IMX_FW_LOCAL_PATH="${DEF_SRC_DIR}/imx/${G_IMX_FW_PKG}.bin"
readonly G_IMX_FW_REMOTE_LINK="${G_FSL_MIRROR}/${G_IMX_FW_PKG}.bin"
# sh imx-vpu-5.4.38.bin --auto-accept
readonly G_IMX_VPU_PKG="imx-vpu-5.4.38"
readonly G_IMX_VPU_LOCAL_DIR="${DEF_SRC_DIR}/imx/${G_IMX_VPU_PKG}"
readonly G_IMX_VPU_LOCAL_PATH="${DEF_SRC_DIR}/imx/${G_IMX_VPU_PKG}.bin"
readonly G_IMX_VPU_REMOTE_LINK="${G_FSL_MIRROR}/${G_IMX_VPU_PKG}.bin"
# sh imx-codec-4.3.5.bin --auto-accept
readonly G_IMX_CODEC_PKG="imx-codec-4.3.5"
readonly G_IMX_CODEC_LOCAL_DIR="${DEF_SRC_DIR}/imx/${G_IMX_CODEC_PKG}"
readonly G_IMX_CODEC_LOCAL_PATH="${DEF_SRC_DIR}/imx/${G_IMX_CODEC_PKG}.bin"
readonly G_IMX_CODEC_REMOTE_LINK="${G_FSL_MIRROR}/${G_IMX_CODEC_PKG}.bin"
# sh imx-gpu-g2d-6.2.4.p1.2.bin --auto-accept
readonly G_IMX_GPU_G2D_PKG="imx-gpu-g2d-6.2.4.p1.2"
readonly G_IMX_GPU_G2D_LOCAL_DIR="${DEF_SRC_DIR}/imx/${G_IMX_GPU_G2D_PKG}"
readonly G_IMX_GPU_G2D_LOCAL_PATH="${DEF_SRC_DIR}/imx/${G_IMX_GPU_G2D_PKG}.bin"
readonly G_IMX_GPU_G2D_REMOTE_LINK="${G_FSL_MIRROR}/${G_IMX_GPU_G2D_PKG}.bin"
# sh imx-gpu-viv-6.2.4.p1.2-aarch32.bin --auto-accept
readonly G_IMX_GPU_VIV_PKG="imx-gpu-viv-6.2.4.p1.2-aarch32"
readonly G_IMX_GPU_VIV_LOCAL_DIR="${DEF_SRC_DIR}/imx/${G_IMX_GPU_VIV_PKG}"
readonly G_IMX_GPU_VIV_LOCAL_PATH="${DEF_SRC_DIR}/imx/${G_IMX_GPU_VIV_PKG}.bin"
readonly G_IMX_GPU_VIV_REMOTE_LINK="${G_FSL_MIRROR}/${G_IMX_GPU_VIV_PKG}.bin"
# i.MX X.org Video Driver for i.MX Graphics 2D acceleration
readonly G_IMX_XORG_DRV_SRC_DIR="${DEF_SRC_DIR}/imx/xf86-video-imx-vivante"
readonly G_IMX_XORG_DRV_GIT="https://source.codeaurora.org/external/imx/xf86-video-imx-vivante.git"
readonly G_IMX_XORG_DRV_GIT_BRANCH="imx_exa_viv6_g2d"
readonly G_IMX_XORG_DRV_GIT_SRCREV="946e8603ed9a52f36d305405dbb2ab8ff90943d0"
# replacement for Freescale's closed-development libfslvapwrapper library
readonly G_IMX_VPU_API_SRC_DIR="${DEF_SRC_DIR}/imx/libimxvpuapi"
readonly G_IMX_VPU_API_GIT="git://github.com/Freescale/libimxvpuapi.git"
readonly G_IMX_VPU_API_GIT_BRANCH="master"
readonly G_IMX_VPU_API_GIT_SRCREV="4afb52f97e28c731c903a8538bf99e4a6d155b42"
# much more standard replacement for Freescale's imx-gst1.0-plugin
readonly G_IMX_GSTREAMER_SRC_DIR="${DEF_SRC_DIR}/imx/gstreamer-imx"
readonly G_IMX_GSTREAMER_GIT="git://github.com/Freescale/gstreamer-imx.git"
readonly G_IMX_GSTREAMER_GIT_BRANCH="master"
readonly G_IMX_GSTREAMER_GIT_SRCREV="889b8352ca09cd224be6a2f8d53efd59a38fa9cb"

## CROSS_COMPILER config and paths
readonly G_CROSS_COMPILER_NAME="gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf"
readonly G_CROSS_COMPILER_ARCHIVE="${G_CROSS_COMPILER_NAME}.tar.xz"
readonly G_CROSS_COMPILER_PATH="${G_TOOLS_PATH}/${G_CROSS_COMPILER_NAME}/bin"
readonly G_CROSS_COMPILER_PREFIX="arm-linux-gnueabihf-"
readonly G_CROSS_COMPILER_JOPTION="-j ${CPUS}"
readonly G_EXT_CROSS_COMPILER_LINK="http://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/arm-linux-gnueabihf/${G_CROSS_COMPILER_ARCHIVE}"

############## base rootfs packages ##########
readonly G_BASE_PACKAGES="locales ntpsec gpsd gpsd-clients openssh-server nfs-common dosfstools network-manager net-tools alsa-utils gstreamer1.0-alsa i2c-tools usbutils iperf audacious mtd-utils bluetooth bluez-obexd bluez-tools blueman gconf2 hostapd udhcpd can-utils"
readonly G_BASE_REMOVE="hddtemp"

# sound mixer & volume
# xfce-mixer is not part of Stretch since the stable version depends on
# gstreamer-0.10, no longer used
# Stretch now uses PulseAudio and xfce4-pulseaudio-plugin is included in
# Xfce desktop and can be added to Xfce panels.
## Add xfce4-mixer xfce4-volumed parole
readonly G_XORG_PACKAGES=""	# "xorg xfce4 xfce4-goodies network-manager-gnome"
readonly G_XORG_REMOVE="xserver-xorg-video-ati xserver-xorg-video-radeon"

############## user rootfs packages ##########
readonly G_USER_PACKAGES="bc build-essential device-tree-compiler git gawk htop libxml2-dev libxslt-dev lzop python3 python3-dateutil python3-numpy python3-pip python3-serial rsync screen sqlite3 sudo tcpdump v4l-utils u-boot-tools zlib1g-dev"
readonly G_USER_PYTHONPKGS="future netifaces pexpect piexif pygeodesy pymap3d pynmea2 pytz scapy"
readonly G_USER_PUBKEY="root.pub"
readonly G_USER_POSTINSTALL="postinstall.sh terminal"
readonly G_USER_LOGINS=""			# was "user x_user" before
readonly G_USER_HOSTNAME="iris2"
readonly G_USER_INIT_PATCHES="init-ksz8795 init-ksz9897" # copy patches/x to /etc/init.d/x
readonly G_USER_DISABLE_SERVICES="ModemManager lightdm hostapd variscite-bluetooth NetworkManager-wait-online"

#### Input params #####
PARAM_DEB_LOCAL_MIRROR="${DEF_DEBIAN_MIRROR}"
PARAM_OUTPUT_DIR="${DEF_BUILDENV}/output"
PARAM_DEBUG="0"
PARAM_CMD="all"
PARAM_BLOCK_DEVICE="na"

### usage ###
function usage() {
	echo "This program version ${SCRIPT_VERSION}"
	echo " Used for make debian(${DEB_RELEASE}) image for \"${G_USER_HOSTNAME}\" board"
	echo " and create bootable sdcard"
	echo ""
	echo "Usage:"
	echo " ./${SCRIPT_NAME} options"
	echo ""
	echo "Options:"
	echo "  -h|--help   -- print this help"
	echo "  -c|--cmd <command>"
	echo "     Supported commands:"
	echo "       deploy      -- prepare environment for all commands"
	echo "       all         -- build or rebuild kernel/bootloader/rootfs"
	echo "       bootloader  -- build or rebuild bootloader (u-boot+SPL)"
	echo "       kernel      -- build or rebuild linux kernel for this board"
	echo "       modules     -- build or rebuild linux kernel modules and install in rootfs directory for this board"
	echo "       rootfs      -- build or rebuild debian rootfs filesystem (includes: make debian apks, make and install kernel moduled,"
	echo "                       make and install extern modules (wifi/bt), create rootfs.tar.gz)"
	echo "       rtar        -- generate or regenerate rootfs.tar.gz image from rootfs folder "
	echo "       clean       -- clean all build artifacts (not delete sources code and resulted images (output folder))"
	echo "       sdcard      -- create bootable sdcard for this device"
	echo "  -o|--output -- custom select output directory (default: \"${PARAM_OUTPUT_DIR}\")"
	echo "  -d|--dev    -- select sdcard device (exmple: -d /dev/sde)"
	echo "  --debug     -- enable debug mode for this script"
	echo "Examples of use:"
	echo "  make only linux kernel for board: sudo ./${SCRIPT_NAME} --cmd kernel"
	echo "  make only rootfs for board:       sudo ./${SCRIPT_NAME} --cmd rootfs"
	echo "  create bootable sdcard:           sudo ./${SCRIPT_NAME} --cmd sdcard --dev /dev/sdX"
	echo "  deploy and build:                 ./${SCRIPT_NAME} --cmd deploy && sudo ./${SCRIPT_NAME} --cmd all"
	echo ""
}

###### parse input arguments ##
readonly SHORTOPTS="c:o:d:h"
readonly LONGOPTS="cmd:,output:,dev:,help,debug"

ARGS=$(getopt -s bash --options ${SHORTOPTS}  \
  --longoptions ${LONGOPTS} --name ${SCRIPT_NAME} -- "$@" )

eval set -- "$ARGS"

while true; do
	case $1 in
		-c|--cmd ) # script command
			shift
			PARAM_CMD="$1";
			;;
		-o|--output ) # select output dir
			shift
			PARAM_OUTPUT_DIR="$1";
			;;
		-d|--dev ) # block device (for create sdcard)
			shift
			[ -e ${1} ] && {
				PARAM_BLOCK_DEVICE=${1};
			};
			;;
		--debug ) # enable debug
			PARAM_DEBUG=1;
			;;
		-h|--help ) # get help
			usage
			exit 0;
			;;
		-- )
			shift
			break
			;;
		* )
			shift
			break
			;;
	esac
	shift
done

## enable tarce options in debug mode
[ "${PARAM_DEBUG}" = "1" ] && {
	echo "Debug mode enabled!"
	set -x
};

## declarate dinamic variables ##
readonly G_ROOTFS_TARBAR_PATH="${PARAM_OUTPUT_DIR}/${DEF_ROOTFS_TARBAR_NAME}"

###### local functions ######

### printing functions ###

# print error message
# $1 - printing string
function pr_error() {
	echo "E: $1"
}

# print warning message
# $1 - printing string
function pr_warning() {
	echo "W: $1"
}

# print info message
# $1 - printing string
function pr_info() {
	echo "I: $1"
}

# print debug message
# $1 - printing string
function pr_debug() {
	echo "D: $1"
}

### work functions ###

# get sources from git repository
# $1 - git repository
# $2 - branch name
# $3 - output dir
# $4 - commit id
function get_git_src() {
	# clone src code
	git clone ${1} -b ${2} ${3}
	cd ${3}
	git reset --hard ${4}
	RET=$?
	cd -
	return $RET
}

# get remote file
# $1 - remote file
# $2 - local file
function get_remote_file() {
	local repeated_cnt=5;
	local RET_CODE=1;
	for (( c=0; c<${repeated_cnt}; c++ ))
	do
		rm ${2}
		wget -c ${1} -O ${2} && {
			RET_CODE=0;
			break;
		};

		echo ""
		echo "###########################"
		echo "## Retry download fail  ###"
		echo "###########################"
		echo ""

		sleep 2;
	done

	return ${RET_CODE}
}

function make_prepare() {
## create src dirs
	mkdir -p ${DEF_SRC_DIR}/imx && :;
	mkdir -p ${DEF_SRC_DIR}/wilink8 && :;
	mkdir -p ${G_TOOLS_PATH} && :;

## create rootfs dir
	mkdir -p ${G_ROOTFS_DIR} && :;

## create out dir
	mkdir -p ${PARAM_OUTPUT_DIR} && :;

## create tmp dir
	mkdir -p ${G_TMP_DIR} && :;
}

# unpack fsl package
# $1 - package
function unpack_imx_package() {
	cd ${DEF_SRC_DIR}/imx
	/bin/sh ${1} --auto-accept
	cd -
	return $?
}

# function generate rootfs in input dir
# $1 - rootfs base dir
function make_debian_rootfs() {
	local ROOTFS_BASE=$1

	pr_info "Make debian(${DEB_RELEASE}) rootfs start..."

## umount previus mounts (if fail)
	umount ${ROOTFS_BASE}/{sys,proc,dev/pts,dev} 2>/dev/null && :;

## clear rootfs dir
###	rm -rf ${ROOTFS_BASE}/* && :;

	pr_info "rootfs: debootstrap"
	debootstrap --verbose --foreign --arch armhf ${DEB_RELEASE} ${ROOTFS_BASE}/ ${PARAM_DEB_LOCAL_MIRROR}

## prepare qemu
	pr_info "rootfs: debootstrap in rootfs (second-stage)"
	cp /usr/bin/qemu-arm-static ${ROOTFS_BASE}/usr/bin/
	mount -o bind /proc ${ROOTFS_BASE}/proc
	mount -o bind /dev ${ROOTFS_BASE}/dev
	mount -o bind /dev/pts ${ROOTFS_BASE}/dev/pts
	mount -o bind /sys ${ROOTFS_BASE}/sys
	LANG=C chroot $ROOTFS_BASE /debootstrap/debootstrap --second-stage

	# delete unused folder
	LANG=C chroot $ROOTFS_BASE rm -rf  ${ROOTFS_BASE}/debootstrap

	pr_info "rootfs: generate default configs"
	mkdir -p ${ROOTFS_BASE}/etc/sudoers.d/
	echo "user ALL=(root) /usr/bin/apt-get, /usr/bin/dpkg, /usr/bin/vi, /sbin/reboot" > ${ROOTFS_BASE}/etc/sudoers.d/user
	chmod 0440 ${ROOTFS_BASE}/etc/sudoers.d/user

## added mirror to source list
echo "deb ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE} main contrib non-free
deb-src ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE} main contrib non-free
deb ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE}-backports main contrib non-free
deb-src ${DEF_DEBIAN_MIRROR} ${DEB_RELEASE}-backports main contrib non-free
" > etc/apt/sources.list

## raise backports priority
echo "Package: *
Pin: release n=${DEB_RELEASE}-backports
Pin-Priority: 500
" > etc/apt/preferences.d/backports

echo "
# /dev/mmcblk0p1  /boot           vfat    defaults        0       0
" > etc/fstab

echo "${G_USER_HOSTNAME}" > etc/hostname

echo "auto lo
iface lo inet loopback
" > etc/network/interfaces

echo "
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
locales locales/default_environment_locale select en_US.UTF-8
console-common	console-data/keymap/policy	select	Select keymap from full list
keyboard-configuration keyboard-configuration/variant select 'English (US)'
openssh-server openssh-server/permit-root-login select true
" > debconf.set

	pr_info "rootfs: prepare install packages in rootfs"
## apt-get install without starting
cat > ${ROOTFS_BASE}/usr/sbin/policy-rc.d << EOF
#!/bin/sh
exit 101
EOF

chmod +x ${ROOTFS_BASE}/usr/sbin/policy-rc.d

## third packages stage
cat > third-stage << EOF
#!/bin/bash
# apply debconfig options
debconf-set-selections /debconf.set
rm -f /debconf.set

function protected_install() {
    local _name=\${*}
    local repeated_cnt=5;
    local RET_CODE=1;

    for (( c=0; c<\${repeated_cnt}; c++ ))
    do
        apt-get install -y \${_name} && {
            RET_CODE=0;
            break;
        };

        echo ""
        echo "###########################"
        echo "## Fix missing packages ###"
        echo "###########################"
        echo ""

        sleep 2;
    done

    return \${RET_CODE}
}


# update packages and install base
apt-get update || apt-get update

protected_install locales
protected_install ntp
# FIXME: a modal window comes up regarding a local modification to sshd_config
# but there is no difference.  Try to suppress the dialog by deleting the file...
	pr_info "rootfs: DEBUG: delete sshd_config"
rm -f ${ROOTFS_BASE}/etc/ssh/sshd_config ${ROOTFS_BASE}/usr/share/openssh/sshd_config
protected_install openssh-server
protected_install nfs-common

# packages required when flashing emmc
protected_install dosfstools

## fix config for sshd (permit root login)
## FIXME: we are dealing with sshd separately below
#sed -i -e 's/#PermitRootLogin.*/PermitRootLogin\tyes/g' /etc/ssh/sshd_config
	pr_info "rootfs: DEBUG: delete sshd_config (again)"
rm -f ${ROOTFS_BASE}/etc/ssh/sshd_config ${ROOTFS_BASE}/usr/share/openssh/sshd_config

# FIXME: same thing about modal window with lightdm.conf
	pr_info "rootfs: DEBUG: delete lightdm.conf"
rm -f ${ROOTFS_BASE}/etc/lightdm/lightdm.conf

# enable graphical desktop
protected_install xorg
	pr_info "rootfs: DEBUG: delete lightdm.conf (again)"
rm -f ${ROOTFS_BASE}/etc/lightdm/lightdm.conf
protected_install xfce4
# FIXME: it keeps giving a modal dialog...  I bet its a double-dependency on xfce4
protected_install xfce4-goodies

# sound mixer & volume
# xfce-mixer is not part of Stretch since the stable versionit depends on
# gstreamer-0.10, no longer used
# Stretch now uses PulseAudio and xfce4-pulseaudio-plugin is included in
# Xfce desktop and can be added to Xfce panels.
#protected_install xfce4-mixer
#protected_install xfce4-volumed

# network manager
protected_install network-manager-gnome

# net-tools (ifconfig, etc.)
protected_install net-tools

## fix lightdm config (added autologin x_user) ##
sed -i -e 's/\#autologin-user=/autologin-user=x_user/g' /etc/lightdm/lightdm.conf
sed -i -e 's/\#autologin-user-timeout=0/autologin-user-timeout=0/g' /etc/lightdm/lightdm.conf

# added alsa & alsa utilites
protected_install alsa-utils
protected_install gstreamer1.0-alsa

# added i2c tools
protected_install i2c-tools

# added usb tools
protected_install usbutils

# added net tools
protected_install iperf

#media
protected_install audacious
# protected_install parole

# mtd
protected_install mtd-utils

# bluetooth
protected_install bluetooth
protected_install bluez-obexd
protected_install bluez-tools
protected_install blueman
protected_install gconf2

# wifi support packages
protected_install hostapd
protected_install udhcpd

# can support
protected_install can-utils

# wierd things happen if these are done all at once...
##protected_install ${G_BASE_PACKAGES} ${G_XORG_PACKAGES}
# wierd things still happened when we tried to install one at a time...
##for p in ${G_BASE_PACKAGES} ${G_XORG_PACKAGES} ; do
##    protected_install ${p}
##done

# delete unused packages ##
# probably this would be ok, but to merge back to a working state, accept this for now:
##apt-get -y remove ${G_XORG_REMOVE} ${G_BASE_REMOVE}
apt-get -y remove xserver-xorg-video-ati
apt-get -y remove xserver-xorg-video-radeon
apt-get -y remove hddtemp

apt-get -y autoremove

# Remove foreign man pages and locales
rm -rf /usr/share/man/??
rm -rf /usr/share/man/??_*
rm -rf /var/cache/man/??
rm -rf /var/cache/man/??_*
(cd /usr/share/locale; ls | grep -v en_[GU] | xargs rm -rf)

# Remove document files
rm -rf /usr/share/doc

# Set root password
echo "root:root" | chpasswd

# self kill
rm -f third-stage
EOF

	pr_info "rootfs: install selected debian packages (third-stage)"
	chmod +x third-stage
	LANG=C chroot ${ROOTFS_BASE} /third-stage

	pr_info "rootfs: secure ssh"
cat > ${ROOTFS_BASE}/etc/ssh/sshd_config << EOF
PermitRootLogin yes
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

	mkdir -p ${ROOTFS_BASE}/root/.ssh
	chmod 0700 ${ROOTFS_BASE}/root/.ssh

# secure config for sshd
[ "${G_USER_PUBKEY}" != "" ] && {
	install -m 0600 ${DEF_BUILDENV}/${G_USER_PUBKEY} ${ROOTFS_BASE}/root/.ssh/authorized_keys
};

# post-install configuration script
[ "${G_USER_POSTINSTALL}" != "" ] && {

	pr_info "rootfs: copy setup script(s)"
	for u in ${G_USER_POSTINSTALL} ;
	do
		install 0700 ${DEF_BUILDENV}/${u} ${ROOTFS_BASE}/root
	done
};

# create additional logins
cat > third-stage-user-logins << EOF
#!/bin/bash

function create_user() {
    useradd -m -G audio -s /bin/bash ${1}
    usermod -a -G video ${1}
    echo "${1}:${1}" | chpasswd
}

# create users and set password
for u in ${G_USER_LOGINS} ;
do
    create_user ${u}
    if [ "${u}" == "x_user" ] ;
    then
        ## fix lightdm config (added autologin x_user) ##
        sed -i -e 's/\#autologin-user=/autologin-user=x_user/g' /etc/lightdm/lightdm.conf
        sed -i -e 's/\#autologin-user-timeout=0/autologin-user-timeout=0/g' /etc/lightdm/lightdm.conf
        passwd -d x_user
    fi
done

# self kill
rm -f third-stage-user-logins
EOF

	pr_info "rootfs: create user logins (third-stage)"
	chmod +x third-stage-user-logins
	LANG=C chroot ${ROOTFS_BASE} /third-stage-user-logins

## fourth-stage ##
### install variscite-bluetooth init script
	install -m 0755 ${G_VARISCITE_PATH}/variscite-bluetooth ${ROOTFS_BASE}/etc/init.d/
	LANG=C chroot ${ROOTFS_BASE} update-rc.d variscite-bluetooth defaults
	LANG=C chroot ${ROOTFS_BASE} update-rc.d variscite-bluetooth enable 2 3 4 5

### install user-added system packages
[ "${G_USER_PACKAGES}" != "" ] && {

	pr_info "rootfs: install user defined packages (user-stage)"
	pr_info "rootfs: G_USER_PACKAGES \"${G_USER_PACKAGES}\" "

cat > user-stage << EOF
#!/bin/bash
# update packages
apt-get update

# install all user packages
apt-get -y install ${G_USER_PACKAGES}

rm -f user-stage
EOF

	chmod +x user-stage
	LANG=C chroot ${ROOTFS_BASE} /user-stage

};

### install user-added init scripts
[ "${G_USER_INIT_PATCHES}" != "" ] && {

	pr_info "rootfs: install user init patches (user-stage)"
	pr_info "rootfs: G_USER_INIT_PATCHES \"${G_USER_INIT_PATCHES}\" "

	for u in ${G_USER_INIT_PATCHES} ;
	do
	    install -m 0755 ${DEF_BUILDENV}/patches/${u} ${ROOTFS_BASE}/etc/init.d/
	    LANG=C chroot ${ROOTFS_BASE} update-rc.d ${u} defaults
	    LANG=C chroot ${ROOTFS_BASE} update-rc.d ${u} enable 2 3 4 5
	done
};

### install user-added python packages
[ "${G_USER_PYTHONPKGS}" != "" ] && {

	pr_info "rootfs: install user python packages (user-stage)"
	pr_info "rootfs: G_USER_PYTHONPKGS \"${G_USER_PYTHONPKGS}\" "

cat > user-python-stage << EOF
#!/bin/bash
# update packages
apt-get update

# install all user packages
apt-get -y install python3-pip
pip3 install ${G_USER_PYTHONPKGS}

rm -f user-python-stage
EOF

	chmod +x user-python-stage
	LANG=C chroot ${ROOTFS_BASE} /user-python-stage

};

## binaries rootfs patching ##
	install -m 0644 ${G_VARISCITE_PATH}/issue ${ROOTFS_BASE}/etc/
	install -m 0644 ${G_VARISCITE_PATH}/issue.net ${ROOTFS_BASE}/etc/
	install -m 0644 ${G_VARISCITE_PATH}/hostapd.conf ${ROOTFS_BASE}/etc/
	install -m 0755 ${G_VARISCITE_PATH}/rc.local ${ROOTFS_BASE}/etc/
	install -m 0644 ${G_VARISCITE_PATH}/splash.bmp ${ROOTFS_BASE}/boot/

	install -m 0644 ${G_VARISCITE_PATH}/wallpaper.png \
		${ROOTFS_BASE}/usr/share/images/desktop-base/default

## added alsa default configs ##
	install -m 0644 ${G_VARISCITE_PATH}/asound.state ${ROOTFS_BASE}/var/lib/alsa/
	install -m 0644 ${G_VARISCITE_PATH}/asound.conf ${ROOTFS_BASE}/etc/

## Revert regular booting
	rm -f ${ROOTFS_BASE}/usr/sbin/policy-rc.d

## install kernel modules in rootfs
	install_kernel_modules ${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_LINUX_KERNEL_DEF_CONFIG} ${G_LINUX_KERNEL_SRC_DIR} ${ROOTFS_BASE} || {
		pr_error "Failed #$? in function install_kernel_modules"
		return 2;
	}

## copy custom files
	cp ${G_VARISCITE_PATH}/kobs-ng ${ROOTFS_BASE}/usr/bin
	cp ${G_VARISCITE_PATH}/fw_env.config ${ROOTFS_BASE}/etc
	cp ${PARAM_OUTPUT_DIR}/fw_printenv ${ROOTFS_BASE}/usr/bin
	ln -sf fw_printenv ${ROOTFS_BASE}/usr/bin/fw_setenv
	cp ${G_VARISCITE_PATH}/10-imx.rules ${ROOTFS_BASE}/etc/udev/rules.d

	cp ${G_VARISCITE_PATH}/chroot_script* ${ROOTFS_BASE}

## install wl18xx stuff
	install_wl18xx_packages ${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX}

## copy imx sources to rootfs for native compilation
	install_imx_packages

	LANG=C LC_ALL=C chroot ${ROOTFS_BASE} /chroot_script_base.sh
	sleep 1; sync

## install xorg libs
	LANG=C LC_ALL=C chroot ${ROOTFS_BASE} /chroot_script_patched-xorg-server.sh
	sleep 1; sync

## install iMX GPU libs
	LANG=C LC_ALL=C chroot ${ROOTFS_BASE} /chroot_script_imx-gpu.sh
	sleep 1; sync

### install vivante init scripts
	cp ${G_VARISCITE_PATH}/xorg.conf ${ROOTFS_BASE}/usr/share/X11/xorg.conf.d/90-vivante.conf
	install -m 0755 ${G_VARISCITE_PATH}/vivante ${ROOTFS_BASE}/etc/init.d/
	LANG=C chroot ${ROOTFS_BASE} update-rc.d vivante defaults
	install -m 0755 ${G_VARISCITE_PATH}/rc.autohdmi ${ROOTFS_BASE}/etc/init.d
	LANG=C chroot ${ROOTFS_BASE} update-rc.d rc.autohdmi defaults

## install iMX VPU libs
	LANG=C LC_ALL=C chroot ${ROOTFS_BASE} /chroot_script_gst.sh

### disable services that the user does not want running
[ "${G_USER_DISABLE_SERVICES}" != "" ] && {

	pr_info "rootfs: disable services the user does not want (user-stage)"
	pr_info "rootfs: G_USER_DISABLE_SERVICES \"${G_USER_DISABLE_SERVICES}\" "

	for u in ${G_USER_DISABLE_SERVICES} ;
	do
	    LANG=C chroot ${ROOTFS_BASE} systemctl disable ${u}
	done
};

## cleanup command
echo "#!/bin/bash
apt-get clean
rm -f cleanup
" > cleanup

	# clean all packages
	pr_info "rootfs: clean"
	chmod +x cleanup
	LANG=C chroot ${ROOTFS_BASE} /cleanup
	umount ${ROOTFS_BASE}/{sys,proc,dev/pts,dev}

## kill latest dbus-daemon instance due to qemu-arm-static
	QEMU_PROC_ID=$(ps axf | grep dbus-daemon | grep qemu-arm-static | awk '{print $1}')
	if [ -n "$QEMU_PROC_ID" ]
	then
		kill -9 $QEMU_PROC_ID
	fi

	rm ${ROOTFS_BASE}/usr/bin/qemu-arm-static
	rm ${ROOTFS_BASE}/chroot_script*
	rm -rf ${ROOTFS_BASE}/usr/local/src/*

	return 0;
}

# make tarbar arx from footfs
# $1 -- packet folder
# $2 -- output arx full name
function make_tarbar() {
	cd $1

	pr_info "make tarbar arx from folder ${1}"
	pr_info "Remove old arx $2"
	rm $2 > /dev/null 2>&1 && :;

	pr_info "Create $2"

	tar czf $2 .
	success=$?
	[ $success -eq 0 ] || {
	# fail
	    rm $2 > /dev/null 2>&1 && :;
	};

	cd -
}

# make linux kernel defconfig
# $1 -- cross compiler prefix
# $2 -- linux defconfig file
# $3 -- linux dirname
# $4 -- out path
function make_kernel_defconfig() {
        pr_info "make kernel .config"
        make ARCH=arm CROSS_COMPILE=${1} ${G_CROSS_COMPILER_JOPTION} -C ${3}/ ${2}

        return 0;
}


# make linux kernel modules
# $1 -- cross compiler prefix
# $2 -- linux defconfig file
# $3 -- linux dtb files
# $4 -- linux dirname
# $5 -- out path
function make_kernel() {
	pr_info "make kernel"
	make CROSS_COMPILE=${1} ARCH=arm ${G_CROSS_COMPILER_JOPTION} LOADADDR=0x10008000 -C ${4}/ uImage

	pr_info "make ${3}"
	make CROSS_COMPILE=${1} ARCH=arm ${G_CROSS_COMPILER_JOPTION} -C ${4} ${3}

	pr_info "Copy kernel and dtb files to output dir: ${5}"
	cp ${4}/arch/arm/boot/uImage ${5}/;
	cp ${4}/arch/arm/boot/dts/*.dtb ${5}/;

	return 0;
}

# make linux menuconfig
# $1 -- cross compiler prefix
# $2 -- linux defconfig file
# $3 -- linux dirname
# $4 -- out path
function make_kernel_menuconfig() {
        pr_info "make menuconfig"
        make CROSS_COMPILE=${1} ARCH=arm ${G_CROSS_COMPILER_JOPTION} -C ${3} menuconfig

        return 0;
}

# clean kernel
# $1 -- linux dir path
function clean_kernel() {
	pr_info "Clean linux kernel"

	make ARCH=arm -C ${1}/ mrproper

	return 0;
}

# make linux kernel modules
# $1 -- cross compiler prefix
# $2 -- linux defconfig file
# $3 -- linux dirname
# $4 -- out modules path
function make_kernel_modules() {
	#pr_info "make kernel defconfig"
	#make ARCH=arm CROSS_COMPILE=${1} ${G_CROSS_COMPILER_JOPTION} -C ${3} ${2}

	pr_info "Compiling kernel modules"
	make ARCH=arm CROSS_COMPILE=${1} ${G_CROSS_COMPILER_JOPTION} -C ${3} modules
}

# install linux kernel modules
# $1 -- cross compiler prefix
# $2 -- linux defconfig file
# $3 -- linux dirname
# $4 -- out modules path
function install_kernel_modules() {
	pr_info "Installing kernel headers to ${4}"
	make ARCH=arm CROSS_COMPILE=${1} ${G_CROSS_COMPILER_JOPTION} -C ${3} INSTALL_HDR_PATH=${4}/usr/local headers_install

	pr_info "Installing kernel modules to ${4}"
	make ARCH=arm CROSS_COMPILE=${1} ${G_CROSS_COMPILER_JOPTION} -C ${3} INSTALL_MOD_PATH=${4} modules_install

	return 0;
}

function install_wl18xx_packages() {
	local WL18XX_FW_DIR=${G_ROOTFS_DIR}/lib/firmware/ti-connectivity
	local WLCONF_DIR=${G_ROOTFS_DIR}/usr/sbin/wlconf

	mkdir -p ${WL18XX_FW_DIR}
	mkdir -p ${WLCONF_DIR}

	pr_info "Compiling wl18xx wlconf"
	make CC=${1}gcc ${G_CROSS_COMPILER_JOPTION} -C ${G_WILINK8_UTILS_SRC_DIR}/wlconf

	pr_info "Installing wl18xx bt firmware"
	cp ${G_WILINK8_FW_BT_SRC_DIR}/initscripts/TIInit_*.bts ${WL18XX_FW_DIR}
	
	pr_info "Installing wl18xx wifi firmware"
	cp ${G_WILINK8_FW_WIFI_SRC_DIR}/*.bin ${WL18XX_FW_DIR}
	cp ${G_VARISCITE_PATH}/wl1271-nvs.bin ${WL18XX_FW_DIR}

	pr_info "Installing wl18xx wlconf"
	cp ${G_WILINK8_UTILS_SRC_DIR}/wlconf/configure-device.sh ${WLCONF_DIR}
	cp ${G_WILINK8_UTILS_SRC_DIR}/wlconf/default.conf ${WLCONF_DIR}
	cp ${G_WILINK8_UTILS_SRC_DIR}/wlconf/dictionary.txt ${WLCONF_DIR}
	cp ${G_WILINK8_UTILS_SRC_DIR}/wlconf/example.* ${WLCONF_DIR}
	cp -r ${G_WILINK8_UTILS_SRC_DIR}/wlconf/official_inis ${WLCONF_DIR}
	cp ${G_WILINK8_UTILS_SRC_DIR}/wlconf/README ${WLCONF_DIR}
	cp ${G_WILINK8_UTILS_SRC_DIR}/wlconf/*.bin ${WLCONF_DIR}
	cp ${G_WILINK8_UTILS_SRC_DIR}/wlconf/wlconf ${WLCONF_DIR}
	cp ${G_WILINK8_UTILS_SRC_DIR}/wlconf/wl18xx-conf-default.bin ${WL18XX_FW_DIR}/wl18xx-conf.bin

	return 0;
}

function install_imx_packages() {
	local VPU_FW_DIR=${G_ROOTFS_DIR}/lib/firmware/vpu
	local IMX_DIR=${G_ROOTFS_DIR}/usr/local/src/imx
	local DEB_DIR=${G_ROOTFS_DIR}/usr/local/src/deb

	mkdir -p ${VPU_FW_DIR}
	mkdir -p ${IMX_DIR}
	mkdir -p ${DEB_DIR}

	pr_info "Installing vpu firmware"
	cp ${G_IMX_FW_LOCAL_DIR}/firmware/vpu/vpu_fw_imx6*.bin ${VPU_FW_DIR}

	cp -dr ${G_IMX_VPU_LOCAL_DIR} ${IMX_DIR}
	cp -dr ${G_IMX_CODEC_LOCAL_DIR} ${IMX_DIR}
	cp -dr ${G_IMX_GPU_G2D_LOCAL_DIR} ${IMX_DIR}
	cp -dr ${G_IMX_GPU_VIV_LOCAL_DIR} ${IMX_DIR}
	cp -dr ${G_IMX_XORG_DRV_SRC_DIR} ${IMX_DIR}
	cp -dr ${G_IMX_VPU_API_SRC_DIR} ${IMX_DIR}
	cp -dr ${G_IMX_GSTREAMER_SRC_DIR} ${IMX_DIR}

	cp -dr ${G_VARISCITE_PATH}/deb/* ${DEB_DIR}

	return 0;
}

# make uboot
# $1 uboot path
# $2 outputdir
function make_uboot() {
### make emmc uboot ###
	pr_info "Make SPL & u-boot: ${G_UBOOT_DEF_CONFIG_MMC}"
	# clean work directory
	make ARCH=arm -C ${1} CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_CROSS_COMPILER_JOPTION} mrproper

	# make uboot config for mmc
	make ARCH=arm -C ${1} CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_CROSS_COMPILER_JOPTION} ${G_UBOOT_DEF_CONFIG_MMC}

	# make uboot
	make ARCH=arm -C ${1} CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_CROSS_COMPILER_JOPTION}

	# copy images
	cp ${1}/SPL ${2}/${G_SPL_NAME_FOR_EMMC}
	cp ${1}/u-boot.img ${2}/${G_UBOOT_NAME_FOR_EMMC}

### make nand uboot ###
	pr_info "Make SPL & u-boot: ${G_UBOOT_DEF_CONFIG_NAND}"
	# clean work directory
	make ARCH=arm -C ${1} CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_CROSS_COMPILER_JOPTION} mrproper

	# make uboot config for nand
	make ARCH=arm -C ${1} CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_CROSS_COMPILER_JOPTION} ${G_UBOOT_DEF_CONFIG_NAND}

	# make uboot
	make ARCH=arm -C ${1} CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_CROSS_COMPILER_JOPTION}

	# copy images
	cp ${1}/SPL ${2}/${G_SPL_NAME_FOR_NAND} && \
	cp ${1}/u-boot.img ${2}/${G_UBOOT_NAME_FOR_NAND} || { return 1; }

	# make fw_printenv
	make env ARCH=arm -C ${1} CROSS_COMPILE=${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_CROSS_COMPILER_JOPTION}
	cp ${1}/tools/env/fw_printenv ${2} || { return 1; }

	return 0;
}

# clean uboot
# $1 -- u-boot dir path
function clean_uboot() {
	pr_info "Clean uboot"

	make ARCH=arm -C ${1}/ mrproper

	return 0;
}

# make sdcard for device
# $1 -- block device
function check_sdcard()
{
	# Check that parameter is a valid block device
	if [ ! -b "$1" ]; then
		pr_error "$1 is not a valid block device, exiting"
		return 1
	fi

	local dev=$(basename $1)

	# Check that /sys/block/$dev exists
	if [ ! -d /sys/block/$dev ]; then
		pr_error "Directory /sys/block/${dev} missing, exiting"
		return 1
	fi

	# Get device parameters
	local removable=$(cat /sys/block/${dev}/removable)
	local block_size=$(cat /sys/class/block/${dev}/queue/physical_block_size)
	local size_bytes=$((${block_size}*$(cat /sys/class/block/${dev}/size)))
	local size_gib=$(bc <<< "scale=1; ${size_bytes}/(1024*1024*1024)")

	# non removable SD card readers require additional check
	if [ "${removable}" != "1" ]; then
		local drive=$(udisksctl info -b /dev/${dev}|grep "Drive:"|cut -d"'" -f 2)
		local mediaremovable=$(gdbus call --system --dest org.freedesktop.UDisks2 --object-path ${drive} --method org.freedesktop.DBus.Properties.Get org.freedesktop.UDisks2.Drive MediaRemovable)
		if [[ "${mediaremovable}" = *"true"* ]]; then
			removable=1
		fi
	fi

	# Check that device is either removable or loop
	if [ "$removable" != "1" -a $(stat -c '%t' /dev/$dev) != ${LOOP_MAJOR} ]; then
		pr_error "$1 is not a removable device, exiting"
		return 1
	fi

	# Check that device is attached
	if [ ${size_bytes} -eq 0 ]; then
		pr_error "$1 is not attached, exiting"
		return 1
	fi

	pr_info "Device: ${LPARAM_BLOCK_DEVICE}, ${size_gib}GiB"
	pr_info "================================================"
	read -p "Press Enter to continue"

	return 0
}

# make sdcard for device
# $1 -- block device
# $2 -- output images dir
function make_sdcard() {
	readonly local LPARAM_BLOCK_DEVICE=${1}
	readonly local LPARAM_OUTPUT_DIR=${2}
	readonly local P1_MOUNT_DIR="${G_TMP_DIR}/p1"
	readonly local P2_MOUNT_DIR="${G_TMP_DIR}/p2"
	readonly local DEBIAN_IMAGES_TO_ROOTFS_POINT="opt/images/Debian"

	readonly local BOOTLOAD_RESERVE=4
	readonly local BOOT_ROM_SIZE=8
	readonly local SPARE_SIZE=0

	[ "${LPARAM_BLOCK_DEVICE}" = "na" ] && {
		pr_warning "No valid block device: ${LPARAM_BLOCK_DEVICE}"
		return 1;
	};

	local part=""
	if [ `echo ${LPARAM_BLOCK_DEVICE} | grep -c mmcblk` -ne 0 ]; then
		part="p"
	fi

	# Check that we're using a valid device
	if ! check_sdcard ${LPARAM_BLOCK_DEVICE}; then
		return 1
	fi

	for ((i=0; i<10; i++))
	do
		if [ `mount | grep -c ${LPARAM_BLOCK_DEVICE}${part}$i` -ne 0 ]; then
			umount ${LPARAM_BLOCK_DEVICE}${part}$i
		fi
	done

	function format_sdcard
	{
		pr_info "Formating SDCARD partitions"
		mkfs.vfat ${LPARAM_BLOCK_DEVICE}${part}1 -n BOOT-VARSOM
		mkfs.ext4 ${LPARAM_BLOCK_DEVICE}${part}2 -L rootfs
	}

	function flash_u-boot
	{
		pr_info "Flashing U-Boot"
		dd if=${LPARAM_OUTPUT_DIR}/${G_SPL_NAME_FOR_EMMC} of=${LPARAM_BLOCK_DEVICE} bs=1K seek=1; sync
		dd if=${LPARAM_OUTPUT_DIR}/${G_UBOOT_NAME_FOR_EMMC} of=${LPARAM_BLOCK_DEVICE} bs=1K seek=69; sync
	}

	function flash_sdcard
	{
		pr_info "Flashing \"BOOT-VARSOM\" partition"
		cp ${LPARAM_OUTPUT_DIR}/*.dtb	${P1_MOUNT_DIR}/
		cp ${LPARAM_OUTPUT_DIR}/uImage	${P1_MOUNT_DIR}/uImage
		sync

		pr_info "Flashing \"rootfs\" partition"
		tar -xpf ${LPARAM_OUTPUT_DIR}/${DEF_ROOTFS_TARBAR_NAME} -C ${P2_MOUNT_DIR}/
	}

	function copy_debian_images
	{
		mkdir -p ${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_ROOTFS_POINT}

		pr_info "Copying Debian images to /${DEBIAN_IMAGES_TO_ROOTFS_POINT}"
		cp ${LPARAM_OUTPUT_DIR}/uImage 						${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_ROOTFS_POINT}/
		cp ${LPARAM_OUTPUT_DIR}/${DEF_ROOTFS_TARBAR_NAME}	${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_ROOTFS_POINT}/${DEF_ROOTFS_TARBAR_NAME}

		cp ${LPARAM_OUTPUT_DIR}/*.dtb						${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_ROOTFS_POINT}/

		pr_info "Copying NAND U-Boot to /${DEBIAN_IMAGES_TO_ROOTFS_POINT}"
		cp ${LPARAM_OUTPUT_DIR}/${G_SPL_NAME_FOR_NAND}		${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_ROOTFS_POINT}/
		cp ${LPARAM_OUTPUT_DIR}/${G_UBOOT_NAME_FOR_NAND}	${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_ROOTFS_POINT}/

		pr_info "Copying MMC U-Boot to /${DEBIAN_IMAGES_TO_ROOTFS_POINT}"
		cp ${LPARAM_OUTPUT_DIR}/${G_SPL_NAME_FOR_EMMC}		${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_ROOTFS_POINT}/
		cp ${LPARAM_OUTPUT_DIR}/${G_UBOOT_NAME_FOR_EMMC}	${P2_MOUNT_DIR}/${DEBIAN_IMAGES_TO_ROOTFS_POINT}/

		return 0;
	}

	function copy_scripts
	{
		pr_info "Copying scripts to /${DEBIAN_IMAGES_TO_ROOTFS_POINT}"
		cp ${G_VARISCITE_PATH}/debian-emmc.sh	${P2_MOUNT_DIR}/usr/sbin/
		cp ${G_VARISCITE_PATH}/debian-install.sh ${P2_MOUNT_DIR}/usr/sbin/
	}

	function ceildiv
	{
		local num=$1
		local div=$2
		echo $(( (num + div - 1) / div ))
	}

	# Delete the partitions
	for ((i=0; i<10; i++))
	do
		if [ `ls ${LPARAM_BLOCK_DEVICE}${part}$i 2> /dev/null | grep -c ${LPARAM_BLOCK_DEVICE}${part}$i` -ne 0 ]; then
			dd if=/dev/zero of=${LPARAM_BLOCK_DEVICE}${part}$i bs=512 count=1024
		fi
	done
	sync

	((echo d; echo 1; echo d; echo 2; echo d; echo 3; echo d; echo w) | fdisk ${LPARAM_BLOCK_DEVICE} &> /dev/null) || true
	sync

	dd if=/dev/zero of=${LPARAM_BLOCK_DEVICE} bs=1024 count=4096
	sleep 2; sync;

	pr_info "Creating new partitions"

	# Create a new partition table
fdisk ${LPARAM_BLOCK_DEVICE} <<EOF
n
p
1
8192
24575
t
c
n
p
2
24576

p
w
EOF
	sleep 2; sync;

	# Get total card size
	total_size=`sfdisk -s ${LPARAM_BLOCK_DEVICE}`
	total_size=`expr ${total_size} / 1024`
	boot_rom_sizeb=`expr ${BOOT_ROM_SIZE} + ${BOOTLOAD_RESERVE}`
	rootfs_size=`expr ${total_size} - ${boot_rom_sizeb} - ${SPARE_SIZE}`

	pr_info "ROOT SIZE=${rootfs_size} TOTAl SIZE=${total_size} BOOTROM SIZE=${boot_rom_sizeb}"
	sleep 2; sync;

	# Format the partitions
	format_sdcard
	sleep 2; sync;

	flash_u-boot
	sleep 2; sync;

	# Mount the partitions
	mkdir -p ${P1_MOUNT_DIR}
	mkdir -p ${P2_MOUNT_DIR}
	sync

	mount ${LPARAM_BLOCK_DEVICE}${part}1  ${P1_MOUNT_DIR}
	mount ${LPARAM_BLOCK_DEVICE}${part}2  ${P2_MOUNT_DIR}
	sleep 2; sync;

	flash_sdcard
	copy_debian_images
	copy_scripts

	pr_info "Sync sdcard..."
	sync
	umount ${P1_MOUNT_DIR}
	umount ${P2_MOUNT_DIR}

	rm -rf ${P1_MOUNT_DIR}
	rm -rf ${P2_MOUNT_DIR}

	pr_info "Done make sdcard!"

	return 0;
}

#################### commands ################

function cmd_make_deploy() {
	make_prepare;

	# get linaro toolchain
	(( `ls ${G_CROSS_COMPILER_PATH} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get and unpack cross compiler";
		get_remote_file ${G_EXT_CROSS_COMPILER_LINK} ${DEF_SRC_DIR}/${G_CROSS_COMPILER_ARCHIVE}
		tar -xJf ${DEF_SRC_DIR}/${G_CROSS_COMPILER_ARCHIVE} -C ${G_TOOLS_PATH}/
	};

	# get uboot repository
	(( `ls ${G_UBOOT_SRC_DIR} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get uboot repository";
		get_git_src ${G_UBOOT_GIT} ${G_UBOOT_BRANCH} ${G_UBOOT_SRC_DIR} ${G_UBOOT_REV}
	};

	# get kernel repository
	(( `ls ${G_LINUX_KERNEL_SRC_DIR} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get kernel repository";
		get_git_src ${G_LINUX_KERNEL_GIT} ${G_LINUX_KERNEL_BRANCH} ${G_LINUX_KERNEL_SRC_DIR} ${G_LINUX_KERNEL_REV}
	};

	# get wilink8 utils repository
	(( `ls ${G_WILINK8_UTILS_SRC_DIR} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get wilink8 utils repository";
		get_git_src ${G_WILINK8_UTILS_GIT} ${G_WILINK8_UTILS_GIT_BRANCH} ${G_WILINK8_UTILS_SRC_DIR} ${G_WILINK8_UTILS_GIT_SRCREV}
		cd ${G_WILINK8_UTILS_SRC_DIR}
		patch -p1 < ${DEF_BUILDENV}/patches/wilink8/utils/config_sh.patch
		cd -
	};

	# get wilink8 firmware repository
	(( `ls ${G_WILINK8_FW_WIFI_SRC_DIR} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get wilink8 wifi firmware repository";
		get_git_src ${G_WILINK8_FW_WIFI_GIT} ${G_WILINK8_FW_WIFI_GIT_BRANCH} ${G_WILINK8_FW_WIFI_SRC_DIR} ${G_WILINK8_FW_WIFI_GIT_SRCREV}
	};

	# get bt firmware repository
	(( `ls ${G_WILINK8_FW_BT_SRC_DIR} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get wilink8 bt firmware repository";
		get_git_src ${G_WILINK8_FW_BT_GIT} ${G_WILINK8_FW_BT_GIT_BRANCH} ${G_WILINK8_FW_BT_SRC_DIR} ${G_WILINK8_FW_BT_GIT_SRCREV}
	};

	# get imx firmware
	(( `ls ${G_IMX_FW_LOCAL_PATH} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get and unpack iMX firmware";
		get_remote_file ${G_IMX_FW_REMOTE_LINK} ${G_IMX_FW_LOCAL_PATH}
		unpack_imx_package ${G_IMX_FW_LOCAL_PATH}
	};

	# get imx vpu library
	(( `ls ${G_IMX_VPU_LOCAL_PATH} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get and unpack iMV VPU library";
		get_remote_file ${G_IMX_VPU_REMOTE_LINK} ${G_IMX_VPU_LOCAL_PATH}
		unpack_imx_package ${G_IMX_VPU_LOCAL_PATH}
	};

	# get imx codec libraries
	(( `ls ${G_IMX_CODEC_LOCAL_PATH} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get and unpack iMV CODEC libraries";
		get_remote_file ${G_IMX_CODEC_REMOTE_LINK} ${G_IMX_CODEC_LOCAL_PATH}
		unpack_imx_package ${G_IMX_CODEC_LOCAL_PATH}
	};

	# get imx gpu g2d libraries
	(( `ls ${G_IMX_GPU_G2D_LOCAL_PATH} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get and unpack iMV GPU G2D libraries";
		get_remote_file ${G_IMX_GPU_G2D_REMOTE_LINK} ${G_IMX_GPU_G2D_LOCAL_PATH}
		unpack_imx_package ${G_IMX_GPU_G2D_LOCAL_PATH}
	};

	# get imx gpu viv libraries
	(( `ls ${G_IMX_GPU_VIV_LOCAL_PATH} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get and unpack iMV GPU VIV libraries";
		get_remote_file ${G_IMX_GPU_VIV_REMOTE_LINK} ${G_IMX_GPU_VIV_LOCAL_PATH}
		unpack_imx_package ${G_IMX_GPU_VIV_LOCAL_PATH}
	};

	# get imx xorg libraries
	(( `ls ${G_IMX_XORG_DRV_SRC_DIR} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get XORG driver repository";
		get_git_src ${G_IMX_XORG_DRV_GIT} ${G_IMX_XORG_DRV_GIT_BRANCH} ${G_IMX_XORG_DRV_SRC_DIR} ${G_IMX_XORG_DRV_GIT_SRCREV}
		cd ${G_IMX_XORG_DRV_SRC_DIR}
		patch -p1 < ${DEF_BUILDENV}/patches/imx/xf86-video-imx-vivante/makefile.patch
		cd -
	};

	# get imx vpu api repository
	(( `ls ${G_IMX_VPU_API_SRC_DIR} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get iMX VPU API repository";
		get_git_src ${G_IMX_VPU_API_GIT} ${G_IMX_VPU_API_GIT_BRANCH} ${G_IMX_VPU_API_SRC_DIR} ${G_IMX_VPU_API_GIT_SRCREV}
	};

	# get gstreamer-imx repository
	(( `ls ${G_IMX_GSTREAMER_SRC_DIR} 2>/dev/null | wc -l` == 0 )) && {
		pr_info "Get gstreamer-imx repository";
		get_git_src ${G_IMX_GSTREAMER_GIT} ${G_IMX_GSTREAMER_GIT_BRANCH} ${G_IMX_GSTREAMER_SRC_DIR} ${G_IMX_GSTREAMER_GIT_SRCREV}
	};

	return 0;
}

function cmd_make_rootfs() {
	make_prepare;

	## make debian rootfs
	cd ${G_ROOTFS_DIR}
	make_debian_rootfs ${G_ROOTFS_DIR} || {
		pr_error "Failed #$? in function make_debian_rootfs"
		cd -;
		return 1;
	}
	cd -

	## pack rootfs
	make_tarbar ${G_ROOTFS_DIR} ${G_ROOTFS_TARBAR_PATH} || {
		pr_error "Failed #$? in function make_tarbar"
		return 4;
	}

	return 0;
}

function cmd_make_uboot() {
	make_uboot ${G_UBOOT_SRC_DIR} ${PARAM_OUTPUT_DIR} || {
		pr_error "Failed #$? in function make_uboot"
		return 1;
	};

	return 0;
}

function cmd_make_kernel_defconfig() {
        make_kernel_defconfig ${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_LINUX_KERNEL_DEF_CONFIG} ${G_LINUX_KERNEL_SRC_DIR} ${PARAM_OUTPUT_DIR} || {
                pr_error "Failed #$? in function make_kernel_defconfig"
                return 1;
        };

        return 0;
}

function cmd_make_kernel() {
	make_kernel ${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_LINUX_KERNEL_DEF_CONFIG} "${G_LINUX_DTB}" ${G_LINUX_KERNEL_SRC_DIR} ${PARAM_OUTPUT_DIR} || {
		pr_error "Failed #$? in function make_kernel"
		return 1;
	};

	return 0;
}

function cmd_make_kernel_menuconfig() {
        make_kernel_menuconfig ${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_LINUX_KERNEL_DEF_CONFIG}  ${G_LINUX_KERNEL_SRC_DIR} ${PARAM_OUTPUT_DIR} || {
                pr_error "Failed #$? in function make_kernel_menuconfig"
                return 1;
        };

        return 0;
}


function cmd_make_kmodules() {
	make_prepare;

	rm -rf ${G_ROOTFS_DIR}/lib/modules/* || {
		pr_error "Failed #$? prepare modules dir"
		return 1;
	};

	make_kernel_modules ${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_LINUX_KERNEL_DEF_CONFIG} ${G_LINUX_KERNEL_SRC_DIR} ${G_ROOTFS_DIR} || {
		pr_error "Failed #$? in function make_kernel_modules"
		return 2;
	};

	install_kernel_modules ${G_CROSS_COMPILER_PATH}/${G_CROSS_COMPILER_PREFIX} ${G_LINUX_KERNEL_DEF_CONFIG} ${G_LINUX_KERNEL_SRC_DIR} ${G_ROOTFS_DIR} || {
		pr_error "Failed #$? in function install_kernel_modules"
		return 2;
	};

	return 0;
}

function cmd_make_rfs_tar() {
	## pack rootfs
	make_tarbar ${G_ROOTFS_DIR} ${G_ROOTFS_TARBAR_PATH} || {
		pr_error "Failed #$? in function make_tarbar"
		return 1;
	}

	return 0;
}

function cmd_make_sdcard() {
	make_sdcard ${PARAM_BLOCK_DEVICE} ${PARAM_OUTPUT_DIR} || {
		pr_error "Failed #$? in function make_sdcard"
		return 1;
	};

	return 0;
}

function cmd_make_clean_kernel() {
	## clean kernel, dtb, modules
        clean_kernel ${G_LINUX_KERNEL_SRC_DIR} || {
                pr_error "Failed #$? in function clean_kernel"
                return 1;
        };

}

function cmd_make_clean() {

	## clean kernel, dtb, modules
	clean_kernel ${G_LINUX_KERNEL_SRC_DIR} || {
		pr_error "Failed #$? in function clean_kernel"
		return 1;
	};

	## clean u-boot
	clean_uboot ${G_UBOOT_SRC_DIR} || {
		pr_error "Failed #$? in function clean_uboot"
		return 2;
	};

	## clean rootfs
	pr_info "Delete rootfs ${ROOTFS_BASE}"
	rm -rf ${ROOTFS_BASE}/* && :;

	## delete tmp dirs and etc
	pr_info "Delete tmp dir ${G_TMP_DIR}"
	rm -rf ${G_TMP_DIR} && :;

	pr_info "Delete rootfs dir ${G_ROOTFS_DIR}"
	rm -rf ${G_ROOTFS_DIR} && :;

	return 0;
}

#################### main function #######################

## test for root access support (msrc not allowed)
[ "$PARAM_CMD" != "deploy" ] && [ "$PARAM_CMD" != "bootloader" ] && [ "$PARAM_CMD" != "kernel" ] && [ "$PARAM_CMD" != "modules" ] && [ ${EUID} -ne 0 ] && {
	pr_error "this command must be run as root (or sudo/su)"
	exit 1;
};

V_RET_CODE=1;

pr_info "Command: \"$PARAM_CMD\" start..."

case $PARAM_CMD in
	deploy )
		cmd_make_deploy && {
			V_RET_CODE=0;
		}
		;;
	rootfs )
		cmd_make_rootfs && {
			V_RET_CODE=0;
		}
		;;
	bootloader )
		cmd_make_uboot && {
			V_RET_CODE=0;
		}
		;;
	kernel )
		cmd_make_kernel && {
			V_RET_CODE=0;
		}
		;;
	kernel_defconfig )
                cmd_make_kernel_defconfig && {
                        V_RET_CODE=0;
                }
                ;;
	kernel_menuconfig )
                cmd_make_kernel_menuconfig && {
                        V_RET_CODE=0;
                }
                ;;
	modules )
		cmd_make_kmodules && {
			V_RET_CODE=0;
		}
		;;
	sdcard )
		cmd_make_sdcard && {
			V_RET_CODE=0;
		}
		;;
	rtar )
		cmd_make_rfs_tar && {
			V_RET_CODE=0;
		}
		;;
	all )
		cmd_make_uboot &&
		cmd_make_kernel_defconfig &&
		cmd_make_kernel &&
		cmd_make_kmodules &&
		cmd_make_rootfs && {
			V_RET_CODE=0;
		}
		;;
	clean )
		cmd_make_clean && {
			V_RET_CODE=0;
		}
		;;
	clean_kernel )
		cmd_make_clean_kernel && {
			V_RET_CODE=0;
		}
		;;
	* )
		pr_error "Invalid input command: \"${PARAM_CMD}\"";
		;;
esac

pr_info ""
pr_info "Command: \"$PARAM_CMD\" end. Exit code: ${V_RET_CODE}"
pr_info ""


exit ${V_RET_CODE};
