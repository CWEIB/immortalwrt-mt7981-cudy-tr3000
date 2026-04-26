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

# 3. 移除 qmodem 中不使用的冗余 LuCI 插件（只留 next 版）
# 这一步能大幅减少生成 ipk 时的磁盘占用和 js 文件冲突
find feeds/qmodem/luci/ -maxdepth 1 -type d ! -name "luci-app-qmodem-next" -exec rm -rf {} +

# 4. 修复依赖警告
sed -i 's/+kmod-mhi-wwan//g' feeds/qmodem/qmodem/Makefile

# 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 针对性安装 QModem 的组件，避免全量安装导致冲突
# 这里以安装 "next" 系列（较新）为例，如果你想用稳定版，请去掉 -next 后缀
./scripts/feeds install -p qmodem luci-app-qmodem-next
./scripts/feeds install -p qmodem qfirehose
./scripts/feeds install -p qmodem quectel_CM_5G_M
# 如果需要短信转发，选一个即可
./scripts/feeds install -p qmodem sms_forwarder_next

# 临时解决Rust问题
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile

# add date in output file name
sed -i -e '/^IMG_PREFIX:=/i BUILD_DATE := $(shell date +%Y%m%d)' \
       -e '/^IMG_PREFIX:=/ s/\($(SUBTARGET)\)/\1-$(BUILD_DATE)/' include/image.mk

# set ubi to 122M
# sed -i 's/reg = <0x5c0000 0x7000000>;/reg = <0x5c0000 0x7a40000>;/' target/linux/mediatek/dts/mt7981b-cudy-tr3000-v1-ubootmod.dts
