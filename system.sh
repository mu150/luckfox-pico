#!/bin/bash

ROOTFS_NAME="rootfs-alpine.tar.gz"
DEVICE_NAME="pico-mini-b"

while getopts ":f:d:" opt; do
  case ${opt} in
    f) ROOTFS_NAME="${OPTARG}" ;;
    d) DEVICE_NAME="${OPTARG}" ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done


rm -rf sdk/sysdrv/custom_rootfs/
mkdir -p sdk/sysdrv/custom_rootfs/
cp "$ROOTFS_NAME" sdk/sysdrv/custom_rootfs/

pushd sdk || exit

pushd tools/linux/toolchain/arm-rockchip830-linux-uclibcgnueabihf/ || exit
source env_install_toolchain.sh
popd || exit

rm -rf .BoardConfig.mk
case $DEVICE_NAME in
  #WARNING: Most of these are untested
  #pico)                  ln -s project/cfg/BoardConfig_IPC/BoardConfig-SD_CARD-Buildroot-RV1103_Luckfox_Pico-IPC.mk                 .BoardConfig.mk ;;
  #pico-86-panel)         ln -s project/cfg/BoardConfig_IPC/BoardConfig-EMMC-Buildroot-RV1106_Luckfox_Pico_86Panel-IPC.mk            .BoardConfig.mk ;;
  pico-mini-a)           ln -s project/cfg/BoardConfig_IPC/BoardConfig-SD_CARD-Buildroot-RV1103_Luckfox_Pico_Mini_A-IPC.mk           .BoardConfig.mk ;;
  pico-mini-b-sd)        ln -s project/cfg/BoardConfig_IPC/BoardConfig-SD_CARD-Buildroot-RV1103_Luckfox_Pico_Mini_B-IPC.mk           .BoardConfig.mk ;;
  pico-mini-b-flash)     ln -s project/cfg/BoardConfig_IPC/BoardConfig-SPI_NAND-Buildroot-RV1103_Luckfox_Pico_Mini_B-IPC.mk          .BoardConfig.mk ;;
  pico-max-sd)           ln -s project/cfg/BoardConfig_IPC/BoardConfig-SD_CARD-Buildroot-RV1106_Luckfox_Pico_Max-IPC.mk             .BoardConfig.mk ;;
  pico-max-flash)        ln -s project/cfg/BoardConfig_IPC/BoardConfig-SPI_NAND-Buildroot-RV1106_Luckfox_Pico_Max-IPC.mk            .BoardConfig.mk ;;
  pico-pi)               ln -s project/cfg/BoardConfig_IPC/BoardConfig-EMMC-Buildroot-RV1106_Luckfox_Pico_Pi-IPC.mk                 .BoardConfig.mk ;;
  pico-pi-w)             ln -s project/cfg/BoardConfig_IPC/BoardConfig-EMMC-Buildroot-RV1106_Luckfox_Pico_Pi_W-IPC.mk               .BoardConfig.mk ;;
  #pico-plus-sd)          ln -s project/cfg/BoardConfig_IPC/BoardConfig-SD_CARD-Buildroot-RV1103_Luckfox_Pico_Plus-IPC.mk            .BoardConfig.mk ;;
  #pico-plus-flash)       ln -s project/cfg/BoardConfig_IPC/BoardConfig-SPI_NAND-Buildroot-RV1103_Luckfox_Pico_Plus-IPC.mk           .BoardConfig.mk ;;
  #pico-pro-sd)           ln -s project/cfg/BoardConfig_IPC/BoardConfig-SD_CARD-Buildroot-RV1106_Luckfox_Pico_Pro-IPC.mk             .BoardConfig.mk ;;
  #pico-pro-flash)        ln -s project/cfg/BoardConfig_IPC/BoardConfig-SPI_NAND-Buildroot-RV1106_Luckfox_Pico_Pro-IPC.mk            .BoardConfig.mk ;;
  #pico-pro-max-fastboot) ln -s project/cfg/BoardConfig_IPC/BoardConfig-SPI_NAND-Busybox-RV1106_Luckfox_Pico_Pro_Max-IPC_FASTBOOT.mk .BoardConfig.mk ;;
  #pico-ultra)            ln -s project/cfg/BoardConfig_IPC/BoardConfig-EMMC-Buildroot-RV1106_Luckfox_Pico_Ultra-IPC.mk              .BoardConfig.mk ;;
  #pico-ultra-w)          ln -s project/cfg/BoardConfig_IPC/BoardConfig-EMMC-Buildroot-RV1106_Luckfox_Pico_Ultra_W-IPC.mk            .BoardConfig.mk ;;
  #pico-ultra-fastboot)   ln -s project/cfg/BoardConfig_IPC/BoardConfig-EMMC-Busybox-RV1106_Luckfox_Pico_Ultra-IPC_FASTBOOT.mk       .BoardConfig.mk ;;
  #pico-webbee-sd)        ln -s project/cfg/BoardConfig_IPC/BoardConfig-SD_CARD-Buildroot-RV1103_Luckfox_Pico_WebBee-IPC.mk          .BoardConfig.mk ;;
  #pico-webbee-flash)     ln -s project/cfg/BoardConfig_IPC/BoardConfig-SPI_NAND-Buildroot-RV1103_Luckfox_Pico_WebBee-IPC.mk         .BoardConfig.mk ;;
  
  *)
    echo "Invalid device: ${DEVICE_NAME}."
    exit 1
    ;;
esac

#echo "$DEVICE_ID" | ./build.sh lunch
echo "export RK_CUSTOM_ROOTFS=../sysdrv/custom_rootfs/$ROOTFS_NAME" >> .BoardConfig.mk
echo "export RK_BOOTARGS_CMA_SIZE=\"1M\"" >> .BoardConfig.mk

#change size on SD
if echo "$DEVICE_NAME" | grep -q "\-sd"; then
	echo "export RK_PARTITION_CMD_IN_ENV=\"32K(env),512K@32K(idblock),256K(uboot),32M(boot),512M(oem),256M(userdata),30G(rootfs)\"" >> .BoardConfig.mk
fi

#cat .BoardConfig.mk

# build sysdrv - rootfs
./build.sh uboot
./build.sh kernel
./build.sh driver
./build.sh env
#./build.sh app
# package firmware
./build.sh firmware
./build.sh save

popd || exit

rm -rf output
mkdir -p output
cp sdk/output/image/* "output/"
