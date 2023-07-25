#!/bin/sh

# make the script stop on error
set -e

DISTRIBUTION=$(lsb_release -i -s)

echo "Running on $DISTRIBUTION"

KERNEL_MODULE_NAME="${1}"
DKMS_MODULE_VERSION="${2}"

if [ -z "${KERNEL_VERSION}" ]; then
	case $DISTRIBUTION in
		"Debian")
			PACKAGE_LISTER="dpkg -l"
			KERNEL_PREFIX="linux-image-"
			;;
		"Fedora")
			PACKAGE_LISTER="rpm -qa"
			KERNEL_PREFIX="kernel-core-"
			;;
		*)
			echo "This script was created for Debian or Fedora based distros"
			exit 1
			;;
	esac
	
	LATEST_LINUX_IMAGE_PACKAGE=$( $PACKAGE_LISTER | grep -oP "$KERNEL_PREFIX\d\S*\b" | sort -r | head -n1 )
	KERNEL_VERSION=${LATEST_LINUX_IMAGE_PACKAGE#$KERNEL_PREFIX}
fi
echo "Building for kernel version ${KERNEL_VERSION}"

# build and install the DKMS module and update initramfs ------------------------------------------

sudo dkms build -k "${KERNEL_VERSION}" -m "${KERNEL_MODULE_NAME}" -v "${DKMS_MODULE_VERSION}" --force
sudo dkms install -k "${KERNEL_VERSION}" -m "${KERNEL_MODULE_NAME}" -v "${DKMS_MODULE_VERSION}" --force

if sudo dmesg | grep -q 'initramfs'; then
	case $DISTRIBUTION in
		"Debian")
			sudo update-initramfs -u -k "${KERNEL_VERSION}"
			;;
		"Fedora")
			sudo dracut --force --regenerate-all
			;;
		*)
			echo "This script was created for Debian or Fedora based distros"
			exit 1
			;;
	esac


fi

printf '\n%s\n    %s\n' "Please reboot your system and check whether ${KERNEL_MODULE_NAME} has been loaded via the command" 'dkms status'
