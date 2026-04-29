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

# ---------- QModem 6.6 驱动补丁函数 ----------
fix_qmi_driver() {
  local f="$1"
  sed -i 's/u64_stats_fetch_begin_irq/u64_stats_fetch_begin/g' "$f"
  sed -i 's/u64_stats_fetch_retry_irq/u64_stats_fetch_retry/g' "$f"
  sed -i 's/memcpy(.*dev_addr.*/eth_hw_addr_set(dev, addr);/g' "$f"
}

# ---------- 修复 6.6 kmod 改名（全仓） ----------
find . -name Makefile -exec sed -i 's/kmod-pcie_mhi/kmod-mhi/g' {} +
find . -name Makefile -exec sed -i 's/kmod-mhi-bus/kmod-mhi/g' {} +
find . -name Makefile -exec sed -i 's/kmod-mhi-wwan/kmod-mhi-net/g' {} +

# ---------- QModem 驱动源码修复 ----------
if [ -d "feeds/qmodem" ]; then
  for f in $(find feeds/qmodem -name "*.c" -type f 2>/dev/null \
    | xargs grep -l "u64_stats_fetch_begin_irq\|memcpy.*dev_addr" 2>/dev/null); do
    fix_qmi_driver "$f"
  done
fi

# ---------- 清理有问题的包 ----------
if [ -d "package/feeds/qmodem" ]; then
  rm -rf package/feeds/qmodem/ndisc6 2>/dev/null || true
  # 移除 kmod-mhi-wwan 依赖
  # find . -path "*qmodem*Makefile" -exec sed -i 's/+\?kmod-mhi-wwan//g' {} \; 2>/dev/null || true
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
