#!/bin/bash
# Cudy TR3000 / MT7981 专项 DIY 脚本 - 适配原版 QModem

set -e

# =========================
# 1. 基础配置：修改 IP
# =========================
# 适配 Cudy 习惯，或者保持你的 192.168.8.1
sed -i 's/192.168.1.1/192.168.8.1/g' package/base-files/files/bin/config_generate

# =========================
# 2. 物理铲除 Next 分支（核心：解决 Error 255）
# =========================
echo "🧹 正在清除 QModem-Next 及其关联包，确保无冲突..."
# 物理删除所有带 -next 后缀的目录，彻底解决 11_modem.js 等文件路径冲突
find package/feeds/qmodem/ -name "*-next" -type d -exec rm -rf {} + 2>/dev/null || true
rm -rf package/feeds/qmodem/luci-app-qmodem-monitor 2>/dev/null || true
rm -rf package/feeds/qmodem/luci-app-qmodem-sms 2>/dev/null || true

# =========================
# 3. 修复 5G 驱动兼容性 (Linux 6.6 关键修复)
# =========================
echo "🔧 修复 5G 厂商驱动 (Quectel/Fibocom) 在 6.6 内核下的报错..."

fix_kernel_api() {
    local file="$1"
    [ -f "$file" ] || return
    # 1. 修复统计函数名变更 (Linux 6.x)
    sed -i 's/u64_stats_fetch_begin_irq/u64_stats_fetch_begin/g' "$file"
    sed -i 's/u64_stats_fetch_retry_irq/u64_stats_fetch_retry/g' "$file"
    # 2. 修复 dev_addr 只读问题 (使用 Linux 规范的 eth_hw_addr_set)
    sed -i 's/memcpy(\(.*\)->dev_addr, \(.*\), ETH_ALEN);/eth_hw_addr_set(\1, \2);/g' "$file"
}

# 全局扫描 QModem 和 MTK 目录下的 C 源码进行补丁
find package/feeds/qmodem/ -name "*.c" | while read -r f; do fix_kernel_api "$f"; done
find package/mtk/ -name "*.c" | while read -r f; do fix_kernel_api "$f"; done

# =========================
# 4. 强制修正 Makefile 依赖
# =========================
# 确保原版 qmodem 能够拉起必要的内核驱动模块
QMODEM_MK="package/feeds/qmodem/qmodem/Makefile"
if [ -f "$QMODEM_MK" ]; then
    echo "⚙️ 修正 qmodem 编译依赖..."
    # 确保原版 qmodem 依赖基础驱动包，防止菜单里选了 UI 却没编译内核模块
    sed -i 's/DEPENDS:=/DEPENDS:=+kmod-usb-net-qmi-wwan +kmod-usb-serial-option +/' "$QMODEM_MK"
fi

# =========================
# 5. 写入配置：锁定原版，禁用 Next
# =========================
echo "📝 锁定原版 QModem 编译选项..."
cat >> .config <<EOF
CONFIG_PACKAGE_luci-app-qmodem=y
CONFIG_PACKAGE_luci-i18n-qmodem-zh-cn=y
CONFIG_PACKAGE_sms-forwarder=y
# CONFIG_PACKAGE_luci-app-qmodem-next is not set
# CONFIG_PACKAGE_sms-forwarder-next is not set
# CONFIG_PACKAGE_luci-app-qmodem-monitor is not set
EOF

# =========================
# 6. 其他 TR3000 常规修复
# =========================
# 修复 Rust 编译可能导致的 OOM 或挂起
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile 2>/dev/null || true
# 修复 MTK 无线驱动依赖
[ -f "package/mtk/drivers/mt_hwifi/Makefile" ] && sed -i 's/+kmod-mt_wifi_osal//g' "package/mtk/drivers/mt_hwifi/Makefile" || true

echo "✅ DIY PART2 适配完毕，开始编译 Cudy TR3000..."
