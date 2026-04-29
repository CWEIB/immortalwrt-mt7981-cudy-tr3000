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

# QModem feed
  if [ "${{ steps.set-env.outputs.enable_qmodem_next }}" != "true" ] && [ "${{ steps.set-env.outputs.enable_qmodem }}" != "true" ]; then
    echo "🔧 禁用 qmodem feed..."
    sed -i '/qmodem/d' feeds.conf.default
  fi
  

echo "🧹 正在清理重复和冲突的软件包..."

# ⭐ 修复 QMI WWAN 驱动 Linux 6.6 兼容性 (所有厂商驱动)
fix_qmi_driver() {
local SOURCE_FILE="$1"
if [ -f "$SOURCE_FILE" ]; then
  echo "🔧 修复驱动: $SOURCE_FILE"
  
  # 修复 u64_stats API 变更 (Linux 6.x 移除了 _irq 后缀)
  sed -i 's/u64_stats_fetch_begin_irq/u64_stats_fetch_begin/g' "$SOURCE_FILE"
  sed -i 's/u64_stats_fetch_retry_irq/u64_stats_fetch_retry/g' "$SOURCE_FILE"
  
  # 修复 dev_addr 只读问题 (Linux 5.15+ dev_addr 变为 const)
  # 方法1: 使用 eth_hw_addr_set (推荐)
  if grep -q 'memcpy.*qmap_net->dev_addr.*real_dev->dev_addr' "$SOURCE_FILE"; then
    sed -i 's/memcpy[[:space:]]*(qmap_net->dev_addr,[[:space:]]*real_dev->dev_addr,[[:space:]]*ETH_ALEN);/eth_hw_addr_set(qmap_net, real_dev->dev_addr);/g' "$SOURCE_FILE"
  fi
  # 方法2: 处理其他可能的 memcpy 到 dev_addr 的情况
  if grep -q 'memcpy.*->dev_addr' "$SOURCE_FILE"; then
    # 使用 dev_addr_set 作为备用方案
    sed -i 's/memcpy[[:space:]]*(\([^,]*\)->dev_addr,[[:space:]]*\([^,]*\),[[:space:]]*ETH_ALEN);/dev_addr_set(\1, \2);/g' "$SOURCE_FILE" 2>/dev/null || true
  fi
  
  echo "✅ 驱动修复完成: $SOURCE_FILE"
fi
}

# 修复 Fibocom QMI WWAN 驱动
fix_qmi_driver "package/mtk/applications/5g-modem/fibocom_QMI_WWAN/qmi_wwan_f.c"
fix_qmi_driver "package/mtk/applications/5g-modem/fibocom_QMI_WWAN/src/qmi_wwan_f.c"

# 修复 Quectel QMI WWAN 驱动 (如果存在)
fix_qmi_driver "package/mtk/applications/5g-modem/quectel_QMI_WWAN/qmi_wwan_q.c"
fix_qmi_driver "package/mtk/applications/5g-modem/quectel_QMI_WWAN/src/qmi_wwan_q.c"

# 修复 Simcom QMI WWAN 驱动 (如果存在)
fix_qmi_driver "package/mtk/applications/5g-modem/simcom_QMI_WWAN/qmi_wwan_s.c"
fix_qmi_driver "package/mtk/applications/5g-modem/simcom_QMI_WWAN/src/qmi_wwan_s.c"

# QModem feed
if [ "${{ steps.set-env.outputs.enable_qmodem_next }}" != "true" ] && [ "${{ steps.set-env.outputs.enable_qmodem }}" != "true" ]; then
    echo "🔧 禁用 qmodem feed..."
    sed -i '/qmodem/d' feeds.conf.default
fi

# 清理禁用的 feeds
[ "${{ steps.set-env.outputs.enable_nikki }}" != "true" ] && rm -rf feeds/nikki* package/feeds/nikki 2>/dev/null || true
[ "${{ steps.set-env.outputs.enable_qmodem_next }}" != "true" ] && [ "${{ steps.set-env.outputs.enable_qmodem }}" != "true" ] && rm -rf feeds/qmodem* package/feeds/qmodem 2>/dev/null || true

# feeds update/install

 rm -rf package/feeds/packages/{exim,onionshare-cli,python-zope-event,python-zope-interface,python-gevent,python-twisted} 2>/dev/null || true
# ⭐ 修复 QMI WWAN 驱动 Linux 6.6 兼容性 (所有厂商驱动)
fix_qmi_driver() {
    local SOURCE_FILE="$1"
    if [ -f "$SOURCE_FILE" ]; then
      echo "🔧 修复驱动: $SOURCE_FILE"
      
      # 修复 u64_stats API 变更 (Linux 6.x 移除了 _irq 后缀)
      sed -i 's/u64_stats_fetch_begin_irq/u64_stats_fetch_begin/g' "$SOURCE_FILE"
      sed -i 's/u64_stats_fetch_retry_irq/u64_stats_fetch_retry/g' "$SOURCE_FILE"
      
      # 修复 dev_addr 只读问题 (Linux 5.15+ dev_addr 变为 const)
      # 方法1: 使用 eth_hw_addr_set (推荐)
      if grep -q 'memcpy.*qmap_net->dev_addr.*real_dev->dev_addr' "$SOURCE_FILE"; then
        sed -i 's/memcpy[[:space:]]*(qmap_net->dev_addr,[[:space:]]*real_dev->dev_addr,[[:space:]]*ETH_ALEN);/eth_hw_addr_set(qmap_net, real_dev->dev_addr);/g' "$SOURCE_FILE"
      fi
      # 方法2: 处理其他可能的 memcpy 到 dev_addr 的情况
      if grep -q 'memcpy.*->dev_addr' "$SOURCE_FILE"; then
        # 使用 dev_addr_set 作为备用方案
        sed -i 's/memcpy[[:space:]]*(\([^,]*\)->dev_addr,[[:space:]]*\([^,]*\),[[:space:]]*ETH_ALEN);/dev_addr_set(\1, \2);/g' "$SOURCE_FILE" 2>/dev/null || true
      fi
        echo "✅ 驱动修复完成: $SOURCE_FILE"
    fi
}

# 修复 Fibocom QMI WWAN 驱动
fix_qmi_driver "package/mtk/applications/5g-modem/fibocom_QMI_WWAN/qmi_wwan_f.c"
fix_qmi_driver "package/mtk/applications/5g-modem/fibocom_QMI_WWAN/src/qmi_wwan_f.c"

# 修复 Quectel QMI WWAN 驱动 (如果存在)
fix_qmi_driver "package/mtk/applications/5g-modem/quectel_QMI_WWAN/qmi_wwan_q.c"
fix_qmi_driver "package/mtk/applications/5g-modem/quectel_QMI_WWAN/src/qmi_wwan_q.c"

# 修复 Simcom QMI WWAN 驱动 (如果存在)
fix_qmi_driver "package/mtk/applications/5g-modem/simcom_QMI_WWAN/qmi_wwan_s.c"
fix_qmi_driver "package/mtk/applications/5g-modem/simcom_QMI_WWAN/src/qmi_wwan_s.c"

# 修复 feeds 中的 QModem 驱动 (如果存在且已启用)
if [ -d "feeds/qmodem" ]; then
    for driver_file in $(find feeds/qmodem -name "*.c" -type f 2>/dev/null | xargs grep -l "u64_stats_fetch_begin_irq\|memcpy.*dev_addr" 2>/dev/null || true); do
      fix_qmi_driver "$driver_file"
    done
fi

# QModem 相关修复
if [ -d "package/feeds/qmodem" ]; then
    rm -rf package/feeds/qmodem/ndisc6 2>/dev/null || true
    # 移除 kmod-mhi-wwan 依赖
    find . -path "*qmodem*Makefile" -exec sed -i 's/+\?kmod-mhi-wwan//g' {} \; 2>/dev/null || true
    echo "✅ QModem 驱动修复完成"
fi

# QModem 特殊处理（互斥）
if [ "${{ steps.set-env.outputs.enable_qmodem_next }}" = "true" ]; then
    echo "CONFIG_PACKAGE_luci-app-qmodem-next=y" >> .config
elif [ "${{ steps.set-env.outputs.enable_qmodem }}" = "true" ]; then
    echo "CONFIG_PACKAGE_luci-app-qmodem=y" >> .config
    # QModem 核心
    echo "CONFIG_PACKAGE_luci-compat=y" >> .config
    echo "CONFIG_PACKAGE_qmodem=y" >> .config
    # QModem 驱动选择 - 使用 Vendor 驱动
    echo "CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_vendor-qmi-wwan=y" >> .config
    echo "# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_generic-qmi-wwan is not set" >> .config
    # QModem IPv6 支持
    echo "CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_ndisc6=y" >> .config
    echo "# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_rdisc6 is not set" >> .config
    echo "# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_no_ndisc_rdisc6 is not set" >> .config
    echo "CONFIG_PACKAGE_ndisc6=y" >> .config
    # QModem Quectel CM 选择 - 使用 Tom 定制版
    echo "CONFIG_PACKAGE_luci-app-qmodem_USE_TOM_CUSTOMIZED_QUECTEL_CM=y" >> .config
    echo "# CONFIG_PACKAGE_luci-app-qmodem_USING_QWRT_QUECTEL_CM_5G is not set" >> .config
    echo "# CONFIG_PACKAGE_luci-app-qmodem_USING_NORMAL_QUECTEL_CM is not set" >> .config
    echo "CONFIG_PACKAGE_quectel-CM-5G-M=y" >> .config
    # QModem 依赖工具
    echo "CONFIG_PACKAGE_sms-tool_q=y" >> .config
    echo "CONFIG_PACKAGE_ubus-at-daemon=y" >> .config
    echo "CONFIG_PACKAGE_tom_modem=y" >> .config
    # QModem Vendor QMI 驱动
    echo "CONFIG_PACKAGE_kmod-qmi_wwan_q=y" >> .config
    echo "CONFIG_PACKAGE_kmod-qmi_wwan_f=y" >> .config
    echo "CONFIG_PACKAGE_kmod-qmi_wwan_s=y" >> .config
    # QModem MWAN (多WAN负载均衡)
    echo "CONFIG_PACKAGE_mwan3=y" >> .config
    echo "CONFIG_PACKAGE_luci-app-mwan3=y" >> .config
    # HQOS 支持
    echo "CONFIG_PACKAGE_mtkhqos_util=y" >> .config
else
    disabled_pkgs+=("luci-app-qmodem-next" "luci-app-qmodem")
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
