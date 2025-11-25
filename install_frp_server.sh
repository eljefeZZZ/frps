#!/bin/bash

set -e

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

echo -e "${YELLOW}=== frp 服务端一键安装及配置脚本 ===${PLAIN}"

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}错误：该脚本必须以 root 用户运行！${PLAIN}"
   echo "请使用 root 用户登录，或在命令前加 sudo"
   exit 1
fi

# --- 参数收集 ---
echo "------------------------------------------------"
read -p "请输入绑定端口 [默认: 7000]: " bind_port
bind_port=${bind_port:-7000}

read -p "请输入HTTP虚拟主机端口 [默认: 8080]: " vhost_http_port
vhost_http_port=${vhost_http_port:-8080}

read -p "请输入HTTPS虚拟主机端口 [默认: 8443]: " vhost_https_port
vhost_https_port=${vhost_https_port:-8443}

read -p "请输入Dashboard端口 [默认: 7500]: " dashboard_port
dashboard_port=${dashboard_port:-7500}

read -p "请输入Dashboard用户名 [默认: admin]: " dashboard_user
dashboard_user=${dashboard_user:-admin}

read -s -p "请输入Dashboard密码 [必填，默认不显示]: " dashboard_pwd
echo ""
if [ -z "$dashboard_pwd" ]; then
  echo -e "${RED}错误：密码不能为空，脚本退出！${PLAIN}"
  exit 1
fi

read -p "请输入Token (客户端连接密钥) [默认: 随机生成]: " token
if [ -z "$token" ]; then
  token=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)
  echo -e "已自动生成 Token: ${SKYBLUE}$token${PLAIN}"
fi
echo "------------------------------------------------"

# 获取本机公网IP (尝试多个源)
echo "正在获取本机公网 IP..."
SERVER_IP=$(curl -s -4 http://ifconfig.me || curl -s -4 http://api.ipify.org || curl -s -4 http://ci.ip.sb)
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="无法获取，请手动确认"
fi

# --- 安装过程 ---
INSTALL_DIR="/frp"
# 获取 GitHub 最新 release 下载链接
echo "正在获取 frp 最新版本链接..."
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep browser_download_url | grep linux_amd64.tar.gz | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo -e "${RED}获取下载链接失败，请检查网络连接。${PLAIN}"
    exit 1
fi

echo -e "下载最新版本 frp: ${SKYBLUE}$DOWNLOAD_URL${PLAIN} ..."
mkdir -p "$INSTALL_DIR"
wget -qO /tmp/frp.tar.gz "$DOWNLOAD_URL"

echo "解压 frp 到 $INSTALL_DIR ..."
tar -zxf /tmp/frp.tar.gz -C "$INSTALL_DIR" --strip-components=1
rm /tmp/frp.tar.gz

echo "写入配置文件 frps.ini ..."
cat > "$INSTALL_DIR/frps.ini" <<EOF
[common]
bind_port = $bind_port
vhost_http_port = $vhost_http_port
vhost_https_port = $vhost_https_port
dashboard_port = $dashboard_port
dashboard_user = $dashboard_user
dashboard_pwd = $dashboard_pwd
token = $token
EOF

echo "创建 systemd 服务文件..."
SERVICE_FILE="/etc/systemd/system/frps.service"

cat > $SERVICE_FILE <<EOF
[Unit]
Description=frp server
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/frps -c $INSTALL_DIR/frps.ini
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

echo "重载 systemd 配置，加自启动..."
systemctl daemon-reload
systemctl enable frps >/dev/null 2>&1

echo "启动 frps 服务..."
systemctl restart frps

# --- 最终展示 ---
echo ""
echo -e "${GREEN}==============================================${PLAIN}"
echo -e "${GREEN}        frp 服务端安装并启动成功！${PLAIN}"
echo -e "${GREEN}==============================================${PLAIN}"
echo -e " 服务器 IP      : ${SKYBLUE}${SERVER_IP}${PLAIN}"
echo -e " 绑定端口       : ${YELLOW}${bind_port}${PLAIN}"
echo -e " ---------------------------------------------"
echo -e " HTTP  端口     : ${YELLOW}${vhost_http_port}${PLAIN}"
echo -e " HTTPS 端口     : ${YELLOW}${vhost_https_port}${PLAIN}"
echo -e " ---------------------------------------------"
echo -e " 面板地址       : ${SKYBLUE}http://${SERVER_IP}:${dashboard_port}${PLAIN}"
echo -e " 面板账号       : ${YELLOW}${dashboard_user}${PLAIN}"
echo -e " 面板密码       : ${YELLOW}${dashboard_pwd}${PLAIN}"
echo -e " ---------------------------------------------"
echo -e " 连接 Token     : ${RED}${token}${PLAIN}  (客户端填写此密钥)"
echo -e "${GREEN}==============================================${PLAIN}"
echo ""
echo -e "配置文件路径: ${INSTALL_DIR}/frps.ini"
echo -e "查看运行状态: systemctl status frps"
echo -e "重启服务命令: systemctl restart frps"
echo ""


