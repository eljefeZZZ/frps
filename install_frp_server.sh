#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'

CONF_FILE="/frp/frps.ini"
SERVICE_FILE="/etc/systemd/system/frps.service"
INSTALL_DIR="/frp"

# --- 辅助函数 ---

# 获取配置值
get_config_value() {
    key=$1
    if [ -f "$CONF_FILE" ]; then
        grep "^$key =" $CONF_FILE | awk -F "= " '{print $2}'
    else
        echo ""
    fi
}

# 通用修改配置函数
modify_config() {
    key=$1
    name=$2
    current_val=$(get_config_value $key)
    
    echo ""
    echo -e "当前 $name 为: ${YELLOW}$current_val${PLAIN}"
    read -p "请输入新的 $name: " new_val
    
    if [ -z "$new_val" ]; then
        echo -e "${RED}输入不能为空！${PLAIN}"
        sleep 1
        show_menu
        return
    fi
    
    # 使用 sed 替换配置
    sed -i "s/^$key = .*/$key = $new_val/" $CONF_FILE
    
    echo -e "${GREEN}$name 已修改为 $new_val，正在重启服务...${PLAIN}"
    systemctl restart frps
    sleep 1
    echo -e "${GREEN}修改成功！${PLAIN}"
    sleep 1
    show_menu
}

# --- 核心流程函数 ---

# 1. 安装流程
install_frps() {
    echo -e "${YELLOW}=== 开始安装 frp 服务端 ===${PLAIN}"

    # 检查是否为 root
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误：该脚本必须以 root 用户运行！${PLAIN}"
        exit 1
    fi

    # 收集参数
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

    read -s -p "请输入Dashboard密码 [必填]: " dashboard_pwd
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

    # 下载安装
    echo "正在获取 frp 最新版本链接..."
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep browser_download_url | grep linux_amd64.tar.gz | cut -d '"' -f 4)

    if [ -z "$DOWNLOAD_URL" ]; then
        echo -e "${RED}获取下载链接失败，请检查网络连接。${PLAIN}"
        exit 1
    fi

    echo -e "下载最新版本 frp: ${SKYBLUE}$DOWNLOAD_URL${PLAIN} ..."
    mkdir -p "$INSTALL_DIR"
    wget -qO /tmp/frp.tar.gz "$DOWNLOAD_URL"
    tar -zxf /tmp/frp.tar.gz -C "$INSTALL_DIR" --strip-components=1
    rm /tmp/frp.tar.gz

    # 写入配置
    echo "写入配置文件 frps.ini ..."
    cat > "$CONF_FILE" <<EOF
[common]
bind_port = $bind_port
vhost_http_port = $vhost_http_port
vhost_https_port = $vhost_https_port
dashboard_port = $dashboard_port
dashboard_user = $dashboard_user
dashboard_pwd = $dashboard_pwd
token = $token
EOF

    # 创建服务
    echo "创建 systemd 服务文件..."
    cat > $SERVICE_FILE <<EOF
[Unit]
Description=frp server
After=network.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/frps -c $CONF_FILE
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable frps >/dev/null 2>&1
    systemctl restart frps

    view_config
}

# 2. 卸载流程
uninstall_frps() {
    echo ""
    read -p "确定要卸载 frps 吗？(y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        systemctl stop frps
        systemctl disable frps
        rm -f $SERVICE_FILE
        systemctl daemon-reload
        rm -rf $INSTALL_DIR
        echo -e "${GREEN}frps 已完全卸载！${PLAIN}"
        exit 0
    else
        show_menu
    fi
}

# 3. 查看信息
view_config() {
    # 获取本机 IPv4
    SERVER_IP=$(curl -s -4 http://ifconfig.me || curl -s -4 http://api.ipify.org)
    if [ -z "$SERVER_IP" ]; then SERVER_IP="无法获取"; fi

    bind_port=$(get_config_value "bind_port")
    vhost_http_port=$(get_config_value "vhost_http_port")
    vhost_https_port=$(get_config_value "vhost_https_port")
    dashboard_port=$(get_config_value "dashboard_port")
    dashboard_user=$(get_config_value "dashboard_user")
    dashboard_pwd=$(get_config_value "dashboard_pwd")
    token=$(get_config_value "token")

    echo ""
    echo -e "${GREEN}==============================================${PLAIN}"
    echo -e "${GREEN}        frp 服务端运行状态及配置信息${PLAIN}"
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
}

# 4. 管理菜单
show_menu() {
    clear
    echo -e "${YELLOW}=== frp 服务端一键管理脚本 ===${PLAIN}"
    echo -e "${GREEN}1.${PLAIN} 查看当前配置信息"
    echo -e "${GREEN}2.${PLAIN} 修改绑定端口 (Bind Port)"
    echo -e "${GREEN}3.${PLAIN} 修改 HTTP 端口"
    echo -e "${GREEN}4.${PLAIN} 修改 HTTPS 端口"
    echo -e "${GREEN}5.${PLAIN} 修改 Token (连接密钥)"
    echo -e "${GREEN}6.${PLAIN} 修改 Dashboard 密码"
    echo "-----------------------------"
    echo -e "${GREEN}7.${PLAIN} 重启 frps 服务"
    echo -e "${GREEN}8.${PLAIN} 停止 frps 服务"
    echo -e "${GREEN}9.${PLAIN} 卸载 frps"
    echo "-----------------------------"
    echo -e "${GREEN}0.${PLAIN} 退出"
    echo ""
    read -p "请输入选项 [0-9]: " choice
    
    case $choice in
        1) view_config && read -p "按回车键返回菜单..." && show_menu ;;
        2) modify_config "bind_port" "绑定端口" ;;
        3) modify_config "vhost_http_port" "HTTP 端口" ;;
        4) modify_config "vhost_https_port" "HTTPS 端口" ;;
        5) modify_config "token" "Token" ;;
        6) modify_config "dashboard_pwd" "Dashboard 密码" ;;
        7) systemctl restart frps && echo -e "${GREEN}服务已重启！${PLAIN}" && sleep 2 && show_menu ;;
        8) systemctl stop frps && echo -e "${RED}服务已停止！${PLAIN}" && sleep 2 && show_menu ;;
        9) uninstall_frps ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项！${PLAIN}" && sleep 1 && show_menu ;;
    esac
}

# --- 入口逻辑 ---
if [ -f "$CONF_FILE" ]; then
    # 已安装，显示菜单
    show_menu
else
    # 未安装，进入安装流程
    install_frps
fi
