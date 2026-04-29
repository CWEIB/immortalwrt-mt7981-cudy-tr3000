#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1./192.168.8./g' package/base-files/files/bin/config_generate

# 1. 彻底移除报错的 fibocom_QMI_WWAN 驱动目录
# 这个驱动版本过旧，不支持 6.6 内核，且与 QModem 提供的驱动功能重复
echo "正在清理不兼容的内置 5G 驱动..."
rm -rf package/mtk/applications/5g-modem/quectel_QMI_WWAN
rm -rf package/mtk/applications/5g-modem/fibocom_QMI_WWAN
rm -rf package/mtk/applications/5g-modem/quectel_MHI

# 2. 移除重复的 5G 驱动包（避免多处源码冲突）
# rm -rf package/feeds/qmodem/fibocom_QMI_WWAN
# rm -rf package/feeds/qmodem/quectel_QMI_WWAN
# rm -rf package/feeds/qmodem/quectel_MHI

# 1. 移除不需要或有问题的包（避免编译中报错）
rm -rf package/feeds/packages/exim
rm -rf package/feeds/packages/onionshare-cli
rm -rf package/feeds/packages/python-zope-event
rm -rf package/feeds/packages/python-zope-interface
rm -rf package/feeds/packages/python-gevent
rm -rf package/feeds/packages/python-twisted

# 2. ndisc6 处理：移除 QModem feed 中的重复版本，优先使用源码自带版本
rm -rf package/feeds/qmodem/ndisc6

# 3. 修复 qmodem 的 kmod-mhi-wwan 依赖警告 (改为可选依赖)
QMODEM_MK="package/feeds/qmodem/qmodem/Makefile"
if [ -f "$QMODEM_MK" ]; then
    sed -i 's/DEPENDS:=.*+kmod-mhi-wwan/# &/g' "$QMODEM_MK"
    sed -i 's/+kmod-mhi-wwan/+PACKAGE_luci-app-qmodem_GENERIC_MHI_PCIe_DRIVER:kmod-mhi-wwan/g' "$QMODEM_MK"
fi
# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 临时解决Rust问题
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile

# add date in output file name
sed -i -e '/^IMG_PREFIX:=/i BUILD_DATE := $(shell date +%Y%m%d)' \
       -e '/^IMG_PREFIX:=/ s/\($(SUBTARGET)\)/\1-$(BUILD_DATE)/' include/image.mk

# set ubi to 122M
# sed -i 's/reg = <0x5c0000 0x7000000>;/reg = <0x5c0000 0x7a40000>;/' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts
