#!/bin/bash
#
# ImmortalWrt H5000M stable DIY script part 2
#

set -e

echo "======================================"
echo "   DIY PART2 - STABLE MODE ENABLED"
echo "======================================"

# =========================
# 1. 修改默认 IP
# =========================
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate
sed -i 's/192.168.1./192.168.8./g' package/base-files/files/bin/config_generate


# =========================
# 2. 强制清理冲突包（关键）
# =========================
echo "🧹 清理冲突 qmodem / sms-forwarder..."

rm -rf package/feeds/qmodem/luci-app-qmodem-next 2>/dev/null || true
rm -rf package/feeds/qmodem/luci-app-qmodem-monitor 2>/dev/null || true
rm -rf package/feeds/qmodem/luci-app-qmodem-sms 2>/dev/null || true
rm -rf package/feeds/qmodem/sms-forwarder 2>/dev/null || true
rm -rf package/feeds/qmodem/luci-i18n-qmodem-next* 2>/dev/null || true

# 防止重复 UI
rm -rf feeds/luci/applications/luci-app-qmodem-next 2>/dev/null || true


# =========================
# 3. 修复 qmodem Makefile（核心）
# =========================
QMODEM_MK="package/feeds/qmodem/qmodem/Makefile"

if [ -f "$QMODEM_MK" ]; then
    echo "🔧 修复 qmodem 依赖..."

    # 删除不稳定 / fork 依赖
    sed -i 's/+kmod-qmi_wwan_q//g' "$QMODEM_MK"
    sed -i 's/+kmod-qmi_wwan_f//g' "$QMODEM_MK"
    sed -i 's/+kmod-qmi_wwan_s//g' "$QMODEM_MK"
    sed -i 's/+kmod-pcie_mhi//g' "$QMODEM_MK"

    # 可选：避免强制失败
    sed -i 's/DEPENDS:=/DEPENDS:=+/' "$QMODEM_MK"
fi


# =========================
# 4. 修复 sms-forwarder 冲突
# =========================
echo "🔧 修复 sms-forwarder 冲突..."

SMS_MK="package/feeds/qmodem/sms-forwarder/Makefile"
if [ -f "$SMS_MK" ]; then
    sed -i 's/sms_forwarder/sms_forwarder_next/g' "$SMS_MK" 2>/dev/null || true
fi


# =========================
# 5. 统一禁用旧 modem stack
# =========================
echo "🚫 禁用旧 modem stack..."

cat >> .config <<EOF
# disable legacy modem stack
# CONFIG_PACKAGE_luci-app-qmodem is not set
# CONFIG_PACKAGE_sms-forwarder is not set
# CONFIG_PACKAGE_modem is not set
EOF


# =========================
# 6. MTK 5G driver 安全修复（保守版）
# =========================
echo "🔧 修复 MTK QMI driver..."

fix_drv() {
    [ -f "$1" ] || return
    sed -i 's/u64_stats_fetch_begin_irq/u64_stats_fetch_begin/g' "$1"
    sed -i 's/u64_stats_fetch_retry_irq/u64_stats_fetch_retry/g' "$1"

    # dev_addr 只读问题（安全替换）
    sed -i 's/memcpy(\(.*\)->dev_addr, \(.*\), ETH_ALEN);/eth_hw_addr_set(\1, \2);/g' "$1"
}

for f in $(find package/mtk -name "*.c" 2>/dev/null); do
    fix_drv "$f"
done


# =========================
# 7. 删除冲突 Python / tool packages（可选优化）
# =========================
rm -rf package/feeds/packages/{python-twisted,python-gevent,python-zope-*} 2>/dev/null || true


# =========================
# 8. Rust fix（保留你的逻辑）
# =========================
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile 2>/dev/null || true


# =========================
# 9. 确保 defconfig 干净生成
# =========================
echo "⚙️ running defconfig..."
make defconfig


echo "======================================"
echo "   DIY PART2 DONE (STABLE)"
echo "======================================"
