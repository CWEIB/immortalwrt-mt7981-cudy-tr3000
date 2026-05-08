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
sed -i 's/192.168.6.1/192.168.8.1/g' package/base-files/files/bin/config_generate

# ==============================
# 设置默认 WiFi 名称为 WIFI_CH
# ==============================
sed -i 's/ImmortalWrt-2.4G/WIFI_CH-2.4G/g' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
sed -i 's/ImmortalWrt-5G/WIFI_CH-2.4G/g' package/mtk/applications/mtwifi-cfg/files/mtwifi.sh

# ==============================
# 设置默认路由器密码为 password
# ==============================
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/base-files/files/etc/shadow

# ==============================
# 更改主机名
# ==============================
# sed -i "s/hostname='.*'/hostname='AE86Wrt'/g" package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/CudyWRT/g' package/base-files/files/bin/config_generate

# ==============================
# 加入作者信息
# ==============================
# sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='TR3000Wrt-$(date +%Y%m%d)'/g"  package/base-files/files/etc/openwrt_release
# sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' By CWEIB'/g" package/base-files/files/etc/openwrt_release
# sed -i "s/OPENWRT_RELEASE=\"*.*\"/OPENWRT_RELEASE=\"TR3000Wrt-$(date +%Y%m%d) By CWEIB\"/g" package/base-files/files/usr/lib/os-release

# ---------- QModem 6.6 驱动补丁函数 ----------
# ⭐ 修复 QMI WWAN 驱动 Linux 6.6 兼容性 (所有厂商驱动)
# echo "修复依赖警告..."

# 1. 移除不需要的有问题的包
# rm -rf package/feeds/packages/exim 2>/dev/null || true
# rm -rf package/feeds/packages/onionshare-cli 2>/dev/null || true
# rm -rf package/feeds/packages/python-zope-event 2>/dev/null || true
# rm -rf package/feeds/packages/python-zope-interface 2>/dev/null || true

# 2. ndisc6 处理：优先使用源码自带版本，移除 QModem feed 中的重复版本避免冲突
# padavanonly 源码在 package/mtk/applications/5g-modem/ndisc 已包含 ndisc6
# rm -rf package/feeds/qmodem/ndisc6 2>/dev/null || true

# 3. 修复 kmod-mhi-wwan 依赖 - 修改 qmodem Makefile 移除该依赖
# qmodem 包默认使用 vendor 驱动 (pcie_mhi)，不需要 generic mhi-wwan
# QMODEM_MK="package/feeds/qmodem/qmodem/Makefile"
# if [ -f "$QMODEM_MK" ]; then
#   echo "🔧 修复驱动: $QMODEM_MK"
#   # 将 kmod-mhi-wwan 依赖改为注释（禁用）
#   sed -i 's/DEPENDS:=.*+kmod-mhi-wwan/# &/g' "$QMODEM_MK" || true
#   sed -i 's/+kmod-mhi-wwan/+PACKAGE_luci-app-qmodem_GENERIC_MHI_PCIe_DRIVER:kmod-mhi-wwan/g' "$QMODEM_MK" || true
# fi

# 移除有问题的依赖包 Makefile 定义或禁用它们
# rm -rf package/feeds/packages/python-gevent 2>/dev/null || true
# rm -rf package/feeds/packages/python-twisted 2>/dev/null || true

# fix_qmi_driver() {
#   local SOURCE_FILE="$1"
#   if [ -f "$SOURCE_FILE" ]; then
#     echo "🔧 修复驱动: $SOURCE_FILE"
      
#     # 修复 u64_stats API 变更 (Linux 6.x 移除了 _irq 后缀)
#      sed -i 's/u64_stats_fetch_begin_irq/u64_stats_fetch_begin/g' "$SOURCE_FILE"
#      sed -i 's/u64_stats_fetch_retry_irq/u64_stats_fetch_retry/g' "$SOURCE_FILE"

#      # 修复 dev_addr 只读问题 (Linux 5.15+ dev_addr 变为 const)
#      # 方法1: 使用 eth_hw_addr_set (推荐)
#      if grep -q 'memcpy.*qmap_net->dev_addr.*real_dev->dev_addr' "$SOURCE_FILE"; then
#         sed -i 's/memcpy[[:space:]]*(qmap_net->dev_addr,[[:space:]]*real_dev->dev_addr,[[:space:]]*ETH_ALEN);/eth_hw_addr_set(qmap_net, real_dev->dev_addr);/g' "$SOURCE_FILE"
#         echo "$(date '+%F %T') [QMAP-MAC-FIX] Patched dev_addr memcpy -> eth_hw_addr_set in: $SOURCE_FILE"
#      fi
#      # 方法2: 处理其他可能的 memcpy 到 dev_addr 的情况
#      if grep -q 'memcpy.*->dev_addr' "$SOURCE_FILE"; then
#      # 使用 dev_addr_set 作为备用方案
#        sed -i 's/memcpy[[:space:]]*(\([^,]*\)->dev_addr,[[:space:]]*\([^,]*\),[[:space:]]*ETH_ALEN);/dev_addr_set(\1, \2);/g' "$SOURCE_FILE" 2>/dev/null || true
#        echo "$(date '+%F %T') [DEV-ADDR-FIX] Patched generic memcpy(dev_addr) -> dev_addr_set in: $SOURCE_FILE"
#      fi
      
#      echo "✅ 驱动修复完成: $SOURCE_FILE"
#   fi
# }
# fix_qmi_driver() {
#   local SOURCE_FILE="$1"
#   if [ -f "$SOURCE_FILE" ]; then
#     echo "🔧 修复驱动: $SOURCE_FILE"

#     # 1. u64_stats API 修复
#     sed -i 's/u64_stats_fetch_begin_irq/u64_stats_fetch_begin/g' "$SOURCE_FILE"
#     sed -i 's/u64_stats_fetch_retry_irq/u64_stats_fetch_retry/g' "$SOURCE_FILE"

#     # 2. 修 memcpy(dev_addr)
#     sed -i 's/memcpy[[:space:]]*(\([^,]*\)->dev_addr,[[:space:]]*\([^,]*\),[[:space:]]*ETH_ALEN);/eth_hw_addr_set(\1, \2);/g' "$SOURCE_FILE" 2>/dev/null || true

#     # 3. ⭐⭐关键修复：在 alloc_etherdev 后强制设置 MAC⭐⭐
#     if grep -q "alloc_etherdev" "$SOURCE_FILE"; then
#       sed -i '/alloc_etherdev/a\
# \ \ \ \ eth_hw_addr_random(net);' "$SOURCE_FILE"
#       echo "$(date '+%F %T') [MAC-INIT-FIX] Insert eth_hw_addr_random after alloc_etherdev in: $SOURCE_FILE"
#     fi

#     # 4. 确保包含头文件
#     if ! grep -q "etherdevice.h" "$SOURCE_FILE"; then
#       sed -i '1i #include <linux/etherdevice.h>' "$SOURCE_FILE"
#     fi

#     echo "✅ 驱动修复完成: $SOURCE_FILE"
#   fi
# }
  
# # 修复 Fibocom QMI WWAN 驱动
# fix_qmi_driver "package/mtk/applications/5g-modem/fibocom_QMI_WWAN/qmi_wwan_f.c"
# fix_qmi_driver "package/mtk/applications/5g-modem/fibocom_QMI_WWAN/src/qmi_wwan_f.c"

# # 修复 Quectel QMI WWAN 驱动 (如果存在)
# fix_qmi_driver "package/mtk/applications/5g-modem/quectel_QMI_WWAN/qmi_wwan_q.c"
# fix_qmi_driver "package/mtk/applications/5g-modem/quectel_QMI_WWAN/src/qmi_wwan_q.c"

# # 修复 Simcom QMI WWAN 驱动 (如果存在)
# fix_qmi_driver "package/mtk/applications/5g-modem/simcom_QMI_WWAN/qmi_wwan_s.c"
# fix_qmi_driver "package/mtk/applications/5g-modem/simcom_QMI_WWAN/src/qmi_wwan_s.c"

# # 修复 feeds 中的 QModem 驱动 (如果存在且已启用)
# if [ -d "feeds/qmodem" ]; then
#   for driver_file in $(find feeds/qmodem -name "*.c" -type f 2>/dev/null | xargs grep -l "u64_stats_fetch_begin_irq\|memcpy.*dev_addr" 2>/dev/null || true); do
#     fix_qmi_driver "$driver_file"
#   done
# fi


# find . -path "*qmodem*Makefile" -exec sed -i 's/+\?kmod-mhi-wwan//g' {} \; 2>/dev/null || true

 # 修复 mt_hwifi
# [ -f "package/mtk/drivers/mt_hwifi/Makefile" ] && sed -i 's/+kmod-mt_wifi_osal//g' "package/mtk/drivers/mt_hwifi/Makefile" || true
# ---------- 清理有问题的包 ----------


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
