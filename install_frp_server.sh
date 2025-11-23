#!/bin/bash

set -e

echo "=== frp 服务端一键安装及配置脚本 ==="

read -p "绑定端口 [7000]: " bind_port
bind_port=${bind_port:-7000}

read -p "HTTP虚拟主机端口 [8080]: " vhost_http_port
vhost_http_port=${vhost_http_port:-8080}

read -p "HTTPS虚拟主机端口 [8443]: " vhost_https_port
vhost_https_port=${vhost_https_port:-8443}

read -p "Dashboard端口 [7500]: " dashboard_port
dashboard_port=${dashboard_port:-7500}

read -p "Dashboard用户名 [admin]: " dashboard_user
dashboard_user=${dashboard_user:-admin}

read -s -p "Dashboard密码 [请输入]: " dashboard_pwd
echo ""
if [ -z "$dashboard_pwd" ]; then
  echo "密码不能为空，退出！"
  exit 1
fi

read -p "Token (客户端连接密码) [默认随机生成]: " token
if [ -z "$token" ]; then
  token=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)
  echo "自动生成 Token: $token"
fi

INSTALL_DIR="/frp"
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep browser_download_url | grep linux_amd64.tar.gz | cut -d '"' -f 4)

echo "下载最新版本 frp ..."
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

sudo bash -c "cat > $SERVICE_FILE" <<EOF
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
sudo systemctl daemon-reload
sudo systemctl enable frps

echo "启动 frps 服务..."
sudo systemctl start frps

echo "frp服务端安装并启动完成！"
echo "配置文件路径: $INSTALL_DIR/frps.ini"
echo "服务状态:"
sudo systemctl status frps --no-pager

echo "脚本执行完毕，祝你使用愉快！"
