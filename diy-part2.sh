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
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

# 1. 删除所有可能导致冲突的内置 MTK 5G 驱动
rm -rf package/mtk/applications/5g-modem

# 2. 移除重复的工具定义
rm -rf feeds/packages/utils/sms-tool
rm -rf feeds/telephony/net/sendat

./scripts/feeds update -a

# 修复依赖
find feeds/qmodem/ -name Makefile -exec sed -i 's/+kmod-mhi-wwan//g' {} +

# 3. 移除 qmodem 中不使用的冗余 LuCI 插件（只留 next 版）
# 这一步能大幅减少生成 ipk 时的磁盘占用和 js 文件冲突
find feeds/qmodem/luci/ -maxdepth 1 -type d ! -name "luci-app-qmodem-next" -exec rm -rf {} +

# 强制安装 QModem 包
./scripts/feeds install -f -p qmodem qmodem qfirehose quectel_CM_5G_M luci-app-qmodem-next sms_forwarder_next

# 安装其它包
./scripts/feeds install -a

# 临时解决Rust问题
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile

# add date in output file name
sed -i -e '/^IMG_PREFIX:=/i BUILD_DATE := $(shell date +%Y%m%d)' \
       -e '/^IMG_PREFIX:=/ s/\($(SUBTARGET)\)/\1-$(BUILD_DATE)/' include/image.mk

# set ubi to 122M
# sed -i 's/reg = <0x5c0000 0x7000000>;/reg = <0x5c0000 0x7a40000>;/' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts
